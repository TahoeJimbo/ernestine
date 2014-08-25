

VM_config = {}

g_vm_box_config_keywords = {
   "mailbox",
   "description",
   "password",
   "notify_list",
   "auto_password:boolean" 
}

g_vm_parser_config = {
   { group_name = "Mailbox", keywords = g_vm_box_config_keywords }
}


--
-- Initailze the voicemail in-core configuration by reading it from
-- disk.
--
-- Returns:
--
--  config_object, nil    == SUCCESS
--  nil, error_message    == FAILURE
--

function VM_config:new()
   local object = {}
   
   setmetatable(object, self)
   self.__index = self

   object.config = {}

   local result = object:PRIV_open(VM_CONFIG)

   if result ~= "OK" then
      return nil, result
   end

   return object, nil
end

--
-- Rewrite the current configuration to disk
--
-- Returns "OK" or an error message

function VM_config:update()

   local backup_name_source, backup_name_dest
   local result

   local backup_versions_to_keep = 5

   for backup = backup_versions_to_keep - 1, 0, -1 do
      if backup == 0 then 
	 backup_name_source = VM_CONFIG
      else
	 backup_name_source = VM_CONFIG_BACKUP..tostring(backup)
      end
      backup_name_dest = VM_CONFIG_BACKUP..tostring(backup + 1) 

      if backup == backup_versions_to_keep - 1 
	 and file_exists(backup_name_dest) then

	     file_delete(backup_name_dest)
      end

      if file_exists(backup_name_source) then
	 result = file_rename(backup_name_source, backup_name_dest)
	 if result ~= true then
	    return "Error trying to rotate backup files."
	 end
      end
   end

   return self:PRIV_write(VM_CONFIG)
end

--
-- Initialize a new mailbox configuration
-- and update the configuration file on disk.
--
-- NOTE: This DOES NOT create the actual physical mailbox
--       structure on disk.
--
-- Returns "OK" or an error message

function VM_config:initialize_mailbox_config(box_num)

    local mailbox = {}

    mailbox.mailbox = box_num
    mailbox.password = "1234"
    mailbox.description = "Voicemail User (Change me)"
    
    self.config[box_num] = mailbox

    return self:update()
end

----------PRIVATE------------------------------------------------------------------------

--
-- Open and parse the config file at the given path.
--
-- Returns "OK" or an error message.
--

function VM_config:PRIV_open(file_path)
   local parsed_config, error_message = Parser:new(file_path, g_vm_parser_config)

   if not parsed_config then
      return error_message
   end

   self.config = {}

   table_dump("parsed config", parsed_config.config_array)
   
   for _, group in ipairs(parsed_config.config_array) do
      if DEBUG_VM_CONFIG then
	 logInfo("Parsing config for "..group.group_name)
      end
      if group.group_name == "Mailbox" then
	 local items = group.items
	 
	 self.config[items.mailbox] = items
      end
   end

   return "OK"
end

-- Write the current live configuration to the given path.
--
-- Returns "OK" or an error message.
--

function VM_config:PRIV_write(file_path)

   local file, err = io.open(file_path, "w")

   if (file == nil) then
      return "Could not open "..file_path.." for writing: "..err
   end

   --[[ Trundle through the config table and emit a self-documenting file --]]

   file:write("\n# VOICEMAIL CONFIGURATION\n\n");

   for box_num, box_config in pairs(self.config) do
      file:write("Mailbox {\n")
      
      for _,full_key in ipairs(g_vm_box_config_keywords) do
	 local key, key_kind = Parser:get_name_and_type(full_key)
	 local value = box_config[key]

	 if value then
	    if key_kind == "boolean" then
	       if value == true then value = "YES"; else value = "NO"; end
	    end
	    file:write("    "..key.." = \""..value.."\"\n")
	 end
      end

      file:write("}\n\n")
   end
   
   file:close()

   return "OK"
end



