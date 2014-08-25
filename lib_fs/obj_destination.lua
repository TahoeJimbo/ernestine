
Destination = {}

--[[
   A destination is an endpoint for a call.

   Given a dialstring (freeswitch, sofia, or our custom string) attempt to
   complete the call to the dialstring, then bridge the source leg to the 
   destination leg.

--]]

                                                                --[[ DESTINATION:NEW ]]--
function Destination:new()
   local object = {}
   setmetatable(object, self)
   self.__index = self

   object.source_caller_id_name = nil
   object.source_caller_id_number = nil

   object.kind = ""
   object.domain = ""

   return object
end
                                               --[[ DESTINATION:SET_SOURCE_CALLER_ID ]]--
function Destination:set_source_caller_id(name, number)
   self.source_caller_id_name = name
   self.source_caller_id_number = number
end

                                             --[[ DESTINATION:SET_EXCLUDED_EXTENSION ]]--
function Destination:set_excluded_extension(extension_digits)
   self.excluded_extension = extension_digits
end

                                                 --[[ DESTINATION:SET_DEFAULT_DOMAIN ]]--
function Destination:set_default_domain(domain)
   self.domain = domain
end

-- 
-- Parses a custom dialstring, storing the result for later use.
-- If custom options are enabled (like caller id) these settings are
-- incorporated into the dialstring.
--
                                              --[[ DESTINATION:SET_CUSTOM_DIALSTRING ]]--

function Destination:set_custom_dialstring(custom_dialstring)
   self.dialstring = Dialstring:new_custom(custom_dialstring)
   self.kind = "custom"
end

-- Sets the dialstring to the raw dialstring provided.  Nothing is done
-- to it.
                                          --[[ DESTINATION:SET_FREESWITCH_DIALSTRING ]]--

function Destination:set_freeswitch_dialstring(freeswitch_dialstring)
   self.dialstring = Dialstring:new_freeswitch(freeswitch_dialstring)
   self.kind = "freeswitch"
end

-- Parses a sofia dialstring and creats a freeswitch dialstring from
-- it, including any custom options (like caller id).

                                               --[[ DESTINATION:SET_SOFIA_DIALSTRING ]]--

function Destination:set_sofia_dialstring(sofia_dialstring)
   self.dialstring = Dialstring:new_sofia(sofia_dialstring)
   self.kind = "sofia"
end

-----------------------------------------------------------------------------------------
-- Connect to the destination, returning (status, message)
--
-- One of the dialstring set functions must be called before calling this function.
--
-- Returns a tuple of (result (String), reason (String))
--
--  "FAILED",     reason    The origination failed for the given reason
--  "COMPLETED",  message   The call was answered and ended normally
--  "BUSY",       reason    The subscriber is using their phone or is otherwise engaged
--  "NO ANSWER",  reason    The call was not answered in the time provided

                                                            --[[ DESTINATION:CONNECT ]]--
function Destination:connect(source_session)
   
   self.dialstring:set_excluded_extension(self.excluded_extension)

   if self.source_caller_id_name then
      self.dialstring:set_variable("origination_caller_id_name",
				   self.source_caller_id_name)
   end

   if self.source_caller_id_number then
      self.dialstring:set_variable("origination_caller_id_number",
				   self.source_caller_id_number)
   end
   
   if self.domain and self.domain ~= "" then
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

                                                        --[[ DESTINATION:DESCRIPTION ]]--
function Destination:description()

   local d_kind = self.kind or "[?]"
   local d_ds

   if self.dialstring then
      d_ds = self.dialstring:description()
   else
      d_ds = "[?]"
   end

   return d_kind.." destination: "..d_ds
end

----------PRIVATE------------------------------------------------------------------------

-- Attempt to ring a dial-string until it is answered or not. :-)
--
-- Returns a tuple of (session (FreeSwitch session), result (String), reason (String))
--
--     nil, "FAILED",     reason    The origination failed for the given reason
-- session, "ANSWERED",   message   The call was answered
--     nil, "BUSY",       reason    The subscriber is using their phone or is
--                                  otherwise engaged
--     nil, "NO ANSWER",  reason    The call was not answered in the time provided

                                        --[[ DESTINATION:PRIV_MAKE_AND_RING_ENDPOINT ]]--

