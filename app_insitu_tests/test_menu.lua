#!/opt/local/bin/lua 

function process_test()
   if (#arg ~= 2) then
      logError("process_dialplan(): Wrong number of arguments.");
      return;
   end

   local test_number = arg[2];

   logError("Starting test: "..test_number)
   test_dispatch(session, test_number)
   logError("Finishing test: "..test_number)
end

function process_record()
   if (#arg ~= 3) then
      logError("process_vm_record(): Wrong number of arguments.");
      return;
   end

   local extension = arg[2];
   local greeting = arg[3];
   
   logError("Starting record.");
   recording_menu(session)
   logError("Finishing voicemail record: Extension: "..extension
	    ..", greeting: "..greeting);
end

----------------------------------------------------------------
-- MAIN
----------------------------------------------------------------

-- GATHER SOME INITIAL DATA

if (session) then
   caller_id_name = session:getVariable("caller_id_name");
   caller_id_number = session:getVariable("caller_id_number");
   caller_uuid = session:getVariable("uuid");
   destination_number = session:getVariable("sip_to_user");

   if (caller_id_name == nil) then caller_id_name="UNKNOWN" end
   if (caller_id_number == nil) then caller_id_name="UNKNOWN" end
   if (caller_uuid == nil) then caller_uuid="????" end
end

aLeg = session;

-- PROCESS ARGUMENTS

if (argv) then
   arg = argv
end

for key, value in ipairs(arg) do
   logError("Arg: "..key.." = "..value);
end

--
-- Dialplan args
--

if (#arg == 0) then
   logError("No arguments.");
   return;
end

if (arg[1] == "TEST") then
   process_test();
elseif (arg[1] == "RECORD_FRAG") then
   process_record();
else
   ivr.play(aLeg, ANNOUNCEMENTS.."sorry youre-having-problems.wav")
end

