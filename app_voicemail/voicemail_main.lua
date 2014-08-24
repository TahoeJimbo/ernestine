

function vm_menu_entrypoint(fs_session, mailbox_number)

   g_vm_config, error_message = VM_config:new()

   if g_vm_config == nil then
      logError(error_message)
      sounds.sit(fs_session, "reserved")
      return nil
   end

   fs_session:answer();
   fs_session:sleep(300);
   
   local mailbox_obj = authenticate(fs_session, mailbox_number)
   if mailbox_obj == nil then
      return
   end

   main_menu(fs_session, mailbox_obj)

   fs_session:hangup()
end

function vm_record_entrypoint(fs_session, mailbox_number, greeting)

   g_vm_config, error_message = VM_config:new()

   if g_vm_config == nil then
      logError(error_message)
      sounds.sit(fs_session, "reserved")
      return
   end

   fs_session:answer()
   fs_session:sleep(300)
   
   local mailbox_obj, status = Mailbox:open_box(mailbox_number)

   if mailbox_obj == nil then
      ivr.play(fs_session, VM.."the-person-at-extension.wav")
      recite.number_digits_smart(fs_session, mailbox_number)
      ivr.play(fs_session, VM.."sender-does-not-have-a-mailbox.wav")
      return "ERR"
   end

   status = mailbox_obj:take_message(fs_session, greeting, caller_id_number)
   fs_session:hangup();
   return "OK";
end



----------------------------------------------------------------
-- MAIN
----------------------------------------------------------------

-- GATHER SOME INITIAL DATA
-- and turn them into global variables.

if (session) then
   caller_id_name = session:getVariable("caller_id_name")
   caller_id_number = session:getVariable("caller_id_number")
   caller_uuid = session:getVariable("uuid")
   destination_number = session:getVariable("sip_to_user")

   if (caller_id_name == nil) then caller_id_name="UNKNOWN" end
   if (caller_id_number == nil) then caller_id_name="UNKNOWN" end
   if (caller_uuid == nil) then caller_uuid="????" end
end

-- PROCESS ARGUMENTS

if (argv) then
   arg = argv
end

for key, value in ipairs(arg) do
   if DEBUG then logInfo("Arg: "..key.." = "..value); end
end

if #arg == 3 and arg[1] == "record" then

   local box_number = arg[2]
   local greeting = arg[3]

   vm_record_entrypoint(session, box_number, greeting)
   return
end

if #arg == 2 and arg[1] == "boxmenu" then
   
   local box_number = arg[2]
   vm_menu_entrypoint(session, box_number)
   return
end

--
-- Ack. Extreme brokenness here. :-)
--

if (#arg ~= 2) then
   logError("usage: voicemail {record|boxmenu} {extension} [greeting]")
end

sounds.sit(session, "vacant")


