

Dialstring = {}

--[[

   Dialstring:new_custom(custom_dialstring)            -- Creates a dialstring object ready to parse
                                                       -- using a custom destination dialstring

   Dialstring:new_freeswitch(freeswitch_dialstring)    -- Creates a dialstring object with the 
                                                       -- pre-parsed freeswitch dialstring

   Dialstring:now_sofia(sofia_endpoint)                -- Creates a dialstring object with the
                                                       -- provided sofia endpoint string

   Dialstring:get()                                    -- Parses the dialstring, adding variables
                                                       -- to it (custom or sofia only)
                                                       -- returning it to the caller.

   Dialstring:set_variable(variable_name, value)       -- Sets a custom variable to be
                                                       -- used by all endpoints in the dialstring
                                                       -- (like "origination_caller_id_number", for
                                                       -- example.
]]--

--
--    CUSTOM DIALSTRING FORMAT:
--
--    Dialstring format = {extension}|{extensions list}
--
--    extensions list =  extension[:extension]+
--    extension = var=value | [0-9]+ | function(args)
--
--    vars:
--      wait=x      >>  wait x seconds for the person to answer
--                   the call before giving up.
--    functions:
--      VM(args)    >>  Transfer the call to specified voicemail extension.
-- 
--    example:
--      "wait=30|8001:wait=50,8002|8005|VM(8000)"
--      set the default answer time to 30 seconds.
--      call 8001 and 8002 in paralell, giving 8001 30 seconds to
--      answer (the default) and 8002 50 seconds.  If no answer after
--      that, give 8005 a crack for 30 seconds, then send the
--      call to voicemail for box 8000.


function Dialstring:new()
   local object = {}
   setmetatable(object,self)
   self.__index = self

   object.additional_vars = {}

   object.custom_dialstring = nil
   object.freeswitch_dialstring = nil
   object.sofia_dialstring = nil

   object.default_domain = nil

   object.parsed_dialstring = nil

   object.failed = false

   return object
end

function Dialstring:new_custom(custom_dialstring)

   if DEBUG then logInfo("Created new custom dialstring object for <"..custom_dialstring..">"); end

   local object = Dialstring:new()
   object.custom_dialstring = custom_dialstring

   return object
end

function Dialstring:new_freeswitch(fs_dialstring)

   if DEBUG then logInfo("Created new freeswitch dialstring object for <"..fs_dialstring..">"); end

   local object = Dialstring:new()
   object.freeswitch_dialstring = fs_dialstring

   return object
end

function Dialstring:new_sofia(sofia_dialstring)

   if DEBUG then logInfo("Created new sofia dialstring object for <"..sofia_dialstring..">"); end

   local object = Dialstring:new()
   object.sofia_dialstring = sofia_dialstring

   return object
end

function Dialstring:set_default_domain(default_domain)
   self.default_domain=default_domain
   self.parsed_dialstring = nil
end

function Dialstring:set_excluded_extension(excluded_extension)
   self.excluded_extension = excluded_extension
   self.parsed_dialstring = nil
end

function Dialstring:set_variable(name, value)
   if DEBUG then logInfo("Setting variable <"..name.."> to <"..value..">"); end
   self.additional_vars[name] = value
   self.parsed_dialstring = nil
end

function Dialstring:description()
   if (self.custom_dialstring) then
      return "custom["..self.custom_dialstring.."]"
   elseif (self.freeswitch_dialstring) then
      return "freeswitch["..self.freeswitch_dialstring.."]"
   elseif (self.sofia_dialstring) then
      return "sofia["..self.sofia_dialstring.."]"
   end

   return "[unknown]"
end

function Dialstring:get()
   if (self.parsed_dialstring) then
      if DEBUG then logInfo("Returning cached dialstring: <"..self.parsed_dialstring..">"); end
      return self.parsed_dialstring
   end

   -- No cached representation available...
   -- Create one from scratch.
   
   if self.custom_dialstring then
      local result_table = self:PRIV_parse_custom()
      return result_table
   end

   if self.sofia_dialstring then
      local result = self:PRIV_parse_sofia()
      return result
   end

   if self.freeswitch_dialstring then
      local result = self:PRIV_parse_freeswitch()
      return result
   end

   logError("Invalid Dialstring object: No dialstring to parse.")
   return nil
end

----------- PRIVATE ROUTINES FOR PARSING, ETC... -----------

--
-- For a sofia string, we just prepent any additional variables to the string
-- to statisfy the needs of the outgoing call. Usually this would involve adding
-- origination_caller_id_* variables.
--

function Dialstring:PRIV_parse_sofia()
   local global_variables = {}
   local local_variables = {}

   -- We already have code that merges our additional variables into
   -- a dialstring format, so let's use it, though it looks funny passing
   -- empty tables to it.

   local variable_string = self:PRIV_merge_variables(global_variables, local_variables)

   return variable_string..self.sofia_dialstring
end


function Dialstring:PRIV_parse_freeswitch()
   local global_variables = {}
   local local_variables = {}

   -- We already have code that merges our additional variables into
   -- a dialstring format, so let's use it, though it looks funny passing
   -- empty tables to it.

   local variable_string = self:PRIV_merge_variables(global_variables, local_variables)

   return variable_string..self.fs_dialstring
end


--
--    Returns: 
--      An unkeyed table with with each entry as a dialstring
--      to attempt dialing, or nil if the dialstring contained an error.
--
--      Each entry is a another table with the keys:
--         "kind" = the type of entry. "FU_VM" (voicemail function, box# in dialstring)
--                                  or "DS" (dial the call in dialstring)
--         "dialstring" = The dialstring data to be dialed.
--

function Dialstring:PRIV_parse_custom()

   local results = {}

   local dialstring = self.custom_dialstring

   excluded_extension = self.excluded_extension or ""

   if DEBUG then logInfo("Parsing <"..dialstring..">, excluding <"..excluded_extension..">"); end

   local global_variables = {};

   -- Break the dialstring up into serial blocks (separated by "|")

   local continueBlocks = string_split(dialstring, "|");

   -- Process each block

   for _,continueBlock in ipairs(continueBlocks) do

      --
      -- The processor returns the kind of block it is, "GL" for a global
      -- variable, which is kept in global_variables["name"] and are
      -- updated there when found.
      --
      -- "VM" for voicemail function, where we put the voicemail box as the
      -- dialstring.  (Function parameters are in the global_variables
      -- beginning with an underscore and should be erased when consumed.)
      --
      -- Anything else is an extension to be dialed.

      dialstring = self:PRIV_process_block(continueBlock, global_variables)

      if dialstring and dialstring ~= "" then

	 if dialstring == "GL" then
	    --skip
	 elseif dialstring == "FU" then
	    if (global_variables._FUNCTION_NAME == "VM") then
	       local result = {}
	       local extension = global_variables._0
	       
	       result.kind = "FU_VM"
	       result.dialstring = extension
	       
	       if DEBUG then logInfo("Voicemil Extension "..extension); end
	       global_variables._FUNCTION_NAME = nil
	       
	       table_append(results, result)
	    else
	       if UNIT_TESTING ~= true then logError("Unknown function: "..global_variables._FUNCTION_NAME); end
	       self.failed = true
	       return nil
	    end
	 else
	    local result = {}
	    result.kind = "DS"
	    result.dialstring = dialstring
	    table_append(results, result)
	 end
      end
   end

   if (self.failed) then 
      return nil
   end

   if DEBUG then table_dump("Dialstring table", results); end

   self.cached_dialstring = results
   return results;
end




-- Vocabulary:
--
-- dialstring entry = a full dialplan entry: "wait=30|wait=60,8001:4001|VM(546)"
-- dialstrign block = part of a dialplan entry between "|"s: "wait=60,8001:4001"
-- extension clause = part of a dialplan block between ":"s: "wait=60,8001"
-- variable declaration = part of an extension clause like "wait=60"


--
-- Process a dialplan variable declaration, placing it into the callvars table.
--
function Dialstring:PRIV_process_variable(variable, variables)

   if (DEBUG) then table_dump("Callvars before:", variables); end

   local parts = string_split(variable, "=");

   if (#parts == 2) then
      if (parts[1] == "wait") then
	 variables["call_timeout"] = parts[2];
      end
   end

   if (DEBUG) then table_dump("Callvars after", variables); end
end

function Dialstring:PRIV_merge_variables(global_variables, local_variables)

   local merged_variables = {}
   local count = 0

   -- First, copy all the additional variables into the global variables.  They override the
   -- globals.

   if self.additional_vars then
      for key,value in pairs(self.additional_vars) do
	 global_variables[key] = value
      end
   end
   
   for key,value in pairs(global_variables) do
      if (key:byte(1) == 95) then
	 -- skip variables beginning with "_"
      else
	 merged_variables[key] = value
	 count = count + 1
      end
   end

   for key,value in pairs(local_variables) do
      if (key:byte(1) == 95) then
	 -- skip variables beginning with "_"
      else
	 if (merged_variables[key] == nil) then
	    --
	    -- Creating a new variable.
	    --
	    merged_variables[key] = value
	    count = count + 1
	 else
	    --
	    -- Updating an existing variable.
	    --
	    merged_variables[key] = value
	 end
      end   
   end

   local sorted_variable_names = {}

   for item in pairs(merged_variables) do sorted_variable_names[#sorted_variable_names + 1] = item; end
   table.sort(sorted_variable_names)

   local merged_variable_string = "";
   local argument_count = 0;

   if (count ~= 0) then
      merged_variable_string = "[";
      
      for _, key in ipairs(sorted_variable_names) do
	 merged_variable_string = merged_variable_string..key.."="..merged_variables[key];
	 argument_count = argument_count + 1
	 if (argument_count ~= count) then
	    merged_variable_string = merged_variable_string..",";
	 end
      end
      
      merged_variable_string = merged_variable_string.."]";
   end

   return merged_variable_string
end

function Dialstring:PRIV_process_singleton_extension_part(singleton, global_variables)

   if string.match(singleton, "=") then
      self:PRIV_process_variable(singleton, global_variables);
      return "GL";
   end


   local func, arg;

   func, arg = string.match(singleton,"^(.+)%((.+)%)$");

   if (func) then                       -- we only support single argument functions
      global_variables._FUNCTION_NAME = func        -- at the moment
      global_variables._FUNCTION_ARG_COUNT = 1
      global_variables._0 = arg
      return "FU";
   end

   return nil
end

-- 
-- Process an extension clause
-- returning a code to indicate what it is.
--
-- Returns:
-- "GL" = Global Variable
-- "FU" = Function (setting _FUNCTION_NAME, _FUNCTION_ARG_COUNT and _0.._n as
--        arguments in the provided "global_variabless" table.
-- ""   = dialstring
--
-- For example: wait=60,8001 returns
-- "8001" and vars.call_timeout = 60   (wait is translated into freeswitch's call_timeout)

function Dialstring:PRIV_process_extension(extension_string, global_variables)

   local parts = {};

   local default_domain = self.default_domain or ""
   local excluded_extension = self.excluded_extension or ""

   if DEBUG then logInfo("Processing <"..extension_string.."> excluding <"..excluded_extension
			    .."> in domain <"..default_domain..">"); end

   -- Split the extension into fragments

   parts = string_split(extension_string, ",");

   if (#parts == 1) then
      -- Only one part.  Could be a global or a function

      local result = self:PRIV_process_singleton_extension_part(parts[1], global_variables)

      if result then return result; end
   end

   -- NOT a global variable or function, so process away!

   local local_variables = {};
   local_variables.hangup_after_bridge = "true";

   local extension_digits = "";

   for _,part in ipairs(parts) do
      if (string.match(part,"=")) then
	 self:PRIV_process_variable(part, local_variables);
      else
	 extension_digits = part;
      end
   end

   --
   -- An extension can be excluded from processing.  Usually this is
   -- the extension of the person calling, in case they're in the
   -- list of extensions to try.  
   --
   if (extension_digits == excluded_extension) then
      return "";
   end

   --
   -- Merge the global and local variables
   --

   local merged_variable_string = self:PRIV_merge_variables(global_variables, local_variables)

   -- If the extension digits have an @ or % sign in them, don't add the default domian.
   
   if default_domain ~= "" then 
      local ext, domain  = string.match(extension_digits,"^(.+)[%%@](.+)$")
      if (ext == nil) then
	 -- no @ or %.  Tack on default domain.
	 
	 extension_digits = extension_digits.."@"..default_domain
      else
	 --
	 -- Check the separated digits to see if they might be excluded...
	 --
	 if ext == excluded_extension then
	    return ""
	 end;
      end
   end

   return merged_variable_string.."User/"..extension_digits;
end

--
-- Process a block of the dialstrng
--

function Dialstring:PRIV_process_block(block, global_variables)

-- 1. Break the block into : separated extensions
-- 2. Process the : separated units.

   if (DEBUG) then
      logInfo("Processing <"..block..">")
   end

   local extensions = {};
   local dialstring = "";
   
   extensions = string_split(block, ":");

   for _,extension_string in ipairs(extensions) do
      if (DEBUG) then logInfo("Processing extension <"..extension_string..">"); end

      local dialstring_part = self:PRIV_process_extension(extension_string, global_variables)
      if (dialstring_part ~= "") then

	 if (dialstring ~= "") then
	    dialstring = dialstring..":_:";
	 end
      
	 dialstring = dialstring..dialstring_part;
      end
   end
   if (DEBUG) then logInfo("Returning <"..dialstring..">"); end
   return dialstring;
end


