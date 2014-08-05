
--[[

MAILBOX OBJECT:

ROOT = path to mailbox files
SERIAL = path to INDEX
N  = Number of new messages
NI = Array of filenames of new messages
NDATE = Array of file creation dates
NCID = Array of file caller id's.  (Optional)

S  = Number of saved messages
SI = Array of saved messages 
SDATE = see above
SCID = see above

D  = Number of "to-do" disposition messages (same index as source message),
     can either be "", "saved" or "deleted".

--]]

-----MAILBOX PRIMITIVES--------------------------------------------------------

debug_mailbox = true

mailbox = {}

function mailbox.update_mwi(mailbox_obj)

   local extension = mailbox_obj.Extension
   local notify_array = {}

   if config[extension] then
      if config[extension].notify_list then
	 local notify_string = config[extension].notify_list
	 notify_array = string_split(notify_string,":")
      else
	 notify_array[1] = extension
      end
   end

   for _, extension_string in ipairs(notify_array) do

      local event = freeswitch.Event("MESSAGE_WAITING")
   
      if (mailbox_obj.N == 0) and (mailbox_obj.S == 0) then
	 event:addHeader("MWI-Messages-Waiting", "no")
	 event:addHeader("MWI-Voice-Message", "0/0 (0/0)")
      else
	 event:addHeader("MWI-Messages-Waiting", "yes")
	 event:addHeader("MWI-Voice-Message",
			 mailbox_obj.N.."/"..
			 mailbox_obj.S.." (0/0)")
      end
      event:addHeader("MWI-Message-Account", "sip:"..
		      extension_string.."@10.11.0.3")

      event:fire()
   end
end

function mailbox.create(mailbox)

    local status
    local mailbox_path=VM_MAILBOX_PREFIX..mailbox.."/"

    status = config_init_mailbox(mailbox)

    if status ~= "OK" then
        return status
    end

    -- Make and initilize mailbox directories...

    status = file_mkdir(mailbox_path)

    if status ~= 0 then
        return "FAIL"
    end

    status = file_mkdir(mailbox_path.."ARCHIVE")

    -- Create the index file

    file, error = io.open(mailbox_path.."INDEX.txt", "w")

    file:write("0\n")    
    file:close()

    return "OK"
end

function mailbox.delete(mailbox)                              -- MAILBOX_DELETE

    local status
    local mailbox_path=VM_MAILBOX_PREFIX..mailbox

    status = file_recursive_delete(mailbox_path)

    if status ~= 0 then
        return "FAIL"
    end

    config[mailbox] = nil
    
    return config_flush()
end


function mailbox.reopen(mailbox_obj)
   return mailbox.open(mailbox_obj.Extension)
end

function mailbox.open(mailbox_num)                             -- MAILBOX_OPEN 

    -- try to open and read all the files in the directory 

    if debug_mailbox == true then
        logInfo("Opening mailbox <"..mailbox_num..">")
    end

    local mailbox_root = VM_MAILBOX_PREFIX..mailbox_num.."/"

    local files = execute_and_capture("ls -1 "..mailbox_root, false)

    if files == nil then
        logInfo("Could not open mailbox <"..mailbox_num..">: "..status)
        return nil, "ERR_NOT_FOUND"
    end

    -- Crunch through the files and initialize ourselves...

    local mailbox_obj={}

    mailbox_obj["ROOT"] = mailbox_root
    mailbox_obj["SERIAL"] = mailbox_root.."INDEX.txt"
    mailbox_obj.Extension = mailbox_num
    mailbox_obj.CurrentIndex = 1
    mailbox_obj.Mode = "N"

    mailbox_obj["N"] = 0
    mailbox_obj["NI"] = {}
    mailbox_obj["NCID"] = {}
    mailbox_obj["NDATE"] = {}

    mailbox_obj["S"] = 0
    mailbox_obj["SI"] = {}
    mailbox_obj["SCID"] = {}
    mailbox_obj["SDATE"] = {}

    mailbox_obj["G"] = 0
    mailbox_obj["GI"] = {}

    mailbox_obj["D"] = {}

    table.sort(files)

    for index, name in ipairs(files) do
       local number, mode = string.match(name, "^(%d%d%d%d%d%d%d%d)(%a)")
       local cid          = string.match(name, "^%d%d%d%d%d%d%d%d%a,(%d+)")

       local ctime = execute_and_capture("stat --printf='%Z' "..mailbox_obj.ROOT..name, true)

       if number == nil then
       else 
	  if debug_mailbox == true then
	     if cid then
		logInfo(index..": "..name..": "..number.."("..mode.."): "..cid)
	     else
		logInfo(index..": "..name..": "..number.."("..mode..")")
	     end
	     logInfo("   ctime: "..ctime)
	  end
	  
	  local mode_index = mode.."I"
	  local cid_index = mode.."CID"
	  local ctime_index = mode.."DATE"
	  
	  mailbox_obj[mode] = mailbox_obj[mode] + 1
	  local position = mailbox_obj[mode]

	  mailbox_obj[mode_index][position] = name

	  if mailbox_obj[cid_index] then
	     mailbox_obj[cid_index][position] = cid
	  end

	  if mailbox_obj[ctime_index] then
	     mailbox_obj[ctime_index][position] = ctime
	  end
       end
    end

    mailbox.update_mwi(mailbox_obj)

    return mailbox_obj, "OK"
