

-- ######
--  MAIN
-- ######


function dialplan_get_outgoing_caller_id(aLeg)

   local source_extension_digits = aLeg:getVariable("sip_from_user_stripped");
   local extension = extensions[source_extension_digits]

   local external_caller_id_number
   local external_caller_id_name

   if (extension) then
      external_caller_id_name = extension.external_caller_id_name
      external_caller_id_number = extension.external_caller_id_number
   else
      external_caller_id_name = CALLER_ID_NAME_LAST_RESORT
      external_caller_id_number = CALLER_ID_NUMBER_LAST_RESORT
   end

   return external_caller_id_name, external_caller_id_number
end


function dialplan_is_nanpa_number(destination)
   
   local area_code, local_number

   area_code, local_number = string.match(destination, "^1([2-9]%d%d)([2-9]%d%d%d%d%d%d)$")

   if (area_code == nil) then
      area_code, local_number = string.match(destination, "^%+1([2-9]%d%d)([2-9]%d%d%d%d%d%d)$")

      if (area_code == nil) then 
	 local_number = string.match(destination, "^([2-9]%d%d%d%d%d%d)$")
      end
   end

   if (local_number == nil) then
      --
      -- We've run out of options.  None of our patterns match, so this ain't a NANPA number.
      --
      logInfo(destination.." is not a NANPA formatted number.")
      return nil, nil
   end

   --
   -- Seven digits is a local number so just return it.
   --

   if area_code and area_code ~= LOCAL_AREA_CODE then
      logInfo("Domestic number: "..area_code..local_number)
      return "domestic", area_code..local_number
   end

   logInfo("Local number: "..local_number)
   return "local", local_number
end

function route_to_carrier(aLeg, kind, destination_obj, outpulsed_number)

   local result = nil
   local message = nil


   if DEBUG then logInfo("Routing "..kind.."("..outpulsed_number..")"); end

   -- Try grandstream for SSN calls.

   if kind == "SSN" then
      local dialstring="sofia/gateway/public::grandstream-tahoe/"..outpulsed_number
      destination_obj:set_sofia_dialstring(dialstring)

      result, message = destination_obj:connect(aLeg)
      logError("result="..result..", message="..message)
   end

   if kind == "domestic" then
      --dialstring="sofia/gateway/public::callcentric-tahoe/1"..outpulsed_number

      dialstring="sofia/gateway/public::flowroute/34197194*1"..outpulsed_number
      destination_obj:set_sofia_dialstring(dialstring)

      logInfo("Routing domestic call: "..dialstring)      

      result, message = destination_obj:connect(aLeg)
      logError("result="..result..", message="..message)
   end

   if kind == "local" then
      --dialstring="sofia/gateway/public::grandstream-tahoe/1530"..outpulsed_number

      dialstring="sofia/gateway/public::flowroute/34197194*1530"..outpulsed_number
      destination_obj:set_sofia_dialstring(dialstring)
      result, message = destination_obj:connect(aLeg)

      logError("result="..result..", message="..message)
   end

   if kind == "international" then
      dialstring="sofia/gateway/public::grandstream-tahoe/011"..outpulsed_number
      destination_obj:set_sofia_dialstring(dialstring)
      result, message = destination_obj:connect(aLeg)
      logError("result="..result..", message="..message)
   end

   if result ~= "COMPLETED" then
      sounds.sit(aLeg, "intercept")
   end
end

function dispatch_outbound(aLeg, context, destination, forced_cid)

   local destination_obj = Destination:new()

   ------CHOOSE OUR OUTGOING CALLER ID VALUES------

   local cid_name, cid_number
   
   if forced_cid == true then
      cid_name = "Mary Smith"
      cid_number = "19078419799"
   else
      cid_name, cid_number = dialplan_get_outgoing_caller_id(aLeg)
   end

   destination_obj:set_source_caller_id(cid_name, cid_number)

   ------PARSE THE OUTBOUND NUMBER------

   local number_kind
   local outpulsed_number

   number_kind, outpulsed_number = dialplan_is_nanpa_number(destination)

   if number_kind then 
      route_to_carrier(aLeg, number_kind, destination_obj, outpulsed_number)
      return
   end

   -- International 011X* ?

   outpulsed_number = string.match(destination, "^%+(%d+)$")

   if (outpulsed_number) then 
      route_to_carrier(aLeg, "international", destination_obj, outpulsed_number)
      return
   end

   outpulsed_number = string.match(destination, "^011(%d+)$")

   if (outpulsed_number) then
      route_to_carrier(aLeg, "international", destination_obj, outpulsed_number)
      return
   end

   -- NANPA Special Services Number NXX?

   outpulsed_number = string.match(destination, "^([2-9]%d%d)$")

   if (outpulsed_number) then
      route_to_carrier(aLeg, "SSN", destination_obj, outpulsed_number)
      return
   end

   -- No clue wtf this is...

   sounds.sit(aLeg, "vacant")
end
   

function dialplan_entrypoint_outbound(session, context, destination)

   logError("STARTING OUTBOUND DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");
	    dispatch_outbound(session, context, destination);
   logError("ENDING OUTBOUND DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");

end
