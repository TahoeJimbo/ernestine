
DID = {}

g_did_parser_keywords  = {
         "id", "description",
	 "dnd_start", "dnd_end",

         "e911_id",
	 "local_code",
	 "numbering_plan"
}

function DID:new(config_pairs)

   local object = {}
   setmetatable(object, self)
   self.__index = self

   -- Copy the pairs in...

   for _, kw in ipairs(g_did_parser_keywords) do
      object[kw] = config_pairs[kw]
   end

   -- Sanity check the DID...

   if object.default_caller_id_number == nil then
      logError("Location id <"..object.id..
		  "> needs to set the default_caller_id_number keyword.")
      return nil
   end
end

--[[

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

]]--
