
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

-----MAILBOX PRIMITIVES------------------------------------------------------------------

debug_mailbox = true

Mailbox = {}

function Mailbox:new()
   local object = {}
   
   setmetatable(object, self)
   self.__index = self

   return object
end
                                                                --[[ MAILBOX:OPEN_BOX]]--
function Mailbox:open_box(box_num, create_if_not_there)

   if DEBUG_MAILBOX then
      logInfo("Opening mailbox <"..box_num..">")
   end

   local box_obj = Mailbox:new()

   --
   -- Try to open and read all the files in the directory.  If we
   -- fail, and "create_if_not_there" is set, we try to create the box
   --

   local result

   result = box_obj:PRIV_process_box_file_list(box_num)

   if result ~= "OK" then
      if create_if_not_there then
	 result = box_obj:PRIV_create_physical_box(box_num)
	 
	 if result ~= "OK" then return nil, result; end

	 -- Try again, without the create flag.

	 return Mailbox:open_box(box_num, false)
      end
      
      return nil, result
   end

   return box_obj, nil
end

function Mailbox:delete_physical_box(box_num)

    local status
    local mailbox_path=VM_MAILBOX_PREFIX..box_num

    status = file_recursive_delete(mailbox_path)

    if status ~= true then
        return "FAIL"
    end

    return "OK"
end

function Mailbox:update_mwi()

   local notify_array = {}
   local box_config = g_vm_config[self.box_number]

   if DEBUG_MAILBOX then logInfo("Updating MWI for box <"..self.box_number..">"); end

   if box_config and box_config.notify_list then
      local notify_string = box_config.notify_list
      notify_array = string_split(notify_string,":")
   else
      notify_array[1] = self.box_number
   end

   for _, box_number_string in ipairs(notify_array) do

      local event = freeswitch.Event("MESSAGE_WAITING")
   
      if (self.N == 0) and (self.S == 0) then
	 event:addHeader("MWI-Messages-Waiting", "no")
	 event:addHeader("MWI-Voice-Message", "0/0 (0/0)")
      else
	 event:addHeader("MWI-Messages-Waiting", "yes")
	 event:addHeader("MWI-Voice-Message",
			 self.N.."/"..
			 self.S.." (0/0)")
      end
      event:addHeader("MWI-Message-Account", "sip:"..
		      box_number_string.."@10.11.0.3")   -- FIXME: THIS SHOULD NOT
                                                        -- BE HARDCODED
      event:fire()
   end
end

---------- PRIVATE ----------------------------------------------------------------------

function Mailbox:PRIV_process_box_file_list(box_num)

   local box_root = VM_MAILBOX_PREFIX..box_num.."/"

   local files = execute_and_capture("ls -1 "..box_root, false)

   if files == nil or #files == 0 then
      return "Box <"..box_num.."> at <"..box_root.."> not found."
   end

   -- Crunch through the files and initialize ourselves...

   self.ROOT = box_root
   self.SERIAL = box_root.."INDEX.txt"
   self.box_number = box_num
   self.current_index = 1
   self.mode = "N"

   self.N = 0
   self.NI = {}
   self.NCID = {}
   self.NDATE = {}

   self.S = 0
   self.SI = {}
   self.SCID = {}
   self.SDATE = {}

   self.G = 0
   self.GI = {}

   self.D = {}

   table.sort(files)

   for index, name in ipairs(files) do
      local number, mode = string.match(name, "^(%d%d%d%d%d%d%d%d)(%a)")
      local cid          = string.match(name, "^%d%d%d%d%d%d%d%d%a,(%d+)")

      local ctime = execute_and_capture("stat --printf='%Z' "..self.ROOT..name,
	                                true)
      if number == nil then
	 --
	 -- Not a mailbox file...
	 --
      else 
	 if DEBUG_MAILBOX then
	    if cid then
	       logInfo(index..": "..name..": "..number.."("..mode.."): "..cid)
	    else
	       logInfo(index..": "..name..": "..number.."("..mode..")")
	    end
	    logInfo("   ctime: "..ctime)
	 end

	 -- mode can be "N" for New or "S" for Saved
	 
	 local mode_index = mode.."I"        -- Index numbers
	 local cid_index = mode.."CID"       -- Caller ID values
	 local ctime_index = mode.."DATE"    -- Date Recorded
	 
	 self[mode] = self[mode] + 1   -- Update the message count
	 local position = self[mode]      -- Update the last index encountered

	 self[mode_index][position] = name  -- Add the file name to the index

	 if self[cid_index] then               -- Add the caller ID to the index.
	    self[cid_index][position] = cid
	 end

	 if self[ctime_index] then         -- Add the date/time to the index
	    self[ctime_index][position] = ctime
	 end
      end
   end

   self:update_mwi()

   return "OK"
end

