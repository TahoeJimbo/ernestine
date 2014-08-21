


function dispatch_outbound(source_obj, context, destination_digits, forced_cid)

   -- The source object has the destination number already configured...

   local dest_number_obj = source_obj:get_dest_number_obj()

   local destinations = gGateways:make_routes_for_destination(source_obj,
							      dest_number_obj)

   if destinations == nil or #destinations == 0 then
      sounds.sit(aLeg, "vacant")
      return
   end

   for index, destination in ipairs(destinations) do
      local result, message = destination:connect(source_obj.source_fs_session)
      
      if result == "COMPLETED" then
	 if DEBUG then logInfo("Outbound call completed normally."); end
	 return
      end

      logError("Call failed to destination "..index)
   end

   logError("Call could not be routed.  All routes failed.")
   sounds.sit(aLeg, "vacant")
end
