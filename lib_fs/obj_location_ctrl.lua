

Location_ctrl = {}

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

   object.extension_controller = nil      -- Provided later by extension parser

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
      table_dump("Location list", object.location_list)
   end

   return object
end

--[[

function Location_ctrl:register_extension_controller(extension_controller)
   if DEBUG_LOCATION then
      logInfo("Registering extension controller.")
   end

   self.extension_controller = extension_controller
end

]]--

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


--[[


function Location_ctrl:get_default_cid(location_id)

   local location = self.location_list[location_id]

   if location == nil then return nil, nil; end

   return location.default_caller_id_name, location.default_caller_id_number
end

function Location_ctrl:get_local_code(location_id)

   local location = self.location_list[location_id]

   if location == nil then return nil, nil; end

   return location.local_code
end

function Location_ctrl:get_from_access_code(access_code)

   local location = self.location_code[access_code]

   if location == nil then return nil; end

   return location
end

function Location_ctrl:get_numbering_plan(location_id)

   local location = self.location_list[location_id]

   if location == nil then return nil; end

   return location.numbering_plan

end
]]--


-- LOCATION: tahoe-house, outside, scruz-house

kTAHOE =   "tahoe"
kOUTSIDE = "outside"
kSCRUZ =   "scruz"

-- Different locations can be stored for different extensions.  The location database
-- is written out as a lua table, which can be imported.  
--
-- If the table cannot be opened or read, the table is created with default
-- values that are surely wrong.
--

location = {}
location_data = {};

function location.write()                                --[[ LOCATE WRITE --]]

    local file, err

    file, err = io.open(LOC_CONFIG, "w")

    if (file == nil) then
        logError("Could not open "..LOC_CONFIG.." for writing: "..err)
	return "ERR_OPEN"
    end

    --[[ Trundle through the config table and emit a self-documenting file --]]

    file:write("\n--[[ LOCATION DATA --]]\n\n");

    for _, location_datum in pairs(location_data) do
    	file:write("Location ")
    	serialize(file, location_datum)
        file:write("\n")
    end
    
    file:close()

    return "OK"
end

function location.load()                                 --[[ LOCATION LOAD--]]
   location_data={}

   if (file_exists(LOC_CONFIG)) then
      dofile(LOC_CONFIG);
      return "OK";
   else 
      location_data = {}
      location_data["546"] = {}
      location_data["546"]["extension"] = "546"
      location_data["546"]["location"] = kTAHOE;
      location.save();
   end
end

function location.save()                                --[[ LOCATION SAVE --]]

   local status;

   --[[ Write the updated config file --]]

   status = location.write()

   if (status ~= "OK") then
      logError("Error writing configuration file to disk.")
      logError("Configuration file may be damaged.")
      return "ERR_UPDATE"
   end

   return "OK"
end

function location.get(extension)
   if (location_data[extension]) then
      return location_data[extension].location;
   end
end

--]-]

