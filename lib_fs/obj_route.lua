

Route = {}

g_route_parser_keywords = {
          "id",
	  "description",
          "domain",
	  "kind",
          "route",
          "many_handsets",
          "location",
      }

g_route_defaults_keywords = {
          "domain",
          "kind",
          "many_handsets",
          "location",
      }

--[[

PROPERTIES:

]]--

--
-- Configure a list of gateways as described in the parser-generated
-- configuration_table.
--
-- We extract the Gateway_Defaults and Gateway blocks and use them to create
-- Gateway objects.
--

                                                                      --[[ ROUTE:NEW ]]--
function Route:new(config_pairs, controller)

   local object = {}
   setmetatable(object, self)
   self.__index = self

   -- Copy the pairs in...

   for _, kw in ipairs(g_route_parser_keywords) do
      if config_pairs[kw] == nil then
         config_pairs[kw] = controller["def_"..kw]
      end

      object[kw] = config_pairs[kw]
   end

   -- Sanity check the location...

   if object.id == nil then
      logError("Route id keyword is required for each extension.")
      return nil
   end

   if object.domain == nil then
      logError("Route id <"..object.id..
		  "> needs to set the domain keyword.")
      return nil
   end

   if object.route == nil then
      logError("Route id <"..object.id..
		  "> needs to set the dialstring keyword.")
      return nil
   end
   
   if object.location == nil then
      logError("Route id <"..object.id.."> needs to set the location keyword.")
      return nil
   end

   if object.many_handsets ~= nil then
      local tf = parse_true_false(object.many_handsets)

      if tf == nil then
	 logError("Route id <"..object.id.."> many_handsets value <"
		     ..object.many_handsets..">: should be yes/no/true/false")
      else
	 object.many_handsets = tf
      end
   end

   return object
end

function Route:get_id()
   return self.id
end

function Route:get_domain()
   return self.domain
end

function Route:get_route()
   return self.route
end

function Route:get_many_handsets()
   return self.many_handsets
end

function Route:get_location_id()
   return self.location
end