end

function mailbox.next_serial(mailbox_obj)

   local result = os.execute(SCRIPTS.."helper nextID "..mailbox_obj["SERIAL"])

   if result == false then
      logError("Could not advance mailbox serial number.")
      return 0, "ERR_FAIL"
   end

   local file, status = io.open(mailbox_obj["SERIAL"], "r")
   if file == nil then 
      logError("Could not open serial number file for reading: "
		  ..(status or "unknown error"))
      return 0, "ERR_FAIL"
   end

   local serial, status = file:read("*number")

   file:close()

   if serial == nil then
      logError("Could not read serial number from file: "
		  ..(status or "unknown error"))
      return 0, "ERR_FAIL"
   end

   if debug_mailbox == true then
      logInfo("Next serial number is ".. serial)
   end
   
   return serial, "OK"
end

function mailbox.set_mode(mailbox_obj, mailbox_mode)
   mailbox_obj.Mode = mailbox_mode
end

function mailbox.play_current(mailbox_obj, aLeg)
   local current_index = mailbox_obj.CurrentIndex
   local mailbox_mode = mailbox_obj.Mode

   local file_name 
           = mailbox_obj.ROOT..mailbox_obj[mailbox_mode.."I"][current_index]

   mailbox.announce_ordinal(mailbox_obj, aLeg)

   aLeg:sleep(200)

   ivr_menu = {}

   ivr_menu[1] = file_name
   ivr_menu[2] = VM.."ding.wav"

   digits = ivr.prompt_list(aLeg, ivr_menu, 1000)

   return true, digits
end

-- returns true if a message played.

function mailbox.next_message(mailbox_obj, aLeg)
   local current_index = mailbox_obj.CurrentIndex
   local mailbox_mode  = mailbox_obj.Mode

   current_index = current_index + 1
   
   if current_index <= mailbox_obj[mailbox_mode] then
      mailbox_obj.CurrentIndex = current_index
      local status, digits = mailbox.play_current(mailbox_obj, aLeg)
      return status, digits
   end
   return false, ""
end

function mailbox.previous_message(mailbox_obj, aLeg)
   local current_index = mailbox_obj.CurrentIndex

   current_index = current_index - 1
   
   if current_index >= 1 then
      mailbox_obj.CurrentIndex = current_index
      local status, digits = mailbox.play_current(mailbox_obj, aLeg)
      return status, digits
   end
   return false, ""
end

function mailbox.take_message(mailbox_obj, aLeg, greeting_index,
			      caller_id)

   local digit

   function record_dtmf_callback(sess, cb_type, obj, arg)
      if cb_type == "dtmf" then
	 digit = obj.digit
	 
	 if obj.digit == "9" then
	    digit = "9"
	    return "break"
	 end
      end
      return ""
   end

   -- Get the next serial number

   local serial_number = 0
   local status

   serial_number, status = mailbox.next_serial(mailbox_obj)

   if status ~= "OK" then
      mailbox_error(aLeg)
      return "error"
   end

   if (not caller_id) then
      caller_id = ""
   end

   -- Play the greeting...

   local file_list = mailbox_obj.GI
   local greeting_file = mailbox_obj.ROOT..file_list[greeting_index+0]

   aLeg:sleep(500)

   if file_exists(greeting_file) then
      digit = ivr.prompt(aLeg, greeting_file, 1000)
   else
      digit = ivr.prompt(aLeg, VM.."greeting-default.wav", 1000)
   end

   if aLeg:ready() == false then
      return "error"
   end

   -- Record the message.

   local record_file 
         = mailbox_obj.ROOT..string.format("%08dN", serial_number)

   if caller_id ~= "" then
      record_file = record_file..","..caller_id..".wav"
   else
      record_file = record_file..".wav"
   end

   if (digit == "9") and (mailbox_obj.Extension == "546") then
      --
      -- Find jim. :-)
      --
      aLeg:execute("lua", "dialplan inbound JimWake private")
      return
   end

   aLeg:setInputCallback("record_dtmf_callback", "")
   
   sounds.voicemail_beep(aLeg)
   
   aLeg:setVariable("record_waste_resources", "true")
   aLeg:setVariable("record_fill_cng", "1400")
   aLeg:recordFile(record_file, 360, 500, 6)

   mailbox_obj = mailbox.reopen(mailbox_obj)

   if (digit == "9") and (mailbox_obj.Extension == "546") then
      aLeg:execute("lua", "dialplan inbound JimWake private")
      return
   end

   ivr.play(aLeg, SOUNDS.."Announcement/thank-you-for-calling.wav")
end

