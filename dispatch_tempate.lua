
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

--
-- APPLICATION INIT GOES HERE
--

--
-- APPLICATION DISPATCH GOES HERE
--

--[[    EXAMPLE EXAMPLE EXAMPLE
if (arg[1] == "DIALPLAN") then
   process_dialplan();
elseif (arg[1] == "VM_RECORD") then
   process_vm_record();
elseif (arg[1] == "VM_MENU") then
   process_vm_menu();
elseif (arg[1] == "VM_CLI") then
   process_vm_cli();
elseif (arg[1] == "CHAOS_IVR") then
   process_chaos_ivr();
elseif (arg[1] == "LOCATION_SET") then
   process_set_location();
end

--]]
