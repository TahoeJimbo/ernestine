
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


