

----- DISPATCH ARGUMENTS -------------------------------------------------------

function process_dialplan_inbound()
   if (#arg ~= 3) then
      logError("Wrong number of arguments.");
      return;
   end

   local extension = arg[2];
   local context = arg[3];

   logError("Starting dialplan: Extension "..extension
	    ..", Context: "..context);
   dialplan_entrypoint_inbound(session, context, extension);
   logError("Finishing dialplan: Extension "..extension
	    ..", Context: "..context);
end

function process_dialplan_outbound()
   if (#arg ~= 3) then
      logError("Wrong number of arguments.");
      return;
   end

   local extension = arg[2];
   local context = arg[3];

   logError("Starting dialplan: Extension "..extension
	    ..", Context: "..context);
   dialplan_entrypoint_outbound(session, context, extension);
   logError("Finishing dialplan: Extension "..extension
	    ..", Context: "..context);
end

function process_vm_record()
   if (#arg ~= 3) then
      logError("process_vm_record(): Wrong number of arguments.");
      return;
   end

   local extension = arg[2];
   local greeting = arg[3];
   
   logError("Starting voicemail record: Extension: "..extension
	    ..", greeting: "..greeting);
   vm_record_entrypoint(session, extension, greeting);
   logError("Finishing voicemail record: Extension: "..extension
	    ..", greeting: "..greeting);
end
   

function process_vm_menu()
   if (#arg ~= 2) then
      logError("process_vm_menu(): Wrong number of arguments.");
      return;
   end

   local extension = arg[2];

   logError("Starting voicemail menu: Extension: "..extension);
   vm_menu_entrypoint(session, extension);
   logError("Finishing voicemail menu: Extension: "..extension);
end

function process_vm_cli()
   if (#arg ~= 1) then
      logError("process_vm_cli(): Wrong number of arguments.");
      return;
   end

   vm_cli_entrypoint();
end

function process_chaos_ivr()
   if (#arg ~= 1) then
      logError("process_chaos_ivr(): Wrong number of arguments.");
      return;
   end
   logError("Starting Carpe Chaos IVR");   
   chaos_ivr_entrypoint(session);
   logError("Finishing Carpe Chaos IVR");   
end

function process_set_location()
   if (#arg ~= 3) then
      logError("process_location(): Wrong number of arguments.");
      return;
   end

   local extension = arg[2];
   local location_name = arg[3];

   logError("Starting location 'set' processing.");
   
   location_data[extension] = {};
   location_data[extension].extension = extension;
   location_data[extension].location = location_name;

   location.save();

   logError("Finishing location 'set' processing.");
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

location.load();

if (arg[1] == "DIALPLAN-IN") then
   process_dialplan_inbound()
elseif (arg[1] == "DIALPLAN-OUT") then
   process_dialplan_outbound()
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

