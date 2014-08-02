

Destination = {}

--[[

Fields:

private:
custom_dialstring = our specially formatted dialstring to use
freeswitch_dialstring = a freeswitch dialstring to use
outgoing_caller_id_number  -> origination_caller_id_name
outgoing_caller_id_name


--]]

function Destination:new()
   object = {}
   setmetatable(object, self)
   self.__index = self

   self.source_caller_id_name = nil
   self.source_caller_id_number = nil

   self.kind = ""
   self.domain = ""

   return object
end

function Destination:set_source_caller_id(name, number)
   self.source_caller_id_name = name
   self.source_caller_id_number = number
end

function Destination:set_excluded_extension(extension_digits)
   self.excluded_extension = extension_digits
end

function Destination:set_default_domain(domain)
   self.domain = domain
end

-- 
-- Parses a custom dialstring, storing the result for later use.
-- If custom options are enabled (like caller id) these settings are
-- incorporated into the dialstring.
--

function Destination:set_custom_dialstring(custom_dialstring)
   self.dialstring = Dialstring:new_custom(custom_dialstring)
   self.kind = "custom"
end

-- Sets the dialstring to the raw dialstring provided.  Nothing is done
-- to it.

function Destination:set_freeswitch_dialstring(freeswitch_dialstring)
   self.dialstring = Dialstring:new_freeswitch(freeswitch_dialstring)
   self.kind = "freeswitch"
end

-- Parses a sofia dialstring and creats a freeswitch dialstring from
-- it, including any custom options (like caller id).

function Destination:set_sofia_dialstring(sofia_dialstring)
   self.dialstring = Dialstring:new_sofia(sofia_dialstring)
   self.kind = "sofia"
end


-- Connect to the destination, returning (status, message)
--
-- One of the dialstring set functions must be called before this.
--
-- Returns a tuple of (result (String), reason (String))
--
--  "FAILED",     reason       The origination failed for the given reason
--  "COMPLETED",   message     The call was answered and ended normally
--  "BUSY",       reason       The subscriber is using their phone or is otherwise engaged
--  "NO ANSWER",  reason       The call was not answered in the time provided

function Destination:connect(source_session)
   
   self.dialstring:set_excluded_extension(self.excluded_extension)

   if (self.source_caller_id_name) then
      self.dialstring:set_variable("origination_caller_id_name", self.source_caller_id_name)
   end

   if (self.source_caller_id_number) then
      self.dialstring:set_variable("origination_caller_id_number", self.source_caller_id_number)
   end
   
   if (self.domain and self.domain ~= "") then
      self.dialstring:set_default_domain(self.domain)
   end

   if self.kind == "custom" then
      return self:PRIV_connect_custom_style(source_session)
   end

   if self.kind == "freeswitch" then
      return self:PRIV_connect_freeswitch_style(source_session)
   end

   if self.kind == "sofia" then
      return self:PRIV_connect_freeswitch_style(source_session)
   end
end


-- Attempt to ring a dial-string until it is answered or not. :-)
--
-- Returns a tuple of (session (FreeSwitch session), result (String), reason (String))
--
--     nil, "FAILED",     reason       The origination failed for the given reason
-- session, "ANSWERED",   message      The call was answered
--     nil, "BUSY",       reason       The subscriber is using their phone or is otherwise engaged
--     nil, "NO ANSWER",  reason       The call was not answered in the time provided

function Destination:PRIV_make_and_ring_endpoint(dialstring_obj)

   local result
   local message

   local hangupState
   local disposition
   
   local dialstring = dialstring_obj.get()

   if DEBUG then logInfo("Calling "..dialstring); end

   local leg = freeswitch.Session(dialstring)

   -- We don't get this far until something difinitive happens with the
   -- session.

   --
   -- Freeswitch as a bunch of different state variables, so we
   -- examine a few of them to be exact in our conclusion.
   --

   hangupState = leg:hangupCause()
   disposition = leg:getVariable("endpoint_disposition")

   if DEBUG then logInfo("Received hangup state: "..hangupState.." and disposition "..disposition); end

   if hangupState == "SUCCESS" and (disposition == "ANSWER" or disposition == "EARLY MEDIA") then 
      result = "ANSWERED"
      message = "The call was answered."
      return leg, result, message
   end

   if hangupState == "NO ANSWER" or hangupState == "NO_USER_RESPONSE" then
      result = "NO ANSWER"
      message = "The call was not answered."
      goto failed
   end

   if hangupState == "USER_BUSY" then
      result = "USER BUSY"
      message = "The subscriber is busy."
      goto failed
   end

   if hangupState == "NORMAL_CLEARING" then
      result = "FAILED"
      message = "Call cleared normally, when it should have been something else."
      goto failed
   end

   result = "FAILED"
   message = "Failed for reason ["..hangupState.."]."

   ::failed::
   if DEBUG then logError(result..": "..message); end
   return nil, result, message
