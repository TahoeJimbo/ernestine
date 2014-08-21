
-- PSTN number parser

Number = {}

g_number_kinds = { "intl", "domestic", "local", "special", "emergency" }

--[[

PROPERTIES:

   plan          = numbering plan name, e.g. "NANPA"
   local_code    = local area code, which is used to distinguish between local and
                   domestic numbers
   raw_number    = the raw dialed digits

   kind          = the detected number kind "intl", "domestic", "local", "service"
                   or "emergency"

   canonical_number = The dialed number, stripped of all prefix indicators (+, 0,
                      011, etc.) consisting of the country code and number, or the 
                      special service/emergency number digits.
--]]

                                                                     --[[ NUMBER:NEW ]]--
function Number:new(numbering_plan, local_code, number)

   if numbering_plan == nil or local_code == nil or number == nil
                            or #numbering_plan == 0 or #number == 0 then

      logError("Invalid arguments.")
      return nil
   end

   local object = {}
   setmetatable(object, self)
   self.__index = self

   object.plan = numbering_plan
   object.local_code = local_code
   object.raw_number = number
   
   object.kind = nil
   object.canonical_number = nil

   object:PRIV_parse()

   if object.kind == nil then
      return nil
   end

   return object
end

                                                                  --[[ NUMBER:FORMAT ]]--
function Number:format(format_string)

   if self.plan == "NANPA" then
      return self:format_NANPA(format_string)
   end

   -- We should never get here.  The object can't be created
   -- if the numbering plan is invalid.

   error("Internal Error")
end

                                                             --[[ NUMBER:DESCRIPTION ]]--
function Number:description()
   
   local d_plan = self.plan or "[?]"
   local d_raw_number = self.raw_number or "[?]"
   local d_kind = self.kind or "[?]"

   return d_plan.." "..d_raw_number.." ("..d_kind..")"
end


----------PRIVATE------------------------------------------------------------------------

                                                              --[[ NUMBER:PRIV_PARSE ]]--
function Number:PRIV_parse()

   if self.plan == "NANPA" then
      self.kind, self.canonical_number = self:parse_NANPA()
   else
      logError("Numbering plan <"..self.plan.."> is not supported.")
      return nil
   end

   if self.kind == nil then
      logError("<"..self.raw_number.."> in <"..self.plan.."> appears to be invalid.")
      return nil
   end
end

