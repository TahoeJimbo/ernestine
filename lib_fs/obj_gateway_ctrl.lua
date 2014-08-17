

Gateway_ctrl = {}

function Gateway_ctrl:new(config_table)

   if config_table == nil then
      logError("Invalid argument")
      return nil
   end

   local object = {}
   setmetatable(object, self)
   self.__index = self

   object.def_domestic_numbering_plan = nil
   object.def_local_code = nil
   object.def_outbound_emergency_format = nil
   object.def_outbound_special_format = nil
   object.def_outbound_local_format = nil
   object.def_outbound_domestic_format = nil
   object.def_outbound_intl_format = nil
   object.def_allowed_call_kinds = nil

   object.gateway_list = {}

   for _, group in ipairs(config_table) do
      if group.group_name == "Gateway_Defaults" then
	 for _, kw in ipairs(g_gateway_defaults_keywords) do
	    if group.items[kw] then
	       object["def_"..kw] = group.items[kw]
	    end
	 end
      elseif group.group_name == "Gateway" then

	 local newGateway = Gateway:new(group.items, object)
	 
	 if newGateway == nil then return nil; end

	 object.gateway_list[#object.gateway_list + 1] = newGateway
      end
   end

   if DEBUG_GATEWAY then 
      table_dump("Gateway list", object.gateway_list)
   end

   return object
end


--
-- Make a list of outgoing dial-strings that are appropriate
-- for the provided number object.
--
-- ALGO: The gateways are filtered to include only those
--       capable of handling the kind of call (local, domestic, etc.)
--
--       Then the list is sorted in the following order:
--       1) local gateways first
--       2) anonymous gateways (no location) second
--       3) other gateways (config file order)
--

function Gateway_ctrl:make_routes_for_destination(source_obj, destination_number_obj)

   local gateways = self:PRIV_get_capable_gateways(destination_number_obj,
						   source_obj.source_location_obj)

   if gateways == nil then return nil; end

   -- For each gateway, build an array of freeswitch dialstrings appropriate for
   -- that gateway...

   local destinations = {}
   local source_location_obj = source_obj.source_location_obj

   for _, gateway in ipairs(gateways) do
      local destination = gateway:make_destination_for_number(destination_number_obj,
							      source_location_obj)
      if destination then
	 destinations[#destinations + 1] = destination
      end
   end

   return destinations
end


function Gateway_ctrl:PRIV_get_capable_gateways(number_obj, source_location_obj)

   --
   -- Create a list of gateways that match our number type.
   -- 
   local class_matches = {}

   for _, gateway in ipairs(self.gateway_list) do

      local allowed_kinds = gateway.allowed_call_kinds

      if allowed_kinds and allowed_kinds:match(number_obj.kind) then
	 class_matches[#class_matches + 1] = gateway
      end
   end

   -- Zero matches?

   if #class_matches == 0 then
      --
      -- We're boned
      --
      logError("No capable gateways to <"..number_obj:format("%r")..">.")
      return nil
   end

   -- 
   -- Start the list with the ones matching our current location
   --

   local location_order = {}

   for _, gateway in ipairs(class_matches) do
      if gateway.location and gateway.location == source_location_obj.id then
	 location_order[#location_order + 1] = gateway
      end
   end

   -- Then add the ones with no location

   for _, gateway in ipairs(class_matches) do
      if not gateway.location then
	 location_order[#location_order + 1] = gateway
      end
   end

   -- Finally add the ones with other locations

   for _, gateway in ipairs(class_matches) do
      if gateway.location and gateway.location ~= source_location_obj.id then
	 location_order[#location_order + 1] = gateway
      end
   end

   -- DONE!

   return location_order
end

