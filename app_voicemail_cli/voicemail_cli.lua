
function mailbox_get_number_from_cli()    --[[ MAILBOX_GET_NUMBER_FROM_CLI --]]
    local line
    local mailbox_num
    local mailbox_valid = false

    repeat
        io.write("\nMailbox number: [return = abort]: ")
        line = io.read("*line")

        mailbox_num = tonumber(line)

	if line == nil or line == "" then
	   return "ABORT"
	elseif mailbox_num == nil then
	    io.write("\nIllegal mailbox number.  Try again.\n")
	elseif mailbox_num < 100 or mailbox_num > 99999 then
            io.write("\nMailbox number must be between 100 and 99999.  Try again.\n")
        else
	    mailbox_valid = true
        end
    until (mailbox_valid == true)

    return tostring(mailbox_num)
end

function cli_show_status()
   -- for each mailbox, show information about the mailbox...

   local vm_config = g_vm_config.config

   local mailbox_obj

   for box_num, box_config in pairs(vm_config) do
      print("Mailbox "..box_num..":")
      
      mailbox_obj, status = Mailbox:open_box(box_num)

      if mailbox_obj == nil then
	 print("**** Could not open mailbox <"..box_num.."> for reading: "..
	       (status or "unknown error"))
      else

	 local notify_list = box_config.notify_list or "<Default>"

	 local auto_pw = box_config.auto_password
	 if auto_pw == nil then
	    auto_pw = "<Default>"
	 elseif auto_pw == true then
	    auto_pw = "ON"
	 else
	    auto_pw = "OFF"
	 end

	 print("  Name: "..box_config.description)
	 print("  Pass: "..box_config.password)
	 print("   MWI: "..notify_list)
	 print("AutoPW: "..auto_pw)
	 print("")
	 print("  Greetings: "..mailbox_obj.G)
	 print("  Messages:")
	 print("     New:     "..mailbox_obj.N)
	 print("     Saved:   "..mailbox_obj.S)
      end
   end
end

function cli_create_mailbox()                      --[[ MAILBOX_CREATE --]]
    local status
    local mailbox_num
    local mailbox_obj

    mailbox_num = mailbox_get_number_from_cli()

    if mailbox_num == "ABORT" then
        return "ABORT"
    end

    --[[ Valid mailbox number.  Does it already exist? --]]

    mailbox_obj, status = Mailbox:open_box(mailbox_num, false)

    if status == "OK" then
        print("\nMailbox number already exists.")
	return "ERR"
    end

    status = g_vm_config:initialize_mailbox_config(mailbox_num)
    
    if status ~= "OK" then
       print("Could not create mailbox configuration: "..status)
       return "ERR"
    end

    mailbox_obj, status = Mailbox:open_box(mailbox_num, true)

    if mailbox_obj == nil then
       print("Could not create physical mailbox: "..status)
       return "ERR"
    end

    print("*** CREATED ***")
end

