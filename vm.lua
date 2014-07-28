

CLI = false;

--[[ ---CONFIG MANAGEMENT----------------------------------------------------]]

function VMConfig(table)
    config[table["mailbox"]] = table
end

function serialize(file, item)
    if type(item) == "number" then
        file:write(item)
    elseif type(item) == "string" then
        file:write(string.format("%q", item))
    elseif type(item) == "table" then
        file:write("{\n")
	for key, value in pairs(item) do
            file:write("  ", key, " = ")
            serialize(file, value)
            file:write(",\n");
        end
        file:write("}\n")
    else
        logError("Cannot serialize a " .. type(item))
    end
end

function config_backup()                                --[[ CONFIG_BACKUP --]]
    local result;

    file_delete(VM_CONFIG_BACKUP)
    result = file_rename(VM_CONFIG, VM_CONFIG_BACKUP)

    if (result ~= 0) then return "ERR_BACKUP" end

    return "OK"
end

function private_config_write()                          --[[ CONFIG_WRITE --]]

    local file, err

    file, err = io.open(VM_CONFIG, "w")

    if (file == nil) then
        logError("Could not open "..VM_CONFIG.." for writing: "..err)
	return "ERR_OPEN"
    end

    --[[ Trundle through the config table and emit a self-documenting file --]]

    file:write("\n--[[ VOICEMAIL CONFIGURATION --]]\n\n");

    for key,extension in pairs(config) do
    	file:write("VMConfig ")
    	serialize(file, extension)
        file:write("\n")
    end
    
    file:close()

    return "OK"
end

function config_init_mailbox(mailbox_number)

    local mailbox_obj = {}

    mailbox_obj["mailbox"] = mailbox_number
    mailbox_obj["password"] = "1234"
    mailbox_obj["user"] = "Voicemail User (Change me)"
    
    config[mailbox] = mailbox_obj

    return config_flush()
end

function config_load()                                     --[[ CONFIG_LOAD--]]
    config={}
    dofile(VM_CONFIG)
    return "OK"
end

function config_save()                                    --[[ CONFIG_SAVE --]]

    local status;

    --[[ Make a backup of the config file --]]

    status = config_backup()

    if (status ~= "OK") then
        logError("Cannot update configurating file on disk.")
	return "ERR_UPDATE"
    end

    --[[ Write the updated config file --]]

    status = private_config_write()

    if (status ~= "OK") then
        logError("Error writing configuration file to disk.")
	logError("Configuration file may be damaged.")
	return "ERR_UPDATE"
    end

    return "OK"
end


--[[ ---UTILITIES------------------------------------------------------------]]

----------------------------------------------------------------
-- MAIN
----------------------------------------------------------------

function vm_cli_entrypoint()
   config_load();
   vm_maint_cli();
end

function vm_menu_entrypoint(aLeg, mailbox_number)

   config_load();
   aLeg:answer();
   aLeg:sleep(300);
   
   local mailbox_obj = authenticate(aLeg, mailbox_number);
   if (mailbox_obj == nil) then
      return;
   end

   main_menu(aLeg, mailbox_obj);

   aLeg:hangup();
end

function vm_record_entrypoint(aLeg, mailbox_number, greeting)

   config_load();
   aLeg:answer();
   aLeg:sleep(300);
   
   local mailbox_obj, status = mailbox.open(mailbox_number);

   if (mailbox_obj == nil) then
      ivr.play(aLeg, VM.."the-person-at-extension.wav");
      number_smart(aLeg, mailbox_number);
      ivr.play(aLeg, VM.."sender-does-not-have-a-mailbox.wav");
      return "ERR";
   end

   status = mailbox.take_message(mailbox_obj, aLeg, greeting,
				 caller_id_number);
   aLeg:hangup();
   return "OK";
end

