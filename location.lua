

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

function Location(table)
   location_data[table["extension"]] = table
end

function location.write()                                --[[ LOCATE WRITE --]]

    local file, err
    local key, location_datum

    file, err = io.open(LOC_CONFIG, "w")

    if (file == nil) then
        logError("Could not open "..LOC_CONFIG.." for writing: "..err)
	return "ERR_OPEN"
    end

    --[[ Trundle through the config table and emit a self-documenting file --]]

    file:write("\n--[[ LOCATION DATA --]]\n\n");

    for key,location_datum in pairs(location_data) do
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
