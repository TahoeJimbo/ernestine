
Source = {}

--[[

Fields:
   source_fs_session
   source_caller_id_name
   source_caller_id_number
   source_uuid

   source_location_obj
   destination_number_obj

--]]

function Source:new(fs_source_leg)
   
   if fs_source_leg == nil then 
      logError("Invalid argument.")
      return nil
   end
   
   local object = {}
   setmetatable(object, self)
   self.__index = self

   object.source_fs_session = fs_source_leg
   object.source_caller_id_name = fs_source_leg:getVariable("caller_id_name")
   object.source_caller_id_number = fs_source_leg:getVariable("caller_id_number")
   object.source_uuid = fs_source_leg:getVariable("uuid")

   -- Determine the location of the source number if possible.

   local source_digits = fs_source_leg:getVariable("sip_from_user_stripped")

   local source_location_id =  gExtensions:location_id_from_digits(source_digits)

   if source_location_id == nil then
      logError("Cannot determine location of source <"..source_digits..">")
      return nil
   end

   local location_obj = gLocations:location_from_id(source_location_id)

   local source_numbering_plan = location_obj:get_numbering_plan()
   local source_local_code = location_obj:get_local_code()

   local destination_digits = fs_source_leg:getVariable("sip_to_user")

   if destination_digits then
      object.destination_number_obj = Number:new(source_numbering_plan,
						 source_local_code,
						 destination_digits)
      if object.destination_number_obj == nil then
	 if DEBUG_SOURCE then
	    logError("Error creating destination number object for <"
			..destination_digits..">")
	 end
	 return nil
      end
   end

   object.source_location_obj = location_obj
	
   return object
end