function cli_print_edit_menu(box_config, keywords, descriptions)
   
   print("\nMailbox "..box_config.mailbox.."\n");
   for i = 1, #keywords do
      local value = box_config[keywords[i]]

      if value == nil then value = ""; end

      if type(value) == "boolean" then
	 if value then value = "ON" else value = "OFF"; end
      end

      print("    "..i..": "..descriptions[i].." <"..value..">")
   end

   print("")
   print("    S: Save and exit")
   print("    C: Cancel without saving")

   repeat
      print("")
      io.write("> ")

      local cmd = io.read("*line")
   
      if cmd == nil or cmd:match("^[SsCc]$") then
	 return cmd
      end

      local item = cmd:match("^(%d+)$")

      if item then

	 item = item + 0

	 if item >= 1 and item <= #keywords then
	    return item
	 end
      end

      print("\nInvalid item number.  Should be between 1 and "..#keywords..".")

   until false
end

function cli_edit_mailbox()                              --[[ MAILBOX_EDIT_FROM_CLI --]]

    local cmd
    local line

    local finished = false

    local mailbox_num

    mailbox_num = mailbox_get_number_from_cli()
    if mailbox_num == "ABORT" then
        return "ABORT"
    end

    --[[ Got valid mailbox number...  Does it already exist? --]]

    local box_object, error_message = Mailbox:open_box(mailbox_num)

    if not box_object then
        io.write("\nCould not open mailbox: "..error_message)
	return
    end

    box_config = g_vm_config.config[mailbox_num]
    undo_config = {}

    for key, value in pairs(box_config) do
       undo_config[key] = value
    end

    local editing_keywords = { "description", "password",
			       "notify_list", "auto_password" }
    local editing_descriptions = { "Name", "Password",
				   "MWI Notify List", "Auto Password" }
    local item

    repeat
       item = cli_print_edit_menu(box_config, editing_keywords, editing_descriptions)

       if item and type(item) == "string" then break; end

       if item and type(item) ~= "number" then
	  print("** Internal error **")
	  return
       end

       local description = editing_descriptions[item]
       local value = box_config[editing_keywords[item]] or ""

       if type(value) == "boolean" then
	  if value then value = "ON" else value = "OFF"; end
       end

       io.write("New "..description..": ["..value.."]: ")
       local new_value = io.read("*line")

       new_value = new_value or ""

       local kw = editing_keywords[item]

       if kw == "auto_password" then
	  local bool_value = string_parse_true_false(new_value)
	  if bool_value == nil then
	     print(new_value.." is not a valid boolean value.")
	  else
	     box_config[kw] = bool_value
	  end
       else
	  box_config[kw] = new_value
       end

    until finished

    print("<"..item..">")

    if item == "S" or item == "s" then
       g_vm_config:update()
       print("*** Configuration Updated ***")
    else
       for key, value in pairs(undo_config) do
	  box_config[key] = value
       end
       print("*** CANCELLED **")
    end

    return "OK"
end


function cli_delete_mailbox()                     --[[ MAILBOX_DELETE_FROM_CLI --]]
    local status
    local mailbox_num
    local mailbox_obj
    
    local line

    mailbox_num = mailbox_get_number_from_cli()

    if mailbox_num == "ABORT" then
        return "ABORT"
    end

    --[[ Validate mailbox number.  Does it exist? --]]

    mailbox_obj, status = Mailbox:open_box(mailbox_num)

    if not mailbox_obj then
        io.write("\nMailbox does not exist.\n")
	return "ERR"
    end

    io.write("\nConfirm deletion by typing YES: ")

    line = io.read("*line")

    if line == nil or line ~= "YES" then
        io.write("\nDELETION CANCELLED\n\n")
        return "OK"
    end

    local status = Mailbox:delete_physical_box(mailbox_num)

    if status ~= "OK" then
       print("*** Deletion Failed ***")
    end
    
    g_vm_config.config[mailbox_num] = nil
    g_vm_config:update()

    print("*** Mailbox <"..mailbox_num.."> has been deleted. ***")
end

function mailbox_serial_from_cli()                     --[[ MAILBOX_SERIAL_FROM_CLI --]]
    local status
    local mailbox_num
    local mailbox_obj
    
    mailbox_num = mailbox_get_number_from_cli()

    if mailbox_num == "ABORT" then
        return "ABORT"
    end

    --[[ Valid mailbox number.  Does it already exist? --]]

    mailbox_obj, status = mailbox.open(mailbox_num)

    if status ~= "OK" then
        io.write("\nMailbox does not exists.\n")
	return "ERR"
    end

    local done = false

    repeat
    
        io.write("\nGetting serial number...\n")


        serial = mailbox.next_serial(mailbox_obj)

	if serial == nil then
            io.write("Recevied nil from mailbox.next_serial.\n")
        else
            io.write("Recevied <",serial,">.\n")
        end

        io.write"\nPress return to try again, or Q to quit. > "

	local line = io.read("*line")

	if (line == nil) or (line == "Q") or (line == "q") then
            done = true
        end

    until (done == true)
end

function cli_repair_config()

   local mailbox_obj
   local changes = 0

   local config = g_vm_config.config

   for box_num, box_config in pairs(config) do
      print("Mailbox "..box_num..":")
      
      mailbox_obj, status = Mailbox:open_box(box_num)

      if mailbox_obj == nil then
	 print("*** Could not open mailbox <"..box_num.."> for reading: "..
		  (status or "unknown error"))

	 io.write("Delete mailbox from configuration? [no] > ")

	 local cmd = io.read("*line")
	 
	 if cmd ~= nil  then
	    if cmd == "yes" or cmd == "Yes" then
	       print("Removing box <"..box_num.."> from configuration.")
	       config[box_num] = nil
	       changes = changes + 1
	    end
	 end
      end
   end

   if changes > 0 then
      print("*** Configuration changes made.  Writing new config...")
      g_vm_config:update()
   end
end

---------- MAIN -------------------------------------------------------------------------

-- Read the current configuration

local vm_config, error_message = VM_config:new()

if vm_config == nil then 
   print(error_message)
   os.exit(1)
end

g_vm_config = vm_config

local cmd
local finished = false

repeat
   io.write("\nMenu\n\n")
   io.write("    S: Status\n")
   io.write("    C: Create mailbox\n")
   io.write("    E: Edit mailbox\n\n")
   io.write("    D: Delete mailbox\n")
   io.write("\n    T: Test serial number\n")
   io.write("    R: Repair config file\n")

   io.write("\n    Q: Quit\n\n")

   io.write("> ")
   cmd = io.read("*line")

   if cmd == nil or cmd == "Q" or cmd == "q" then
      finished = true
   end

   if cmd == "S" or cmd == "s" then cli_show_status(); end
   if cmd == "C" or cmd == "c" then cli_create_mailbox(); end
   if cmd == "E" or cmd == "e" then cli_edit_mailbox(); end
   if cmd == "D" or cmd == "d" then cli_delete_mailbox(); end
   if cmd == "T" or cmd == "t" then cli_new_message_sn(); end
   if cmd == "R" or cmd == "r" then cli_repair_config(); end

until (finished == true)

