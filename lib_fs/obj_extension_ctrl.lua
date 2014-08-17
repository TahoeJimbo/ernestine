
Route_ctrl = {}

--[[

PROPERTIES:

   

]]--

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

   object.extension_dict = {}

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

	 object.extension_dict[new_extension.id] = new_extension
      end
   end

   if DEBUG_EXTENSION then 
      table_dump("Extension list", object.extension_dict)
   end

   return object
end

function Route_ctrl:extension_from_digits(extension_digits)

   if DEBUG_EXTENSION then
      logInfo("Looking up <"..extension_digits..">")
   end

   local extension = self.extension_dict[extension_digits]

   if extension == nil then
      logError("Extension <"..extension_digits.."> NOT FOUND.")
      return nil
   end

   return extension
end

function Route_ctrl:location_id_from_digits(extension_digits)

   if DEBUG_EXTENSION then
      logInfo("Looking up location of <"..extension_digits..">")
   end

   local extension = self:extension_from_digits(extension_digits)

   if (extension == nil) then return nil; end

   local location_id = extension:get_location()

   if DEBUG_EXTENSION then
      logInfo("Extension <"..extension_digits.."> is in <"..location_id..">")
   end

   return location_id
end
