

Location_ctrl = {}

                                                              --[[ LOCATION_CTRL:NEW ]]--
function Location_ctrl:new(config_table)

   if DEBUG_LOCATION then
      logInfo("Creating new location controller.")
   end

   if config_table == nil then
      logError("Invalid argument")
      return nil
   end

   local object = {}
   setmetatable(object, self)
   self.__index = self

   object.location_list = {}
   object.location_code = {} 

   for _, group in ipairs(config_table) do
      if group.group_name == "Location" then

	 local new_location = Location:new(group.items)
	 
	 if new_location == nil then return nil; end

	 object.location_list[new_location.id] = new_location
	 if new_location.activation_code then
	    object.location_code[new_location.activation_code] = new_location
	 end
      end
   end

   if DEBUG_LOCATION then 
      table_dump("Location list", object.location_list, logInfo)
   end

   return object
end
                                                --[[ LOCATION_CTRL:LOCATION_FROM_ID ]]--

function Location_ctrl:location_from_id(location_id)
   
   if DEBUG_LOCATION then
      logInfo("Request for location <"..location_id..">")
   end

   local location = self.location_list[location_id]

   if location == nil then
      logError("Invalid location id <"..location_id..">")
      return nil
   end

   return location
end

function Location_ctrl:location_from_activation_code(activation_code)

   local location = self.location_code[activation_code]

   return location
end

----------------------------------------------------------------------------------------
-- LOCATION STATE

g_location_parser_config = {
   { group_name = "Location", keywords = { "extension", "location" } }
}

                                                --[[ LOCATION_CTRL:GET_USER_LOCATION ]]--
function Location_ctrl:get_user_location(vm_box)
   if DEBUG_LOCATION then 
      logInfo("Getting user location at box <"..vm_box..">")
   end
   local user_loc_id = self.location_data[vm_box]

   if user_loc_id then
      if DEBUG_LOCATION then 
	 logInfo("Location for user <"..vm_box.."> is <"..user_loc_id..">")
      end
   else
      logError("Could find location for <"..vm_box..">")
   end
   return user_loc_id
end

function Location_ctrl:set_user_location(extension, location_id)
   self.location_data[extension] = location_id
   self:save()
end

function Location_ctrl:load()                                --[[ LOCATION_CTRL:LOAD ]]--

   self.location_data={}

   if file_exists(LOC_CONFIG) then

      local location_parser, error_message
	                              = Parser:new(LOC_CONFIG, g_location_parser_config)

      if location_parser == nil then
	 logError("Could not read location file.")
      else
	 local config_pairs = location_parser.config_array

	 for _, group in ipairs(config_pairs) do
	    if group.group_name == "Location" then
		   local key = group.items.extension
		   local value = group.items.location

		   self.location_data[key] = value
	    end
	 end
	 if DEBUG_LOCATION then 
	    table_dump("Location user table:", self.location_data, logInfo)
	 end
	 return "OK"
      end
   end

   --
   -- Create the file
   --
   self.location_data = {}
   self.location_data["0"] = "none"
   self:save()
end

function Location_ctrl:save()                                --[[ LOCATION_CTRL:SAVE ]]--

   local status;

   --[[ Write the updated config file --]]

   status = self:PRIV_write()

   if status ~= "OK" then
      logError("Error writing configuration file to disk.")
      logError("Configuration file may be damaged.")
      return nil
   end

   return "OK"
end


function Location_ctrl:PRIV_write()                         --[[ LOCATION_CTRL:WRITE ]]--

    local file, err

    file, err = io.open(LOC_CONFIG, "w")

    if file == nil then
        logError("Could not open "..LOC_CONFIG.." for writing: "..err)
	return nil
    end

    --[[ Trundle through the config table and emit the config file --]]

    file:write("\n#  LOCATION STATE\n\n")

    for key, location in pairs(self.location_data) do
    	file:write("Location {\n")
	file:write("    extension = \""..key.."\"\n")
	file:write("    location = \""..location.."\"\n")
	file:write("}\n")
        file:write("\n")
    end
    
    file:close()

    return "OK"
end