function Mailbox:PRIV_create_physical_box(box_num)

    local status
    local box_path = VM_MAILBOX_PREFIX..box_num.."/"

    -- Make and initilize mailbox directories...

    status = file_mkdir(box_path)

    if status ~= true then
        return "Could not create new voicemail box."
    end

    status = file_mkdir(box_path.."ARCHIVE")

    -- Create the index file

    file, error = io.open(box_path.."INDEX.txt", "w")

    file:write("0\n")    
    file:close()

    return "OK"
end

function Mailbox:next_serial()

   local result = os.execute(SCRIPTS.."helper nextID "..self.SERIAL)

   if result == false then
      return 0, "Could not advance mailbox serial number."
   end

   local file, status = io.open(self.SERIAL, "r")
   if file == nil then 
      return 0, "Could not open serial number file for reading: "
	         ..(status or "unknown error")
   end

   local serial, status = file:read("*number")

   file:close()

   if serial == nil then
      logError("Could not read serial number from file: "
		  ..(status or "unknown error"))
      return 0, "ERR_FAIL"
   end

   if DEBUG_MAILBOX then logInfo("Next serial number is ".. serial); end
   
   return serial, "OK"
end

function Mailbox:set_mode(mailbox_mode)
   self.mode = mailbox_mode
end

--
-- Plays the current message.  If the listener presses a keypad button,
-- interrupt the playback and return the button
--
-- Returns true, [button|""]

function Mailbox:play_current(fs_session)
   local current_index = self.current_index
   local mailbox_mode = self.mode

   local file_name 
           = self.ROOT..self[mailbox_mode.."I"][current_index]

   self:announce_ordinal(fs_session)

   fs_session:sleep(200)

   ivr_menu = {}

   ivr_menu[1] = file_name
   ivr_menu[2] = VM.."ding.wav"

   digits = ivr.prompt_list(fs_session, ivr_menu, 1000)

   return true, digits
end

--
-- Attempts to play the next message.  If the listener presses a keypad button,
-- interrupt the playback and return the button.
--
-- returns true, [button|""] if a message was played
--         false, "" if the message was not played.

function Mailbox:next_message(fs_session)
   local current_index = self.current_index
   local mailbox_mode  = self.mode

   current_index = current_index + 1
   
   if current_index <= self[mailbox_mode] then
      self.current_index = current_index
      local status, digits =self:play_current(fs_session)
      return status, digits
   end
   return false, ""
end

--
-- Attempts to play the previous message.  If the listener presses a keypad button,
-- interrupt the playback and return the button.
--
-- Returns true, [button|""] if a message was played
--         false, "" if the message was not played.
--

function Mailbox:previous_message(fs_session)
   local current_index = self.current_index

   current_index = current_index - 1
   
   if current_index >= 1 then
      self.current_index = current_index
      local status, digits = self:play_current(fs_session)
      return status, digits
   end
   return false, ""
end

--
-- Records a message in the receiver's mailbox.
--
-- If the source presses a keypad button, interrupt the recording
-- and process the digits.
--
-- returns "OK", or an error message
--

function Mailbox:take_message(fs_session, greeting_index, caller_id)

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

   serial_number, status = self:next_serial()

   if status ~= "OK" then
      self:error(fs_session)
      return "error"
   end

   if (not caller_id) then
      caller_id = ""
   end

   -- Play the greeting...

   local file_list = self.GI
   local greeting_file = self.ROOT..file_list[greeting_index+0]

   fs_session:sleep(500)

   if file_exists(greeting_file) then
      digit = ivr.prompt(fs_session, greeting_file, 1000)
   else
      digit = ivr.prompt(fs_session, VM.."greeting-default.wav", 1000)
   end

   if fs_session:ready() == false then
      return "error"
   end

   -- Record the message.

   local record_file 
         = self.ROOT..string.format("%08dN", serial_number)

   if caller_id ~= "" then
      record_file = record_file..","..caller_id..".wav"
   else
      record_file = record_file..".wav"
   end

   if (digit == "9") then
      fs_session:execute("set", "ringback=%(2000,4000,440.0,480.0)")
      fs_session:execute("lua",
		   "dialplan inbound EMERGENCY_"..self.box_number.." public")
      return
   end

   fs_session:setInputCallback("record_dtmf_callback", "")
   
   sounds.voicemail_beep(fs_session)
   
   fs_session:setVariable("record_waste_resources", "true")
   fs_session:recordFile(record_file, 360, 500, 6)

   self:update_mwi()

   if digit == "9" then
      fs_session:execute("set", "ringback=%(2000,4000,440.0,480.0)")
      fs_session:execute("lua",
		   "dialplan inbound EMERGENCY_"..self.box_number.." public")
      return
   end

   ivr.play(fs_session, SOUNDS.."Announcement/thank-you-for-calling.wav")
end