function mailbox.cleanup(mailbox_obj)

   -- scan through the disposition list, saving and deleting (archiving)
   -- messages as needed.

   mailbox_type = mailbox_obj.Mode

   local source_table
   
   logError("mailbox_cleanup: CLEANING UP!")

   if mailbox_type == "N" then
      source_table = mailbox_obj.NI
   elseif mailbox_type == "S" then
      source_table = mailbox_obj.SI
   else
      logError("mailbox_cleanup: Cannot cleanup. Invalid mailbox mode.")
      return
   end

   for index, action in pairs(mailbox_obj.D) do
      if action == "saved" then 
	 -- save the message by renaming it with an "S" instead of an "N"
	 -- index.
	 local source_ID = source_table[index]:match("(%d%d%d%d%d%d%d%d)")
	 local source_path = mailbox_obj.ROOT..source_table[index]
	 local dest_path

	 dest_path = mailbox_obj.ROOT..string.format("%sS.wav", source_ID)

	 logInfo("SAVE: Source: "..source_path..", Dest: "..dest_path)
	 file_rename(source_path, dest_path)
      end

      if action == "deleted" then
	 local source_path = mailbox_obj.ROOT..source_table[index]
	 local dest_path = mailbox_obj.ROOT.."ARCHIVE/"..source_table[index]
	 logInfo("DELETE: Source: "..source_path..", Dest: "..dest_path)

	 file_rename(source_path, dest_path)
      end
   end
end

function mailbox.announce_stats(mailbox_obj, aLeg)

   local menu = {}
   
   -- No messages at all?

   if mailbox_obj.N == 0 and mailbox_obj.S == 0 then
      ivr.play(aLeg, VM.."no-messages.wav")
      return
   end

   -- New messages

   if mailbox_obj.N == 0 then
      table_append(menu, VM.."no-new-messages.wav")
   else
      -- Try a canned message first...

      local fileName = VM.."count-"..mailbox_obj.N.."-new-msgs.wav"

      if file_exists(fileName) then
	 table_append(menu, fileName)
      elseif mailbox_obj.N == 0 then
	 table_append(menu, VM.."no-new-messages.wav")
      else
	 -- No joy, construct the message ourselves...
	 table_append(menu, VM.."you-have.wav")
	 recite.make_human_number_playlist(menu, mailbox_obj.N)
	 table_append(menu, VM.."new.wav")
	 table_append(menu, VM.."messages.wav")
      end
   end

   -- Saved messages
   
   fileName = VM.."count-and-"..mailbox_obj.S.."-saved-msgs.wav"
   
   if file_exists(fileName) then
      table_append(menu, fileName)
   else
      if mailbox_obj.S ~= 0 then
	 -- No joy, construct the message ourselves...
	 table_append(menu, VM.."and.wav")
	 recite.make_human_number_playlist(menu, mailbox_obj.S)
	 table_append(menu, VM.."saved.wav")
	 table_append(menu, VM.."messages.wav")
      end
   end

   ivr.prompt_list(aLeg, menu, 1)
end

function mailbox.error(aLeg)
      ivr.play(aLeg, VM.."this-is-the-voice-mail-system.wav")
      aLeg:sleep(500)

      ivr.play(aLeg, SOUNDS.."Announcement/something-is-terribly-wrong.wav")
      aLeg:sleep(250)
      ivr.play(aLeg, SOUNDS.."Announcement/an-error-has-occured.wav")
      aLeg:sleep(250)
      ivr.play(aLeg, SOUNDS.."Announcement/cannot-complete-otherend-error.wav")
      aLeg:sleep(250)
      ivr.play(aLeg, SOUNDS.."Announcement/hangup-try-again.wav")
      aLeg:sleep(500)
      ivr.play(aLeg, SOUNDS.."Announcement/thank-u-for-patience.wav")
end

function mailbox.announce_ordinal(mailbox_obj, aLeg)

   local current_index = mailbox_obj.CurrentIndex
   local mailbox_mode = mailbox_obj.Mode

   if current_index == 1 and mailbox_obj[mailbox_mode] == 1 then
      -- For only one message in the box, just say nothing.
      return true
   end
   
   if current_index == mailbox_obj[mailbox_mode] then
      ivr.play(aLeg, VM.."count-ord-last-msg.wav")
      return true
   end

   local file = VM.."count-ord-"..current_index.."-msg.wav"

   if file_exists(file) then
      ivr.play(aLeg, file)
      return false
   end

   -- Rats, we have to construct it by hand...

   ivr.play(aLeg, VM.."message.wav")
   recite.number_as_human(aLeg, current_index)

   return false
end

function mailbox.announce_envelope(mailbox_obj, aLeg)

   local current_index = mailbox_obj.CurrentIndex
   local mailbox_mode = mailbox_obj.Mode

   -- Announce the date

   ivr.play(aLeg, VM.."received.wav")
   recite.relative_date(aLeg, mailbox_obj[mailbox_mode.."DATE"][current_index])

   -- Announce the caller ID.

   local cid = mailbox_obj[mailbox_mode.."CID"][current_index]

   if cid then
      aLeg:sleep(500)
      logError("Reciting number: "..cid)
      recite.phone_number(aLeg, cid)
   else
      ivr.play(aLeg, VM.."i-dont-know-who-sent-message.wav")
   end

   aLeg:sleep(500)
end
