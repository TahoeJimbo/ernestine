
-- Vocabulary:
--
-- dialstring entry = a full dialplan entry: "wait=30|wait=60,8001:4001|VM(546)"
-- dialstrign block = part of a dialplan entry between "|"s: "wait=60,8001:4001"
-- extension clause = part of a dialplan block between ":"s: "wait=60,8001"
-- variable declaration = part of an extension clause like "wait=60"

dialplan_private = {};

--
-- Process a dialplan variable declaration, placing it into the callvars table.
--
function dialplan_private.process_variable(variable, variables)

   if (DEBUG) then table_dump("Callvars before:", variables); end

   local parts = string_split(variable, "=");

   if (#parts == 2) then
      if (parts[1] == "wait") then
	 variables["call_timeout"] = parts[2];
      end
   end

   if (DEBUG) then table_dump("Callvars after", variables); end
end

function dialplan_private.merge_variables(global_variables, local_variables)

   local merged_variables = {}
   local count = 0
   local key, value
   
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

function process_singleton_extension_part(singleton, global_variables)

   if string.match(singleton, "=") then
      dialplan_private.process_variable(singleton, global_variables);
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

function dialplan_private.process_extension(extension, global_variables,
					    excluded_extension, default_domain)

   local parts = {};
   local part;

   default_domain = default_domain or ""

   if DEBUG then logInfo("Processing <"..extension.."> excluding <"..excluded_extension
			    .."> in domain <"..default_domain..">"); end

   -- Split the extension into fragments

   parts = string_split(extension, ",");

   if (#parts == 1) then
      -- Only one part.  Could be a global or a function

      local result = process_singleton_extension_part(parts[1], global_variables)

      if result then return result; end
   end

   -- NOT a global variable or function, so process away!

   local local_variables = {};
   local_variables.hangup_after_bridge = "true";

   local extension_digits = "";

   for _,part in ipairs(parts) do
      if (string.match(part,"=")) then
	 dialplan_private.process_variable(part, local_variables);
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

   local merged_variable_string = dialplan_private.merge_variables(global_variables, local_variables)

   -- If the extension digits have an @ or % sign in them, don't add the default domian.
   
   if default_domain ~= "" then 
      ext, domain  = string.match(extension_digits,"^(.+)[%%@](.+)$")
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

function dialplan_private.process_block(block, global_variables, excluded_extension, default_domain)

-- 1. Break the block into : separated extensions
-- 2. Process the : separated units.

   if (DEBUG) then
      logInfo("Processing <"..block..">, exluding <"..excluded_extension..">");
   end

   local extensions = {};
   local extension;
   local dialString = "";
   
   extensions = string_split(block, ":");

   for _,extension in ipairs(extensions) do
      if (DEBUG) then logInfo("Processing extension <"..extension..">"); end

      local dialStringPart = dialplan_private.process_extension(extension, global_variables,
							        excluded_extension, default_domain);
      if (dialStringPart ~= "") then

	 if (dialString ~= "") then
	    dialString = dialString..":_:";
	 end
      
	 dialString = dialString..dialStringPart;
      end
   end
   if (DEBUG) then logInfo("Returning <"..dialString..">"); end
   return dialString;
end