function Mailbox:cleanup()

   -- scan through the disposition list, saving and deleting (archiving)
   -- messages as needed.

   mailbox_type = self.mode

   local source_table
   
   if DEBUG_MAILBOX then logInfo("mailbox_cleanup: CLEANING UP!"); end

   if mailbox_type == "N" then
      source_table = self.NI
   elseif mailbox_type == "S" then
      source_table = self.SI
   else
      logError("Cannot cleanup. Invalid mailbox mode.")
      return
   end

   for index, action in pairs(self.D) do
      if action == "saved" then 
	 -- save the message by renaming it with an "S" instead of an "N"
	 -- index.
	 local source_ID = source_table[index]:match("(%d%d%d%d%d%d%d%d)")
	 local source_path = self.ROOT..source_table[index]
	 local dest_path

	 dest_path = self.ROOT..string.format("%sS.wav", source_ID)

	 logInfo("SAVE: Source: "..source_path..", Dest: "..dest_path)
	 file_rename(source_path, dest_path)
      end

      if action == "deleted" then
	 local source_path = self.ROOT..source_table[index]
	 local dest_path = self.ROOT.."ARCHIVE/"..source_table[index]
	 logInfo("DELETE: Source: "..source_path..", Dest: "..dest_path)

	 file_rename(source_path, dest_path)
      end
   end
end

function Mailbox:announce_stats(fs_session)

   local menu = {}
   
   -- No messages at all?

   if self.N == 0 and self.S == 0 then
      ivr.play(fs_session, VM.."no-messages.wav")
      return
   end

   -- New messages

   if self.N == 0 then
      table_append(menu, VM.."no-new-messages.wav")
   else
      -- Try a canned message first...

      local fileName = VM.."count-"..self.N.."-new-msgs.wav"

      if file_exists(fileName) then
	 table_append(menu, fileName)
      elseif self.N == 0 then
	 table_append(menu, VM.."no-new-messages.wav")
      else
	 -- No joy, construct the message ourselves...
	 table_append(menu, VM.."you-have.wav")
	 recite.make_human_number_playlist(menu, self.N)
	 table_append(menu, VM.."new.wav")
	 table_append(menu, VM.."messages.wav")
      end
   end

   -- Saved messages
   
   fileName = VM.."count-and-"..self.S.."-saved-msgs.wav"
   
   if file_exists(fileName) then
      table_append(menu, fileName)
   else
      if self.S ~= 0 then
	 -- No joy, construct the message ourselves...
	 table_append(menu, VM.."and.wav")
	 recite.make_human_number_playlist(menu, self.S)
	 table_append(menu, VM.."saved.wav")
	 table_append(menu, VM.."messages.wav")
      end
   end

   ivr.prompt_list(fs_session, menu, 1)
end

function Mailbox:error(fs_session)
      ivr.play(fs_session, VM.."this-is-the-voice-mail-system.wav")
      fs_session:sleep(500)

      ivr.play(fs_session, SOUNDS.."Announcement/something-is-terribly-wrong.wav")
      fs_session:sleep(250)
      ivr.play(fs_session, SOUNDS.."Announcement/an-error-has-occured.wav")
      fs_session:sleep(250)
      ivr.play(fs_session, SOUNDS.."Announcement/cannot-complete-otherend-error.wav")
      fs_session:sleep(250)
      ivr.play(fs_session, SOUNDS.."Announcement/hangup-try-again.wav")
      fs_session:sleep(500)
      ivr.play(fs_session, SOUNDS.."Announcement/thank-u-for-patience.wav")
end

function Mailbox:announce_ordinal(fs_session)

   local current_index = self.current_index
   local mailbox_mode = self.mode

   if current_index == 1 and self[mailbox_mode] == 1 then
      -- For only one message in the box, just say nothing.
      return true
   end
   
   if current_index == self[mailbox_mode] then
      ivr.play(fs_session, VM.."count-ord-last-msg.wav")
      return true
   end

   local file = VM.."count-ord-"..current_index.."-msg.wav"

   if file_exists(file) then
      ivr.play(fs_session, file)
      return false
   end

   -- Rats, we have to construct it by hand...

   ivr.play(fs_session, VM.."message.wav")
   recite.number_as_human(fs_session, current_index)

   return false
end

function Mailbox:announce_envelope(fs_session)

   local current_index = self.current_index
   local mailbox_mode = self.mode

   -- Announce the date

   ivr.play(fs_session, VM.."received.wav")
   recite.relative_date(fs_session, self[mailbox_mode.."DATE"][current_index])

   -- Announce the caller ID.

   local cid = self[mailbox_mode.."CID"][current_index]

   if cid then
      fs_session:sleep(500)
      logError("Reciting number: "..cid)
      recite.phone_number(fs_session, cid)
   else
      ivr.play(fs_session, VM.."i-dont-know-who-sent-message.wav")
   end

   fs_session:sleep(500)
end


