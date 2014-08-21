

Dialstring = {}

--[[

   Dialstring:new_custom(custom_dialstring)          -- Creates a dialstring object
                                                     -- ready to parse using a custom
                                                     -- destination dialstring

   Dialstring:new_freeswitch(freeswitch_dialstring)  -- Creates a dialstring object with
                                                     -- the pre-parsed freeswitch
                                                     -- dialstring

   Dialstring:now_sofia(sofia_endpoint)              -- Creates a dialstring object with
                                                     -- the provided sofia endpoint 
                                                     -- string

   Dialstring:get()                                  -- Parses the dialstring, adding
                                                     -- variables to it (custom or sofia
                                                     -- only) returning it to the caller.

   Dialstring:set_variable(variable_name, value)     -- Sets a custom variable to be
                                                     -- used by all endpoints in the
                                                     -- dialstring (like
                                                     -- "origination_caller_id_number",
                                                     -- for example.
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
--      VM(box[,greeting#])    >>  Transfer the call to specified voicemail extension.
--      IF_TIME(start,finish,route) >> Transfer to route the current time is within the
--                                     interval
--      IF_LOC(vmbox,location,route) >> Transfer to route if the owner of the
--                                      voicemail box is at location
--      GOTO(route) >> Stops current route and continues to the specified route

--    example:
--      "wait=30|8001:wait=50,8002|8005|VM(8000)"

--      set the default answer time to 30 seconds.
--      call 8001 and 8002 in paralell, giving 8001 30 seconds to
--      answer (the default) and 8002 50 seconds.  If no answer after
--      that, give 8005 a crack for 30 seconds, then send the
--      call to voicemail for box 8000.


                                                                 --[[ DIALSTRING:NEW ]]--

-- DO NOT CALL THIS --
-- Call one of the new_* convenience constructors below...

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

----------CONSTRUCTORS AND INITIALIZATION------------------------------------------------
--
-- Create a dialstring object and associate a dialstring with it...
-- 
                                                          --[[ DIALSTRING:NEW_CUSTOM ]]--
function Dialstring:new_custom(custom_dialstring)

   if DEBUG_DIALSTRING then
      logInfo("Created new custom dialstring object for <"..custom_dialstring..">")
   end

   local object = Dialstring:new()
   object.custom_dialstring = custom_dialstring

   return object
end

                                                      --[[ DIALSTRING:NEW_FREESWITCH ]]--
function Dialstring:new_freeswitch(fs_dialstring)

   if DEBUG_DIALSTRING then
      logInfo("Created new freeswitch dialstring object for <"..fs_dialstring..">")
   end

   local object = Dialstring:new()
   object.freeswitch_dialstring = fs_dialstring

   return object
end
                                                           --[[ DIALSTRING:NEW_SOFIA ]]--
function Dialstring:new_sofia(sofia_dialstring)

   if DEBUG_DIALSTRING then
      logInfo("Created new sofia dialstring object for <"..sofia_dialstring..">")
   end

   local object = Dialstring:new()
   object.sofia_dialstring = sofia_dialstring

   return object
end

----------PROPERTY ACCESSORS-------------------------------------------------------------

                                                  --[[ DIALSTRING:SET_DEFAULT_DOMAIN ]]--
function Dialstring:set_default_domain(default_domain)
   self.default_domain=default_domain
   self.parsed_dialstring = nil
end

--
-- The provided extension will be omitted from the rendered dialstring.
--
-- This is primarily used to remove the calling extension when a route
-- is expanded and it includes the calling extension.  It wouldn't be
-- very nice to have the call ring back to the caller.  
--
                                                  --[[ DIALSTRING:SET_DEFAULT_DOMAIN ]]--
function Dialstring:set_excluded_extension(excluded_extension)
   self.excluded_extension = excluded_extension
   self.parsed_dialstring = nil
end

--
-- Variables added here will be inserted into the rendered dialstring.  If
-- a global variable (in a custom dialstring) shares the same name, the variable
-- added here will overwrite it when the dialstring is rendered.
--
                                                        --[[ DIALSTRING:SET_VARIABLE ]]--
function Dialstring:set_variable(name, value)
   if DEBUG_DIALSTRING then 
      logInfo("Setting variable <"..name.."> to <"..value..">")
   end

   self.additional_vars[name] = value
   self.parsed_dialstring = nil
end
                                                         --[[ DIALSTRING:DESCRIPTION ]]--
function Dialstring:description()
   if self.custom_dialstring then
      return "custom["..self.custom_dialstring.."]"
   elseif self.freeswitch_dialstring then
      return "freeswitch["..self.freeswitch_dialstring.."]"
   elseif self.sofia_dialstring then
      return "sofia["..self.sofia_dialstring.."]"
   end

   return "[unknown]"
end

--
-- Render the dialstring, expanding multiple extensions into an array of stand-alone
-- dialstring entries that should be called serially by FreeSWITCH.
--
-- For example: "wait=30,8000|VM(546)"
--
-- Might return:
--
-- results[1] = table { kind = "DS", dialstring = "{call_timeout=30...etc}/User/8000" }
-- results[2] = table { kind = "FU_VM", dialstring = "546" }
--
                                                                 --[[ DIALSTRING:GET ]]--
function Dialstring:get()
   if self.parsed_dialstring then
      if DEBUG_DIALSTRING then
	 logInfo("Returning cached dialstring: <"..self.parsed_dialstring..">")
      end
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

----------- PRIVATE ROUTINES FOR PARSING, ETC... ----------------------------------------

--
-- For a sofia string, we just prepent any additional variables to the string
-- to statisfy the needs of the outgoing call. Usually this would involve adding
-- origination_caller_id_* variables.
--

                                                    --[[ DIALSTRING:PRIV_PARSE_SOFIA ]]--
function Dialstring:PRIV_parse_sofia()
   local global_variables = {}
   local local_variables = {}

   -- We already have code that merges our additional variables into
   -- a dialstring format, so let's use it, though it looks funny passing
   -- empty tables to it.

   local variable_string = self:PRIV_merge_variables(global_variables, local_variables)

   return variable_string..self.sofia_dialstring
end

                                               --[[ DIALSTRING:PRIV_PARSE_FREESWITCH ]]--
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
                                                    --[[DIALSTRING:PRIV_PARSE_CUSTOM ]]--
function Dialstring:PRIV_parse_custom()

   local results = {}

   local dialstring = self.custom_dialstring

   excluded_extension = self.excluded_extension or ""

   if DEBUG_DIALSTRING then
      logInfo("Parsing <"..dialstring..">, excluding <"..excluded_extension..">")
   end

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
	    local function_name = global_variables._FUNCTION_NAME

	    if function_name  == "VM" or function_name == "IF_LOC"
	       or function_name == "IF_TIME" or function_name == "GOTO" then

	       local result = {}
	       local args = global_variables._0
	       
	       result.kind = "FU_"..function_name
	       result.dialstring = args
	       
	       if DEBUG_DIALSTRING then
		  logInfo("Function "..function_name.."("..args..")")
	       end

	       global_variables._FUNCTION_NAME = nil
	       
	       table_append(results, result)
	    else
	       logError("Unknown function: "..function_name)
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

   if self.failed then 
      return nil
   end

   if DEBUG_DIALSTRING then table_dump("Dialstring table", results); end

   self.cached_dialstring = results
   return results;
end

--
--
-- Vocabulary for parsing routines:
--
-- dialstring entry = a full dialplan entry: "wait=30|wait=60,8001:4001|VM(546)"
-- dialstring block = part of a dialplan entry between "|"s: "wait=60,8001:4001"
-- extension clause = part of a dialplan block between ":"s: "wait=60,8001"
-- variable declaration = part of an extension clause like "wait=60"

--
-- Process a dialplan variable declaration, placing it into the callvars table.
--
                                               --[[ DIALSTRING:PRIV_PROCESS_VARIABLE ]]--

function Dialstring:PRIV_process_variable(variable, variables)

   if DEBUG_DIALSTRING then table_dump("Callvars before:", variables); end

   local parts = string_split(variable, "=")

   if #parts == 2 then
      if parts[1] == "wait" then
	 variables["call_timeout"] = parts[2]
      else
	 variables[parts[1]] = parts[2]
      end
   end

   if DEBUG_DIALSTRING then table_dump("Callvars after", variables); end
end

                                                --[[ DIALSTRING_PRIV_MERGE_VARIABLES ]]--

function Dialstring:PRIV_merge_variables(global_variables, local_variables)

   local merged_variables = {}
   local count = 0

   -- First, overlay all the additional variables on top of the global variables.
   -- They override the existing globals of the same name...

   if self.additional_vars then
      for key,value in pairs(self.additional_vars) do
	 global_variables[key] = value
      end
   end

   -- Now overlay the global variables, skipping ones beginning with "_"
   
   for key,value in pairs(global_variables) do
      if key:byte(1) == 95 then
	 -- skip variables beginning with "_"
      else
	 merged_variables[key] = value
	 count = count + 1
      end
   end

   -- And finally, overlay the local variables.  Again, skipping those beginning
   -- with "_"

   for key,value in pairs(local_variables) do
      if key:byte(1) == 95 then
	 -- skip variables beginning with "_"
      else
	 if merged_variables[key] == nil then
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

   --
   -- Sort them so they are always presented to freeswitch in a deterministic
   -- manner. 
   --

   local sorted_variable_names = {}

   for item in pairs(merged_variables) do
      sorted_variable_names[#sorted_variable_names + 1] = item
   end

   table.sort(sorted_variable_names)

   --
   -- Now construct the comma separated variable portion of the dial string and 
   -- return it.
   --
   local merged_variable_string = "";
   local argument_count = 0;

   if count ~= 0 then
      merged_variable_string = "[";
      
      for _, key in ipairs(sorted_variable_names) do
	 local value = merged_variables[key]
	 
	 if value:find("[%s,]") ~= nil then
		value = "'"..value.."'"
	 end

	 merged_variable_string = merged_variable_string..key.."="..value
	 argument_count = argument_count + 1
	 if argument_count ~= count then
	    merged_variable_string = merged_variable_string..",";
	 end
      end
      
      merged_variable_string = merged_variable_string.."]";
   end

   return merged_variable_string
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
-- "8001" and vars.call_timeout = 60   (wait is translated into
--                                      freeswitch's call_timeout variable)

                                              --[[ DIALSTRING:PRIV_PROCESS_EXTENSION ]]--

function Dialstring:PRIV_process_extension(extension_string, global_variables)

   local parts = {};

   local default_domain = self.default_domain or ""
   local excluded_extension = self.excluded_extension or ""

   if DEBUG_DIALSTRING then
      logInfo("Processing <"..extension_string.."> excluding <"..excluded_extension
			    .."> in domain <"..default_domain..">")
   end

   -- We might be a function, so check for that first.

   local function_name, args = extension_string:match("^([A-Za-z0-9_]+)%((.+)%)$")

   if function_name then 
      if DEBUG_DIALSTRING then
	 logInfo("Found function <"..function_name.."> with args <"..args..">")
      end
      
      global_variables._FUNCTION_NAME = function_name
      global_variables._FUNCTION_ARG_COUNT = 1
      global_variables._0 = args
      return "FU";
   end

   -- If there are no "," characters in our extension string, it's
   -- either a global variable assignment or a function call...

   local multiple_parts  = extension_string:match(",")

   if not multiple_parts then 
      -- We might also be a global variable assignment

      if string.match(extension_string, "=") then
	 self:PRIV_process_variable(extension_string, global_variables);
	 return "GL";
      end
   end

   -- Ok, we're neither.  Process normally

   parts = string_split(extension_string, ",");

   local local_variables = {};
   local_variables.hangup_after_bridge = "true";

   local extension_digits = "";

   for _, part in ipairs(parts) do
      if string.match(part,"=") then
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
   if extension_digits == excluded_extension then
      return "";
   end

   --
   -- Merge the global and local variables
   --

   local merged_variable_string = self:PRIV_merge_variables(global_variables,
							    local_variables)

   -- If the extension digits have an @ or % sign in them, don't add the default domian.
   
   if default_domain ~= "" then 
      local ext, domain  = string.match(extension_digits,"^(.+)[%%@](.+)$")
      if ext == nil then
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
                                                  --[[ DIALSTRING:PRIV_PROCESS_BLOCK ]]--

function Dialstring:PRIV_process_block(block, global_variables)

   -- 1. Break the block into : separated extensions
   -- 2. Process the : separated units.

   if DEBUG_DIALSTRING then
      logInfo("Processing <"..block..">")
   end

   local extensions = {};
   local dialstring = "";
   
   extensions = string_split(block, ":");

   for _,extension_string in ipairs(extensions) do
      if DEBUG_DIALSTRING then
	 logInfo("Processing extension <"..extension_string..">")
      end

      local dialstring_part = self:PRIV_process_extension(extension_string,
							  global_variables)
      if dialstring_part ~= "" then

	 if dialstring ~= "" then
	    dialstring = dialstring..":_:";
	 end
      
	 dialstring = dialstring..dialstring_part;
      end
   end
   if DEBUG_DIALSTRING then logInfo("Returning <"..dialstring..">"); end
   return dialstring;
end


