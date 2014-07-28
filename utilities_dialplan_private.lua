
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

   return merged_variables, count
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

function dialplan_private.processExtension(extension, global_variables, excludeExtension)

   local parts = {};
   local part;

   -- An extension with only one = and no ","'s is a global assignment.

   parts = string_split(extension, ",");

   if (#parts == 1) then
      -- Only one part.  Maybe a global?

      if (string.match(parts[1],"=")) then
	 dialplan_private.process_variable(parts[1], global_variables);
	 return "GL";
      end

      local func, arg;

      func, arg = string.match(parts[1],"^(.+)%((.+)%)$");

      if (func) then                       -- we only support single argument functions
	 global_variables._FUNCTION_NAME = func        -- at the moment
	 global_variables._FUNCTION_ARG_COUNT = 1
	 global_variables._0 = arg
	 return "FU";
      end
   end

   -- NOT a global variable or function, so process away!

   local local_variables = {};
   local_variables.hangup_after_bridge = "true";

   local extensionDigits = "";

   for _,part in ipairs(parts) do
      if (string.match(part,"=")) then
	 dialplan_private.process_variable(part, local_variables);
      else
	 extensionDigits = part;
      end
   end

   --
   -- An extension can be excluded from processing.  Usually this is
   -- the extension of the person calling, in case they're in the
   -- list of extensions to try.  
   --
   if (extensionDigits == excludeExtension) then
      return "";
   end

   --
   -- Merge the global and local variables
   --

   local merged_variables, merged_variable_count  = dialplan_private.merge_variables(global_variables, local_variables)

   --
   -- Sort the varables so they remain deterministic between runs.
   -- (Turns out that this can be a big deal.)
   --
  
   local sorted_variable_names = {}

   for item in pairs(merged_variables) do sorted_variable_names[#sorted_variable_names + 1] = item; end
   table.sort(sorted_variable_names)

   local merged_variable_string = "";
   local argument_count = 0;

   if (merged_variable_count ~= 0) then
      merged_variable_string = "[";
      
      for _, key in ipairs(sorted_variable_names) do
	 merged_variable_string = merged_variable_string..key.."="..merged_variables[key];
	 argument_count = argument_count + 1
	 if (argument_count ~= merged_variable_count) then
	    merged_variable_string = merged_variable_string..",";
	 end
      end
      
      merged_variable_string = merged_variable_string.."]";
   end


   return merged_variable_string.."User/"..extensionDigits;
end

function dialplan_private.processBlock(block, vars, excludeExtension)

-- 1. Break the block into : separated extensions
-- 2. Process the : separated units.

   if (DEBUG) then
      logInfo("Processing <"..block..">, exluding <"..excludeExtension..">");
   end

   local extensions = {};
   local extension;
   local dialString = "";
   
   extensions = string_split(block, ":");

   for _,extension in ipairs(extensions) do
      if (DEBUG) then logInfo("Processing <"..extension..">"); end

      local dialStringPart = dialplan_private.processExtension(extension, vars,
							 excludeExtension);
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



