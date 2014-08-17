
Location = {}

g_location_parser_keywords = {
         "id", "description",
	 "activation_code",
         "default_caller_id_name","default_caller_id_number",
         "e911_id",
	 "local_code",
	 "numbering_plan"
}

function Location:new(config_pairs)

   local object = {}
   setmetatable(object, self)
   self.__index = self

   -- Copy the pairs in...

   for _, kw in ipairs(g_location_parser_keywords) do
      object[kw] = config_pairs[kw]
   end

   -- Sanity check the location...

   if object.id == nil then
      logError("Location id keyword is required for each location.")
      return nil
   end

   if object.default_caller_id_name == nil then
      logError("Location id <"..object.id..
		  "> needs to set the default_caller_id_name keyword.")
      return nil
   end

   if object.default_caller_id_number == nil then
      logError("Location id <"..object.id..
		  "> needs to set the default_caller_id_number keyword.")
      return nil
   end
   
   if object.local_code == nil then
      logError("Local area/city code required for location id <"..object.id..">")
      return nil
   end

   if object.numbering_plan == nil then
      logError("Location id <"..object.id..
		  "> needs to set the numbering_plan keyword.")
      return nil
   end

   return object
end

function Location:get_id()
   return self.id
end

function Location:get_description()
   if self.description then return self.description; end

   return "No description"
end

function Location:get_activation_code()
   return self.activation_code
end

function Location:get_caller_id_info()
   return self.default_caller_id_name, self.default_caller_id_number
end

function Location:get_e911_id()
   if self.e911_id then return self.e911_id; end

   return ""
end

function Location:get_local_code()
   if self.local_code then return self.local_code; end

   return ""
end

function Location:get_numbering_plan()
   return self.numbering_plan
end


