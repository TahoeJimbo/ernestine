
--[[ ---MAINTENANCE MENU-----------------------------------------------------]]

function vm_maint_cli()
    local finshed = false

    repeat
        io.write("\nMenu\n\n")
        io.write("    S: Status\n")
        io.write("    C: Create mailbox\n")
	io.write("    E: Edit mailbox\n\n")
	io.write("    D: Delete mailbox\n")
	io.write("\n    T: Test serial number\n")
	io.write("    R: Repair config file\n")

        io.write("\n    Q: Quit\n\n");

	io.write("> ")
        cmd = io.read("*line")

        if (cmd == nil) or (cmd == "Q") or (cmd == "q") then
           finished = true
        end

	if (cmd == "S" or cmd == "s") then
	    show_status()
        end

        if (cmd == "C" or cmd == "c") then
	    mailbox_create_from_cli()
        end

	if (cmd == "E" or cmd == "e") then
            mailbox_edit_from_cli()
	end

	if (cmd == "D" or cmd == "d") then
            mailbox_delete_from_cli()
        end

	if (cmd == "T" or cmd == "t") then
	    mailbox_serial_from_cli()	    
	end

	if (cmd == "R" or cmd == "r") then
	   repair_config();
	end

    until (finished == true)
end

function mailbox_get_number_from_cli()    --[[ MAILBOX_GET_NUMBER_FROM_CLI --]]
    local line
    local mailbox
    local mailbox_valid = false
    local status

    repeat
        io.write("\nMailbox number: [return = abort]: ")
        line = io.read("*line")

        mailbox = tonumber(line)

	if (line == nil) or (line == "") then
	   return "ABORT"
	elseif (mailbox == nil) then
	    io.write("\nIllegal mailbox number.  Try again.\n")
	elseif (mailbox < 100) or (mailbox > 99999) then
            io.write("\nMailbox number must be between 100 and 99999.  Try again.\n")
        else
	    mailbox_valid = true;
        end
    until (mailbox_valid == true)

    return tostring(mailbox)
end

