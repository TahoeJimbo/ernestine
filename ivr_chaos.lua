
-------------------------------------------------------------------------------

-- Define the dispatch table.. 1-->jason, etc.

dispatcher={}
dispatchExt={}

dispatcher["1"] = "jason"
dispatcher["2"] = "eric"
dispatcher["3"] = "jim"

dispatcher["jason"] = "Jason Bane"
dispatcher["eric"] = "Eric Carter"
dispatcher["jim"] = "Jim Hayes"

-- Extension format "[T|B]:dialstring".
--                   T = transfer through dialplan.
--                   B = transfer by bridging to sofia style endpoint

dispatchExt["jason"]
                  = "B:16505214710"

dispatchExt["eric"] 
                  = "B:12138148338"

dispatchExt["jim"] = "T:546";

-------------------------------------------------------------------------------
--
-- Dispatch a "dispatch" name: jim, jason or eric, using the aLeg session.
--

function ivr_dispatch(aLeg, destination)

    logError("Transfering to "..dispatcher[destination]..".")

    session:sleep(250);
    ivr.play(aLeg, CARPECHAOS.."find-"..destination..".wav");
    session:sleep(250);

    local dialString = dispatchExt[destination];

    -- Decode dial-string to figure out what to do...

    local type, subDialString = dialString:match("^([TB]):(.*)$");

    logInfo("Dispatch type: "..type..", string: <"..subDialString..">");

    -- Transfer or bridge?
    
    if (type == "T") then
       local extension, context = subDialString:match("^(%d+),(.+)$");
       dialplan_entrypoint_inbound(aLeg, private, extension);
    end

    if (type == "B") then
       dialplan_entrypoint_outbound(aLeg, context, subDialString)
    end
end

--
-- MANAGE THE MENU, PROMPTING THE USER AND REPEATING IF ERRORS OR TIMEOUTS
-- Returns the extension to transfer the caller to. and
-- status = error | timed-out | valid
--

function chaos_ivr_menu(aLeg)
    local digits
    local status

    local audioFile = CARPECHAOS.."anc-directory.wav";
    local timeoutFile = CARPECHAOS.."anc-onceagain.wav";
    local timeoutFinalFile = CARPECHAOS.."anc-timeout.wav";

    for index=1,2 do

       if (aLeg:ready() == false) then return "", "error"; end

       if (index ~= 1) then
	  aLeg:sleep(250)
	  ivr.play(aLeg, timeoutFile);
       end

       if (aLeg:ready() == false) then return "", "error"; end

       digits, status  = ivr.prompt(aLeg, audioFile);

       aLeg:sleep(250)

       if (aLeg:ready() == false) then return "", "error"; end

       if (status == "valid" and dispatcher[digits] ~= nil) then
	  local extension = dispatcher[digits]
	  logInfo("Result extension: <"..extension..">")
	  aLeg:sleep(250)
	  return extension, "valid"
       end
    end

    if (status == "timed-out") then
       logError("No response.")
       ivr.play(aLeg, timeoutFinalFile);
       if (aLeg:ready() == false) then return "", "error"; end
       return "jason", "valid"
    end

    logError("Too many errors. Hanging up.")
    ivr.play(aLeg, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
    ivr.play(aLeg, ANNOUNCEMENTS.."hangup-try-again.wav");
    aLeg:sleep(500);
    return "", "error";
end



function chaos_ivr_entrypoint(aLeg)

   aLeg:answer()
   aLeg:sleep(500)

   logError("Starting CHAOS IVR...");

   --[[ DO THE INTRODUCTION --]]

   aLeg:streamFile(CARPECHAOS.."anc-intro.wav")

   --[[ MAIN MENU --]]

   extension, status = chaos_ivr_menu(aLeg)

   if (status == "valid") then
      ivr_dispatch(aLeg, extension)
   else
      aLeg:hangup()
   end

   logError("Finished CHAOS IVR...");
end


----------------------------------------------------------------
-- MAIN
----------------------------------------------------------------

-- GATHER SOME INITIAL DATA

if (session) then
   caller_id_name = session:getVariable("caller_id_name");
   caller_id_number = session:getVariable("caller_id_number");
   caller_uuid = session:getVariable("uuid");
   destination_number = session:getVariable("sip_to_user");

   if (caller_id_name == nil) then caller_id_name="UNKNOWN" end
   if (caller_id_number == nil) then caller_id_name="UNKNOWN" end
   if (caller_uuid == nil) then caller_uuid="????" end
end

--
-- APPLICATION INIT GOES HERE
--

logError("Starting Carpe Chaos IVR")

--
-- APPLICATION DISPATCH GOES HERE
--

chaos_ivr_entrypoint(session)

