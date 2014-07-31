

-- ######
--  MAIN
-- ######


function dialplan_set_outgoing_caller_id(aLeg)

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

   session:setVariable("effective_caller_id_name", external_caller_id_name)
   session:setVariable("effective_caller_id_number", external_caller_id_number)
end


function dialplan_is_nanpa_number(destination)
   
   local area_code, local_number

   area_code, local_number = string.match(destination, "^1([2-9]%d%d)([2-9]%d%d%d%d%d%d)$")

   if (area_code) then goto check_for_local; end

   area_code, local_number = string.match(destination, "^%+1([2-9]%d%d)([2-9]%d%d%d%d%d%d)$")

   if (area_code) then goto check_for_local; end

   local_number = string.match(destination, "^([2-9]%d%d%d%d%d%d)$")

   if (local_number == nil) then
      --
      -- We've run out of options.  None of our patterns match, so this ain't a NANPA number.
      --
      return nil, nil
   end

   --
   -- Seven digits is a local number so just return it.
   --

   if (local_number) then
      return "local", local_number
   end

   ::check_for_local::

   if area_code == LOCAL_AREA_CODE then
      return "local", local_number
   end

   return "domestic", area_code..local_number

end

function route_to_carrier(aLeg, kind, outpulsed_number)

   local result, message

   -- Try grandstream for SSN calls.

   if kind == "SSN" then
      dialstring="sofia/gateway/public::grandstream-tahoe/"..outpulsed_number
      result, message = dialplan.connect_freeswitch_style(aLeg, dialstring)
      logError("result="..result..", message="..message)
   end

   if result ~= "COMPLETED" then
      sounds.sit(aLeg, "intercept")
   end
end

function dispatch_outbound(aLeg, context, destination)

   ------CHOOSE OUR OUTGOING CALLER ID VALUES------

   dialplan_set_outgoing_caller_id(aLeg)

   ------PARSE THE OUTBOUND NUMBER------

   local local_call = false
   local domestic_call = false

   local number_kind
   local outpulsed_number

   number_kind, outpulsed_number = dialplan_is_nanpa_number(destination)

   if (number_kind) then 
      route_to_carrier(number_kind, outpulsed_number)
      return
   end

   -- International 011X* ?

   outpulsed_number = string.match(destination, "^%+(%d+)$")

   if (outpulsed_number) then 
      route_to_carrier(aLeg, "international", outpulsed_number)
      return
   end

   outpulsed_number = string.match(destination, "^011(%d+)$")

   if (outpulsed_number) then
      route_to_carrier(aLeg, "international", outpulsed_number)
      return
   end

   -- NANPA Special Services Number NXX?

   outpulsed_number = string.match(destination, "^([2-9]%d%d)$")

   if (outpulsed_number) then
      route_to_carrier(aLeg, "SSN", outpulsed_number)
      return
   end

   -- No clue wtf this is...

   sounds.sit(aLeg, "vacant")
end
   

function dialplan_entrypoint_outbound(session, context, destination)

   logError("STARTING OUTBOUND DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");
	    dispatch_outbound(aLeg, context, destination);
   logError("ENDING OUTBOUND DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");

end