function Destination:PRIV_make_and_ring_endpoint(aLeg, dialstring)

   local result
   local message

   local hangupState
   local disposition
   
   if DEBUG_DESTINATION then logInfo("Calling "..dialstring); end

   local leg = freeswitch.Session(dialstring, aLeg)

   -- We don't get this far until something difinitive happens with the
   -- session.

   --
   -- Freeswitch as a bunch of different state variables, so we
   -- examine a few of them to be exact in our conclusion.
   --

   hangupState = leg:hangupCause()
   disposition = leg:getVariable("endpoint_disposition")

   if DEBUG_DESTINATION then logInfo("Received hangup state: "..hangupState
				     .." and disposition "..disposition); end
   if hangupState == "SUCCESS"
      and (disposition == "ANSWER" or disposition == "EARLY MEDIA") then 

      result = "ANSWERED"
      message = "The call was answered."
      if DEBUG_DESTINATION then logInfo(result..": "..message); end
      return leg, result, message
   end

   if hangupState == "NO ANSWER" or hangupState == "NO_USER_RESPONSE" then
      result = "NO ANSWER"
      message = "The call was not answered."
      if DEBUG_DESTINATION then logInfo(result..": "..message); end
      return nil, result, message
   end

   if hangupState == "USER_BUSY" then
      result = "USER BUSY"
      message = "The subscriber is busy."
      if DEBUG_DESTINATION then logInfo(result..": "..message); end
      return nil, result, message
   end

   if hangupState == "NORMAL_CLEARING" then
      result = "FAILED"
      message = "Call cleared normally, when it should have been something else."
      logError(result..": "..message)
      return nil, result, message
   end

   result = "FAILED"
   message = "Failed for reason ["..hangupState.."]."

   logError(result..": "..message)
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

                                      --[[ DESTINATION:PRIV_CONNECT_FREESWITCH_STYLE ]]--

function Destination:PRIV_connect_freeswitch_style(source_session, alternate_dialstring)

   local aLeg = source_session;

   local freeswitch_dialstring = alternate_dialstring or self.dialstring:get()

   -- Make sure our a-leg is still alive...

   local aLegState = aLeg:getState();

   if aLeg:ready() == false then
      logInfo("dialplan.connect: A-Leg not prepared for connection: "..aLegState);
      return "FAILED", "Source session is not ready."
   end

   aLeg:setVariable("continue_on_fail", "true")

   -- Create the b-leg and attempt a connection...  The make_and_ring
   -- call will not return until something difinitive happens.

   local bLeg, status, message = self:PRIV_make_and_ring_endpoint(aLeg,
								  freeswitch_dialstring)

   if bLeg == nil then
      return status, message
   end

   -- Ok, the b-leg is connected!  Make sure the aLeg is still around

   if aLeg:ready() == false then
      aLegState = aLeg:hangupCause()
      logInfo("dialplan.connect: A leg disappeared: "..aLegState)
      return "FAILED", "Source session disappeared while destination was connecting."
   end

   -- Both legs are still alive here.

   freeswitch.bridge(aLeg, bLeg)
   hangupCause = bLeg:hangupCause()
   bLeg:destroy()
   aLeg:hangup()

   if DEBUG_DESTINATION then logInfo("bLeg hangup cause: ["..hangupCause.."]"); end

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
                                          --[[ DESTINATION:PRIV_CONNECT_CUSTOM_STYLE ]]--

