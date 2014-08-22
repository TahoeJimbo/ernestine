
-- PSTN number parser

----------------------------------------------------
-- NANPA PARSING

-- PRIV_NANPA_parse() parses and returns the canonical representation of the
-- dialed number within the NANPA numbering plan:
--
-- The prefixes + and 011 are treated as international calls, and are stripped.
-- The prefixes +1, 1, and 0111 are treated as domestic calls, and are stripped.
-- Domestic rules (area code and prefix begin with 2-9, the rest are 0-9)
-- Domestic calls are returned as "NXXNXXXXXX" (N = 2-9, X = 0-9]
-- Local calls are returned as "NXXXXXX" (N = 2-9, X = 0-9)

-- RETURNS: (kind, canonicalized number) or (nil, nil)

                                                             --[[ NUMBER:PARSE_NANPA ]]--
function Number:parse_NANPA()

   local result

   -- Try the emergency number first.  Don't want risk coding bug
   -- masking it below.

   result = self:PRIV_NANPA_parse_emergency()
   
   if result then
      return "emergency", result
   end

   result = self:PRIV_NANPA_parse_intl()

   if result then
      return "intl", result
   end

   result = self:PRIV_NANPA_parse_domestic()

   if result then

      -- Make sure it's not a fully qualified local number...

      local possible_local_number = self:PRIV_NANPA_parse_local(result)

      if possible_local_number then 
	 return "local", possible_local_number
      end

      return "domestic", result
   end

   result = self:PRIV_NANPA_parse_local()

   if result then
      return "local", result
   end

   result = self:PRIV_NANPA_parse_service()

   if result then
      return "service", result
   end

   -- logError(self.raw_number.." is not a NANPA formatted number.")
   return nil, nil
end

-- %r      Raw digits, unaltered
-- %c      Canonical parsed number, (countrycode + number)
-- %l      Local part (minus country and city code)
-- %a      Area/city code
                                                            --[[ NUMBER:FORMAT_NANPA ]]--
function Number:format_NANPA(fs)

   if fs == nil or #fs < 2 then
      logError("Improper format string.")
      return nil
   end

   local area_code = nil
   local local_part = nil

   local output = ""

   if self.kind == "local" or self.kind == "domestic" then
      if #self.canonical_number == 7 then
	 area_code = self.local_code
	 local_part = self.canonical_number
      else
	 area_code, local_part
	    = self.canonical_number:match("^(%d%d%d)(%d%d%d%d%d%d%d)$")
      end
   end
   
   local flength = #fs
   local fpos = 1

   while fpos <= flength do
      x = fs:sub(fpos,fpos)
      
      if x == "%" then
	 local expansion = self:PRIV_NANPA_process_percent(fs, fpos, flength)
	 if expansion == nil then return nil; end

	 output = output..expansion
	 fpos = fpos + 1
      else
	 output = output..x
      end

      fpos = fpos + 1
   end

   return output
end
                                              --[[ NUMBER:PRIV_NANPA_PROCESS_PERCENT ]]--

function Number:PRIV_NANPA_process_percent(fs, fpos, flength)
   fpos = fpos + 1
   
   if fpos > flength then
      logError("Percent escape is missing valid code at position "..fpos)
      return nil
   end

   local escape = fs:sub(fpos, fpos)

   if escape == "%" then
      return "%"
   end

   if escape == "r" then
      return self.raw_number
   end

   if escape == "c" then
      return self.canonical_number
   end

   if escape == "l" then
      if self.kind == "domestic" or self.kind == "local" then
	 return self.canonical_number:match("^1%d%d%d(%d%d%d%d%d%d%d)$")
      end
      
      if self.kind == "service" or self.kind == "emergency" then
	 return self.canonical_number
      end

      logError("%l escape cannot be used on international number <"
		  ..self.raw_number..">.")
      return nil;
   end

   if escape == "a" then
      if self.kind == "domestic" or self.kind == "local" then
	 return self.canonical_number:match("^1(%d%d%d)%d%d%d%d%d%d%d$")
      end

      logError("%a escape cannot only be used on local or domestic numbers, not on <"
		  ..self.kind..">, <"..self.raw_number..">")
      return nil
   end
