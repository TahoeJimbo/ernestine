
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



vm_cli_entrypoint()