function mailbox_edit_from_cli()                --[[ MAILBOX_EDIT_FROM_CLI --]]

    local cmd
    local name
    local line
    local password

    local finished = false

    local mailbox

    mailbox = mailbox_get_number_from_cli()
    if (mailbox == "ABORT") then
        return "ABORT"
    end

    --[[ Got valid mailbox number...  Does it already exist? --]]

    status = mailbox.open(mailbox)

    if (status == "OK") then
        io.write("\nMailbox number already exists.\n")
    else
        extension_valid = true
    end

    box_config = config[mailbox];

    local saved_user = box_config["user"]
    local saved_password = box_config["password"]

    local name = saved_user
    local password = saved_password

    repeat
        io.write("\nMailbox ", mailbox, "\n\n");
        io.write("    1: Name: <", name, ">\n")
        io.write("    2: Password: <", password, ">\n")
        io.write("\n")
        io.write("    S: Save and exit\n");
        io.write("    C: Cancel without saving\n");
        io.write("\n")
        io.write("> ")

        cmd = io.read("*line")
	
	if (cmd == nil) or (cmd == "S") or (cmd == "s") then
	    finished = true
	end

	if (cmd == "1") then
	    io.write("Name: [", name, "]: ")
	    name = io.read("*line")

	    if (name == nil) then
	        finished=true
	    elseif (name == "") then
                io.write("Empty or invalid name.\n")
		name = saved_user
	    elseif (#name < 6) then
	        io.write("Name must be at least six characters (including spaces.\n")
                name = saved_user
            end
	end

	if (cmd == "2") then
	   io.write("Password: [", password, "]: ")

	   line = io.read("*line")

	   if (line == nil) then
	       finished=true
	       break
            end
	   
	   password = tonumber(line)

	   if (password == nil) or (password < 1000) or (password > 99999999) then
	       io.write("The password should be between 4 and 8 digits.\n")
	       password = saved_password
           end
	end

	if (cmd == "C") or (cmd == "c") then
	    finished = true
        end

    until (finished == true)

    if (cmd == "S" or cmd == "s") then
         box_config["user"] = name
         box_config["password"] = password
	 config_save()
    end

    return "OK"
end

--345678901234567890123456789012345678901234567890123456789012345678901234567890

function mailbox_create_from_cli()                      --[[ MAILBOX_CREATE --]]
    local status
    local mailbox
    local mailbox_obj

    mailbox = mailbox_get_number_from_cli()

    if (mailbox == "ABORT") then
        return "ABORT"
    end

    --[[ Valid mailbox number.  Does it already exist? --]]

    mailbox_obj, status = mailbox.open(mailbox)

    if (status == "OK") then
        io.write("\nMailbox number already exists.\n")
	return "ERR"
    end

    return mailbox.create(mailbox)

end


function mailbox_delete_from_cli()                     --[[ MAILBOX_DELETE_FROM_CLI --]]
    local status
    local mailbox
    local mailbox_obj
    
    local line

    mailbox = mailbox_get_number_from_cli()

    if (mailbox == "ABORT") then
        return "ABORT"
    end

    --[[ Valid mailbox number.  Does it already exist? --]]

    mailbox_obj, status = mailbox.open(mailbox)

    if (status ~= "OK") then
        io.write("\nMailbox does not exists.\n")
	return "ERR"
    end

    io.write("\nConfirm deletion by typing YES: ")

    line = io.read("*line")

    if (line == nil) or (line ~= "YES") then
        io.write("\nDELETION CANCELLED\n\n")
        return "OK"
    end

    mailbox.delete(mailbox)
end

function mailbox_serial_from_cli()                     --[[ MAILBOX_SERIAL_FROM_CLI --]]
    local status
    local mailbox
    local mailbox_obj
    
    local line

    mailbox = mailbox_get_number_from_cli()

    if (mailbox == "ABORT") then
        return "ABORT"
    end

    --[[ Valid mailbox number.  Does it already exist? --]]

    mailbox_obj, status = mailbox.open(mailbox)

    if (status ~= "OK") then
        io.write("\nMailbox does not exists.\n")
	return "ERR"
    end

    local done = false;

    repeat
    
        io.write("\nGetting serial number...\n")


        serial = mailbox.next_serial(mailbox_obj)

	if (serial == nil) then
            io.write("Recevied nil from mailbox_next_serial.\n")
        else
            io.write("Recevied <",serial,">.\n")
        end

        io.write("\nPress return to try again, or Q to quit. > ")

	local line = io.read("*line")

	if (line == nil) or (line == "Q") or (line == "q") then
            done = true;
        end

    until (done == true)

end

function show_status()
   -- for each mailbox, show information about the mailbox...

   local box_config
   local key
   local mailbox_obj

   for key in pairs(config) do
      print("Mailbox "..key..":");
      
      box_config = config[key];
      mailbox_obj,status = mailbox.open(key);

      if (mailbox_obj == nil) then
	 print("**** Could not open mailbox <"..key.."> for reading: "..
	       (status or "unknown error"));
      else

	 print("  Name: "..box_config["user"]);
	 print("  Pass: "..box_config["password"]);
	 print("  Greetings: "..mailbox_obj.G);
	 print("  Messages:");
	 print("     New:     "..mailbox_obj.N);
	 print("     Saved:   "..mailbox_obj.S);
      end
   end
end

function repair_config()
   local box_config
   local key
   local mailbox_obj
   local changes = 0;

   for key in pairs(config) do
      print("Mailbox "..key..":");
      
      box_config = config[key];
      mailbox_obj,status = mailbox.open(key);

      if (mailbox_obj == nil) then
	 print("**** Could not open mailbox <"..key.."> for reading: "..
	       (status or "unknown error"));

	 io.write("Delete mailbox from configuration? [no] > ");

	 local cmd = io.read("*line")
	
	 if (cmd ~= nil)  then
	    if (cmd == "yes" or cmd == "Yes") then
	       print("Removing box <"..key.."> from configuration.");
	       config[key] = nil;
	       changes = changes + 1;
	    end
	 end
      end
   end

   if (changes > 0) then
      print("**** Configuration changes made.  Writing new config...");
      config_save();
   end
end