end
                                                   --[[ NUMBER:PRIV_NANPA_PARSE_INTL ]]--
function Number:PRIV_NANPA_parse_intl()

   local international_number = nil

   --
   -- 1 is the NANPA country code so reject "international" numbers using it.
   -- The "domestic" parser will deal with it.
   --

   if string.match(self.raw_number, "^+1") or 
      string.match(self.raw_number, "^1") or
      string.match(self.raw_number, "^0111") then
	 return nil
   end

   international_number = string.match(self.raw_number, "^%+(%d+)")

   if international_number then
      if DEBUG_NUMBER then
	 logInfo("Returning international number <"..international_number..">")
      end
      return international_number;
   end

   international_number = string.match(self.raw_number, "^011(%d+)")

   if international_number then
      if DEBUG_NUMBER then 
	 logInfo("Returning international number <"..international_number..">")
      end
      return international_number;
   end

   return nil;
end

--
-- Technically, domestic prefixes (NXX) cannot end in 11, but only for
-- *geographic* area codes.  We don't bother trying to make this distinction.
-- The number should be "good enough" and we'll let the remote end sort out
-- possible issues.
--
                                               --[[ NUMBER:PRIV_NANPA_PARSE_DOMESTIC ]]--
function Number:PRIV_NANPA_parse_domestic()

   local domestic_number

   domestic_number = string.match(self.raw_number, "^(1[2-9]%d%d[2-9]%d%d%d%d%d%d)$")

   if domestic_number then
      if DEBUG_NUMBER then
	 logInfo("Returning domestic number <"..domestic_number..">")
      end
      return domestic_number
   end

   domestic_number = string.match(self.raw_number, "^%+(1[2-9]%d%d[2-9]%d%d%d%d%d%d)$")

   if domestic_number then
      if DEBUG_NUMBER then 
	 logInfo("Returning domestic number <"..domestic_number..">")
      end
      return domestic_number
   end

   domestic_number = string.match(self.raw_number, "^011(1[2-9]%d%d[2-9]%d%d%d%d%d%d)$")

   if domestic_number then
      if DEBUG_NUMBER then
	 logInfo("Returning domestic number <"..domestic_number..">")
      end
      return domestic_number
   end

   return nil
end
                                                  --[[ NUMBER:PRIV_NANPA_PARSE_LOCAL ]]--

function Number:PRIV_NANPA_parse_local(domestic_number)

   local area_code = nil
   local local_number = nil

   if domestic_number then
      --
      -- Break down the number into the area and local parts
      --
      area_code, local_number = string.match(domestic_number, "^1([2-9]%d%d)([2-9]%d%d%d%d%d%d)$")

      if area_code == self.local_code then
	 if DEBUG_NUMBER then
	    logInfo("Returning local number <"..domestic_number..">")
	 end
	 return domestic_number
      end

      return nil
   end

   local_number = string.match(self.raw_number, "^([2-9]%d%d%d%d%d%d)$")

   if local_number then
      local_number = "1"..self.local_code..local_number
      if DEBUG_NUMBER then
	 logInfo("Returning local number <"..local_number..">")
      end
      return local_number
   end
      
   return nil
end
                                                --[[ NUMBER:PRIV_NANPA_PARSE_SERVICE ]]--
function Number:PRIV_NANPA_parse_service()

   local service_number = nil

   service_number = string.match(self.raw_number, "^[2-8]11$")

   if service_number then
      if DEBUG_NUMBER then 
	 logInfo("Returning service number <"..service_number..">")
      end
      return service_number
   end

   return nil
end
                                              --[[ NUMBER:PRIV_NANPA_PARSE_EMERGENCY ]]--
function Number:PRIV_NANPA_parse_emergency()

   local emergency_number = nil
   
   if self.raw_number == "911" then
      if DEBUG_NUMBER then
	 logInfo("Returning emergency number <911>")
      end
      return "911"
   end

   return nil
end