end

-- 
-- dialplan.connect_freeswitch_style(source_session)
--
-- Attempts to call the freeswitch_dialstring and connects it to the
-- source_session if successful.
--
-- NOTE: As the name implies, this call expects a dialstring in the FreeSWITCH
--       format.  NOT our custom format.
--
-- Returns a tuple of (result, reason), both are strings.
--
-- "COMPLETED", message
-- "NO ANSWER", message
-- "BUSY",      message
-- "FAILED",    reason

function Destination:PRIV_connect_freeswitch_style(source_session, alternate_dialstring)

   local aLeg = source_session;

   local freeswitch_dialstring = alternate_dialstring or self.dialstring:get()

   -- Make sure our a-leg is still alive...

   local aLegState = aLeg:getState();

   if (aLeg:ready() == false) then
      logInfo("dialplan.connect: A-Leg not prepared for connection: "..aLegState);
      return "FAILED", "Source session is not ready."
   end

   -- Create the b-leg and attempt a connection...  The make_and_ring
   -- call will not return until something difinitive happens.

   local bLeg, status, message = dialplan.make_and_ring_endpoint(freeswitch_dialstring)

   if (bLeg == nil) then
      return status, message
   end

   -- Ok, the b-leg is connected!  Make sure the aLeg is still around

   if (aLeg:ready() == false) then
      aLegState = aLeg:hangupCause()
      logInfo("dialplan.connect: A leg disappeared: "..aLegState)
      return "FAILED", "Source session disappeared while destination was connecting."
   end
      
   -- Both legs are still alive here.

   freeswitch.bridge(aLeg, bLeg)

   hangupCause = bLeg:hangupCause()
   bLeg:destroy()
   aLeg:hangup()

   if DEBUG then logInfo("bLeg hangup cause: ["..hangupCause.."]"); end

   return "COMPLETED", "The call completed normally."
end

-- dialplan.connect_custom(source_session)
-- 
-- Attempts to connect the source session with one of the endpoints in our
-- custom dialstring.  If exclude_extension is not empty (or nil) of the
-- the extension to be excluded is part of the custom_dialstring, it will
-- be excluded when connecting.  (This is usually used to ensure that if
-- the calling party's extension is in the dialstring, they won't be
-- called.
-- 
-- Returns a tuple of (result, reason), both are strings.
-- 
-- "COMPLETED", message  
-- "NO ANSWER", message
-- "BUSY",      message
-- "FAILED",    reason
-- "TRY VOICEMAIL", extension
--

function Destination:PRIV_connect_custom_style(source_session)
   
   local results = {}

   results = self.dialstring:get()

   if DEBUG then logInfo("Starting custom connection to <"..self.dialstring:description()..">"); end

   if (results == nil) then
      return FAILED, "No destinations could be found for the custom dialstring <"..self.dialstring:description()..">"
   end

   local last_result
   local last_reason

   for _, result_item in ipairs(results) do

      local kind = result_item.kind
      local dialstring = result_item.dialstring

      if (kind == "FU_VM") then
	 -- VOICEMAIL!
	 
	 if DEBUG then logInfo("Returning TRY_VOICEMAIL"); end
	 return "TRY VOICEMAIL", dialstring

      elseif (dialstring == "") then
	 if DEBUG then logError("Returning FAILED: Internal Error"); end
	 return "FAILED", "Internal error.  Received an empty dialstring after parsing."
      else
	 --
	 -- Try to connect the call to this dialstring
	 --
	 local result, message = self:PRIV_connect_freeswitch_style(source_session, dialstring)

	 if result == "COMPLETED" then
	    -- YAY!  DONE!
	    if DEBUG then logInfo("Returning COMPLETED"); end
	    return "COMPLETED", "The call was connected and completed normally."
	 end

	 last_result = result
	 last_reason = message
	 --
	 -- Not done.  Continue with the next one.
	 --
      end
   end
   
   --
   -- HMM. Got all the way to the end without completing...
   --
   if (last_result and last_reason) then
      if DEBUG then logError("Returning "..last_result..": "..last_reason); end
      return last_result, last_reason
   end

   if DEBUG then logError("Returning FAILED: Unknown Error"); end

   return "FAILED", "Unknown failure. No additional data can be provided."
end
