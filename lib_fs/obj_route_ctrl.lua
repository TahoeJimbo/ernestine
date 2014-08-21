
Route_ctrl = {}

--[[

The route controller manages individual routes to endpoints, and chooses the
best route to get there.

It can, for example: 
  Route emergency calls to a local land-line.
  Reroute calls during certain times of day.
  Reroute calls based on the location of the receiver.

--]]

                                                                 --[[ ROUTE_CTRL:NEW ]]--
function Route_ctrl:new(config_table)

   if config_table == nil then
      logError("Invalid argument")
      return nil
   end

   local object = {}
   setmetatable(object, self)
   self.__index = self

   object.def_domain = nil
   object.def_many_handsets = nil
   object.def_location = nil

   object.route_dict = {}

   for _, group in ipairs(config_table) do
      if group.group_name == "Route_Defaults" then
	 for _, kw in ipairs(g_route_defaults_keywords) do
	    if group.items[kw] then
	       object["def_"..kw] = group.items[kw]
	    end
	 end
      elseif group.group_name == "Route" then

	 local new_extension = Route:new(group.items, object)
	 
	 if new_extension == nil then return nil; end

	 object.route_dict[new_extension.id] = new_extension
      end
   end

   if DEBUG_ROUTE then 
      table_dump("Route list", object.route_dict)
   end

   return object
end

--
-- Find the route to the given route id.
--
                                                   --[[ ROUTE_CTRL:ROUTE_FROM_DIGITS ]]--

function Route_ctrl:route_from_digits(route_digits)

   if DEBUG_ROUTE then
      logInfo("Looking up <"..route_digits..">")
   end

   local route = self.route_dict[route_digits]

   if route == nil then
      logError("Route <"..route_digits.."> NOT FOUND.")
      return nil
   end

   if DEBUG_ROUTE then
      logInfo("Found route <"..route_digits..">, route: <"
		 ..route:get_route()..">")
   end

   return route
end

--
-- Find and return the location id for the given route id.
--
                                             --[[ ROUTE_CTRL:LOCATION_ID_FROM_DIGITS ]]--

function Route_ctrl:location_id_from_digits(route_digits)

   if DEBUG_ROUTE then
      logInfo("Looking up location of <"..route_digits..">")
   end

   local extension = self:route_from_digits(route_digits)

   if extension == nil then return nil; end

   local location_id = extension:get_location()

   if DEBUG_ROUTE then
      logInfo("Extension <"..route_digits.."> is in <"..location_id..">")
   end

   return location_id
end
