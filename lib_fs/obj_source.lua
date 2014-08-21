
Source = {}

--[[

Fields:
   source_fs_session
   source_caller_id_name
   source_caller_id_number
   source_uuid
   source_digits

   source_location_obj
   destination_number_obj
   destination_digits
   source_route_obj

--]]

--
-- Create a new "source" object, culling all sorts of information from
-- the provided FreeSWITCH call leg.
--
-- This object serves as a container that can be passed around, and helps
-- reduce a lot of duplicated code.
--
                                                                     --[[ SOURCE:NEW ]]--
function Source:new(fs_source_leg)
   
   if fs_source_leg == nil then 
      logError("Invalid argument.")
      return nil
   end
   
   local object = {}
   setmetatable(object, self)
   self.__index = self

   -- Determine the location of the source number if possible.
   
   local source_digits = fs_source_leg:getVariable("sip_from_user_stripped")
   local source_route = gRoutes:route_from_digits(source_digits)
   local source_location_id = source_route:get_location_id()

   if source_location_id == nil then
      logError("Cannot determine location of source <"..source_digits..">")
      return nil
   end

   local location_obj = gLocations:location_from_id(source_location_id)

   local source_numbering_plan = location_obj:get_numbering_plan()
   local source_local_code = location_obj:get_local_code()

   local destination_digits = fs_source_leg:getVariable("sip_to_user")
   local destination_number_obj

   if destination_digits then
      destination_number_obj = Number:new(source_numbering_plan,
					  source_local_code,
					  destination_digits)
   end

   local source_caller_id_name = fs_source_leg:getVariable("caller_id_name")

   if (source_caller_id_name == nil) then
      source_caller_id_name = fs_source_leg:getVariable("sip_from_user_stripped");
      
      if source_caller_id_name ~= nil then
	 fs_source_leg:setVariable("sip_from_display", source_caller_id_name);
      end
   end

   if source_caller_id_name == nil then
      source_caller_id_name = "NO ID PROVIDED"
   end

   object.source_fs_session = fs_source_leg
   object.source_caller_id_name = source_caller_id_name
   object.source_caller_id_number = fs_source_leg:getVariable("caller_id_number")
   object.source_uuid = fs_source_leg:getVariable("uuid")
   object.source_location_obj = location_obj
   object.destination_number_obj = destination_number_obj
   object.destination_digits = destination_digits
   object.source_digits = source_digits
   object.source_route_obj = source_route
	
   return object
end

function Source:get_fs_session()
   return self.source_fs_session
end

function Source:get_caller_id_info()
   return self.source_caller_id_name, self.source_caller_id_number
end

function Source:get_uuid()
   return self.uuid
end

function Source:get_source_digits()
   return self.source_digits
end

function Source:get_location_obj()
   return self.source_location_obj
end

function Source:get_dest_number_obj()
   return self.destination_number_obj
end

function Source:get_dest_digits()
   return self.destination_digits
end

function Source:get_source_route_obj()
   return self.source_route_obj
end
   