function Destination:PRIV_connect_custom_style(source_session)
   
   local results = {}

   results = self.dialstring:get()

   if DEBUG_DESTINATION then logInfo("Starting custom connection to <"
			 ..self.dialstring:description()..">"); end

   if results == nil then
      return "FAILED", "No destinations could be found for the custom dialstring <"
	               ..self.dialstring:description()..">"
   end

   local last_result
   local last_reason

   for _, result_item in ipairs(results) do
      
      local kind = result_item.kind
      local dialstring = result_item.dialstring

      --
      -- Do we still have a source leg?  Bail if not.
      --

      if source_session:ready() ~= true then
	 --
	 -- Source bailed.  We're done!
	 --
	 return "FAILED", "Source leg of the call disappeared."
      end

      if DEBUG_DESTINATION then
	 logInfo("Evaluating <"..kind.."> with args <"..dialstring..">")
      end

      if kind == "FU_VM" then
	 -- VOICEMAIL!
	 
	 if DEBUG_DESTINATION then logInfo("Returning TRY_VOICEMAIL"); end
	 return "TRY VOICEMAIL", dialstring

      elseif kind == "FU_IF_LOC" then
	 -- LOCATION AWARENESS
	 local redirect = Destination:PRIV_is_at_location(dialstring)

	 if redirect then
	    if DEBUG_DESTINATION then logInfo("Redirecting to <"..redirect..">"); end
	    return "REDIRECT", redirect
	 else
	    if DEBUG_DESTINATION then logInfo("...no match. Continuing."); end
	 end

      elseif kind == "FU_IF_TIME" then
	 -- TIME OF DAY CHECK
	 local redirect = Destination:PRIV_is_in_timeframe(dialstring)

	 if redirect then
	    if DEBUG_DESTINATION then logInfo("Redirecting to <"..redirect..">"); end
	    return "REDIRECT", redirect
	 else
	    if DEBUG_DESTINATION then logInfo("...not in time range. Continuing."); end
	 end

      elseif kind == "FU_GOTO" then
	 if DEBUG_DESTINATION then logInfo("Redirecting to <"..dialstring..">"); end
	 return "REDIRECT", dialstring

      elseif dialstring == "" then
	 if DEBUG_DESTINATION then logError("Returning FAILED: Internal Error"); end
	 return "FAILED", "Internal error.  Received an empty dialstring after parsing."
      else
	 --
	 -- Try to connect the call to this dialstring
	 --
	 if DEBUG_DESTINATION then
	    logError("Trying to connect to <"..dialstring..">")
	 end

	 local result, message = self:PRIV_connect_freeswitch_style(source_session,
								    dialstring)

	 if result == "COMPLETED" then
	    -- YAY!  DONE!
	    if DEBUG_DESTINATION then logInfo("Returning COMPLETED"); end
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
   if last_result and last_reason then
      if DEBUG_DESTINATION then logError("Returning "..last_result..
					 ": "..last_reason); end
      return last_result, last_reason
   end

   if DEBUG_DESTINATION then logError("Returning FAILED: Unknown Error"); end

   return "FAILED", "Unknown failure. No additional data can be provided."
end

                                          --[[ DESTINATION:PRIV_IS_IN_TIMEFRAME ]]--

function Destination:PRIV_is_in_timeframe(args_string)

   -- 
   -- Parse the arguments
   --

   if DEBUG_DESTINATION then logInfo("Arguments: <"..args_string..">"); end

   args = string_split(args_string, ",")
   if #args ~= 3 then return "FAILED"; end

   --
   -- Get the current local time...
   --

   local localtime_parts = os.date("*t", os.time())
   
   local hours = localtime_parts.hour
   local minutes = localtime_parts.min
   local current_time = (hours * 100) + minutes

   local start_time = args[1] + 0
   local end_time = args[2] + 0

   if end_time < start_time then
      if current_time > start_time then
	 return args[3]
      end

      if current_time < end_time then
	 return args[3]
      end
   else
      if current_time > start_time and current_time < end_time then 
	 return args[3]
      end
   end

   return nil
end

                                          --[[ DESTINATION:PRIV_IS_AT_LOCATION ]]--

function Destination:PRIV_is_at_location(args_string)

   --
   -- Parse the arguments
   --

   args = string_split(args_string, ",")
   if #args ~= 3 then return "FAILED"; end

   local vm_box = args[1]
   local location = args[2]

   local location_obj = gLocations:get(vm_box)

   if location_obj then
      if location == location_obj.get_id() then
	 return args[3]
      end
   end

   return nil
end
