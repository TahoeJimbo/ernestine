
-----DIALPLAN UTILITIES--------------------------------------------------------

---------PARSER

-- These routines are used to process custom "dial strings" that
-- allow serial, parallel and "function" calling.
--

dialplan = {};

-- dialplan.parse(extension_object, exclude_extension_digits) --> {table of dialstrings}
--
--    DIALSTRING FORMAT:
--
--    Dialstring format = {extensions list}|{extensions list}
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

function dialplan.parse(extension, excluded_extension)

   local results = {}

   local dialstring = extension.dialstring
   local default_domain = extension.domain

   excluded_extension = excluded_extension or ""

   if DEBUG then logInfo("Parsing <"..dialstring..">, excluding <"..excluded_extension..">"); end

   local continueBlock;
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

      dialstring = dialplan_private.process_block(continueBlock, global_variables,
					 	  excluded_extension, default_domain);
      if (dialstring == "") then
	 logError("Returning nil.");
	 return nil
      end

      if (dialstring == "GL") then
	 goto continue
      end

      if (dialstring == "FU") then
	 if (global_variables._FUNCTION_NAME == "VM") then
	    local result = {}
	    local extension = global_variables._0

	    result.kind = "FU_VM"
	    result.dialstring = extension

	    if DEBUG then logInfo("Voicemil Extension "..extension); end
	    global_variables._FUNCTION_NAME = nil

	    table_append(results, result)
	    goto continue
	 end

	 logError("Unknown function: "..global_variables._FUNCTION_NAME);
	 goto continue
      end
     
      local result = {}
      result.kind = "DS"
      result.dialstring = dialstring
      table_append(results, result)

      ::continue::
   end
   
   if (#results == 0) then
      if (dialstring == "") then
	 logError("No results. Returning nil.");
	 return nil
      end
   end

   if DEBUG then table_dump("Dialstring table", results); end

   return results;
end

-- Attempt to ring a dial-string until it is answered or not. :-)
--
-- Returns a tuple of (session (FreeSwitch session), result (String), reason (String))
--
--     nil, "FAILED",     reason       The origination failed for the given reason
-- session, "ANSWERED",   message      The call was answered
--     nil, "BUSY",       reason       The subscriber is using their phone or is otherwise engaged
--     nil, "NO ANSWER",  reason       The call was not answered in the time provided

function dialplan.make_and_ring_endpoint(dial_string)

   local result
   local message

   local hangupState
   local disposition

   if DEBUG then logInfo("Calling "..dial_string); end

   local leg = freeswitch.Session(dial_string)

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
-- dialplan.connect_freeswitch_style(source_session, freeswitch_dialstring)
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

function dialplan.connect_freeswitch_style(source_session, freeswitch_dialstring)

   local aLeg = source_session;

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

-- dialplan.connect_(source_session, custom_dialstring, exclude_extension)
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

function dialplan.connect_custom_style(source_session, extension_object, excluded_extension)
   
   local results = {}

   excluded_extension = excluded_extension or ""

   if DEBUG then logInfo("{session}, "..extension_object.dialstring..", {session}, "..excluded_extension); end

   results = dialplan.parse(extension_object, excluded_extension)

   if (results == nil) then
      return FAILED, "No destinations could be found for the custom dialstring <"..extension_object.dialstring..">"
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

      elseif (dialString == "") then
	 if DEBUG then logError("Returning FAILED: Internal Error"); end
	 return "FAILED", "Internal error.  Received an empty dialstring after parsing."
      else
	 --
	 -- Try to connect the call to this dialstring
	 --
	 local result, message = dialplan.connect_freeswitch_style(source_session, dialstring);

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
      if DEBUG then LogError("Returning "..last_result..": "..last_reason); end
      return last_reasult, last_reason
   end

   if DEBUG then LogError("Returning FAILED: Unknown Error"); end
   return "FAILED", "Unknown failure. No additional data can be provided."
end



