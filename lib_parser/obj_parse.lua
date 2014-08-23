
Parser = {}

local kParseStateWantGroup        = 1    -- or EOF
local kParseStateWantOpenBrace    = 2
local kParseStateWantKeyword      = 3    -- or "}", or "+"
local kParseStateWantEqual        = 4
local kParseStateWantQuotedString = 5


function Parser:new(file_name, parser_config)

   if file_name == nil or parser_config == nil then
      logError("Invalid argument")
      return nil
   end

   local object = {}
   setmetatable(object, self)
   self.__index = self

   object.current_group_name = nil       -- Name of group being parsed.
   object.current_group_keyword = nil    -- Name of current keyword being parsed
   object.current_group_pairs = nil      -- The keyword pairs being built for current 
                                         -- group

   object.current_group_index = nil      -- Keyword lookup table for current group

   object.current_file_name = nil
   object.current_line = 0

   object.config_array = {}

   object.parse_grammar = parser_config
   object.parse_index = nil
   
   local error_msg = object:load_file(file_name)

   if (error_msg) then 
      return nil, error_msg
   end

   return object, nil
end


function Parser:PRIV_index_grammar()

   self.parse_index = {}
   
   for _, conf_entry in ipairs(self.parse_grammar) do
      local group_name = conf_entry.group_name
      local group_table = {}

      for _, keyword in ipairs(conf_entry.keywords) do
	 group_table[keyword] = 1
      end

      self.parse_index[group_name] = group_table
   end
end


function parse_true_false(token)

   if token == nil then return nil; end

   if type(token) == "boolean" then return token; end

   local token = token:upper()

   if token == "YES" or token == "TRUE" or token == "1" then
      return true
   end

   if token == "NO" or token == "FALSE" or token == "0" then
      return false
   end

   return nil
end


--
-- Load the file and lightly parse the basic structure, ensuring balanced
-- braces, and quotes, storing each group's configration statements 
-- as a table of keyword/value pairs.
--

function Parser:load_file(file_name)

   self.current_file_name = file_name
   self.current_line = 0

   self:PRIV_index_grammar()
   
   local file, error_msg = io.open(file_name, "r")
   
   if file == nil then
      logError("File <"..file_name..">: "..error_msg)
      return nil
   end

   -- read each line, looking for a "XXXX { blah }" pattern

   local parse_state = kParseStateWantGroup

   for line in file:lines() do
      self.current_line = self.current_line + 1
      repeat
	 token, line = PRIV_next_token(line)

	 if token then
	    if token ~= "#" then
	       if DEBUG_PARSE then 
		  logInfo("TOKEN: <"..token.."> in state: "..parse_state)
	       end

	       local error_message = nil

	       if parse_state == kParseStateWantGroup then
		  parse_state, error_message = self:expecting_group(token)
	       elseif parse_state == kParseStateWantOpenBrace then
		  parse_state, error_message = self:expecting_open_brace(token)
	       elseif parse_state == kParseStateWantKeyword then
		  parse_state, error_message = self:expecting_keyword(token)
	       elseif parse_state == kParseStateWantEqual then
		  parse_state, error_message = self:expecting_equal(token)
	       elseif parse_state == kParseStateWantQuotedString then
		  parse_state, error_message = self:expecting_quoted_string(token)
	       end

	       if error_message then
		  self:error_message(error_message)
		  file:close()
		  return error_message
	       end
	    end
	 else 
	    if line ~= nil then
	       self:error_message(line)
	       file:close()
	       return line
	    end
	 end
      until token == nil
   end
   file:close()
end

function Parser:error_message(message)
   logError(self.current_file_name..":"..self.current_line..": "..message)
end

function Parser:expecting_group(token)
   -- see if the token is in our configured list of possible groups

   self.current_group_index = self.parse_index[token]

   if (self.current_group_index == nil) then
      return nil, "Unknown group name: \""..token.."\""
   end

   self.current_group_name = token
   self.current_group_pairs = {}

   return kParseStateWantOpenBrace, nil
end

function Parser:expecting_open_brace(token)
   
   if token == "{" then 
      return kParseStateWantKeyword, nil
   end

   return nil, "Expecting \"{\" after the \""..self.current_group_name.."\" group name."
end

function Parser:expecting_keyword(token)

   -- If we get a "}" then we should close the current group

   if token == "}" then
      -- Close out the group...

      local config_entry = {}
      config_entry.group_name = self.current_group_name
      config_entry.items = self.current_group_pairs


      self.config_array[#self.config_array + 1] = config_entry

      self.current_group_name = nil
      self.current_group_pairs = nil
      self.current_group_index = nil
      self.current_group_pairs = nil

      return kParseStateWantGroup, nil
   end

   -- If we get a "+" we should go back to expecting a quoted
   -- string, and append it to the current group's keyword
   if token == "+" and self.current_group_keyword then
      return kParseStateWantQuotedString, nil
   end

   -- See if our token is an allowed keyword for the current group...

   if self.current_group_index[token] ~= nil then
      self.current_group_keyword = token
      self.current_group_index[token] = ""
      return kParseStateWantEqual, nil
   end

   return nil, "\""..token.."\" is not a valid keyword for the \""
                   ..self.current_group_name.."\" group."
end

function Parser:expecting_equal(token)

   if token == "=" then
      return kParseStateWantQuotedString, nil
   end

   return nil, "Expecting \"=\" after the \""..self.current_group_keyword.."\" keyword."
end

function Parser:expecting_quoted_string(token)

   if token:sub(1,1) ~= "\"" then
      return nil, "Expected a quoted string after the \"=\" sign."
   end

   -- install the string in the keyword.

   local unquoted_string = token:sub(2, #token - 1)

   local current_pair_value = self.current_group_pairs[self.current_group_keyword] or ""
   current_pair_value = current_pair_value..unquoted_string
   self.current_group_pairs[self.current_group_keyword] = current_pair_value

   return kParseStateWantKeyword, nil
end

function PRIV_next_token(line)

   if line == nil then return nil, nil; end
   if #line == 0 then return nil, nil; end

   -- consume leading whitespace

   if line:match("^%s*$") then return nil, nil; end
   
   rest = line:match("^[\t ]*(.*)$")

   if rest == nil then
      return nil, nil
   else 
      line = rest
   end

   -- tokens are "{" and "}", [a-zA-z_], "=", and quoted strings.

   -- get the easy stuff out of the way...

   local first_char = line:sub(1,1)

   if first_char == "#" then
      -- a comment...  Consume the rest of the line
      return "#", ""
   end

   if first_char == "{" or first_char == "}"
      or first_char == "=" or first_char == "+" then

      line = line:sub(2,#line)
      return first_char, line
   end

   if first_char == "\"" then
      -- Quoted string!
      
      local qs, rest = line:match("^(\".-\")(.*)$")

      if qs ~= nil then
	 return qs, rest
      else
	 return nil, "Unbalanced quotation marks, starting at "..line
      end
   end

   -- Anything else is a variable.

   local var, rest = line:match("^([0-9a-zA-Z_]+)%s*(.*)$")

   if var ~= nil then
      return var, rest
   end

   return nil, "Invalid configuration keyword: \""..line.."\""
end
