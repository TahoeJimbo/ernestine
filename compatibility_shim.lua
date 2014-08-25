
--[[ COMPATIBILITY MODULE --]]

COMPATIBILITY_MODE = true

session={}

function session.getVariable(s, var)
    if var == "caller_id_name" then  return "Jim Hayes"
    elseif var == "caller_id_number" then return "8001"
    elseif var == "uuid" then return "0000-2344-3412-2322"
    elseif var == "sip_to_user" then return "611"
    elseif var == "sip_from_user_stripped" then return "8001"
    elseif var == "endpoint_disposition" then return "ANSWER"
    end
    
    logError("Requested variable <"..var.."> is not defined.")
    return "NOTDEFINED"
end

function session.setVariable(s, var, value)
   if DEBUG_COMPATIBILITY then
      logInfo("Setting variable "..var.." to <"..value..">");
   end
end

function session.execute(s, execString) logInfo("EXECUTE: "..execString); end

function session.answer(s) logInfo("ANSWERING SESSION"); end
function session.sleep(s, sleep) logInfo("SLEEPING "..sleep.." ms."); end
function session.streamFile(s, file) logInfo("PLAY FILE: "..file); end
function session.hangup(s) logInfo("HANGING UP"); end
function session.ready(s) logInfo("READY RETURNING TRUE"); return true; end

function session.destroy(s) logInfo("DESTROY"); end

function session.playAndGetDigits(s, min,max,timeout,term,prompt,error,regex,opt1,opt2,opt3)
    if DEBUG_COMPATIBILITY then
       logInfo("Prompt: "..prompt..", Error: "..error..", Reg-Ex: "..regex)
    end
    return "#"
end

function session.getState(s)
   return "SC_NORMAL";
end

function session.hangupCause(s)
   return "SUCCESS";
end

function session.setAutoHangup(s, bool)
   local bool_string

   if bool == true then bool_string = "true"; end
   if bool == false then bool_string = "false"; end

   if bool_string == nil then bool_string = "???"; end

   if DEBUG_COMPATIBILITY then logInfo("AUTO HANGUP: "..bool_string); end
end

event = {}

function event.addHeader(dummy,header, data)
   if DEBUG_COMPATIBILITY then 
      logInfo("COMPAT: Event add header: "..header..", "..data)
   end
end

function event.fire(dummy)
   if DEBUG_COMPATIBILITY then logInfo("COMPAT: Event fired"); end
end


freeswitch = {}

function freeswitch.consoleLog(level, ...)
   if not UNIT_TESTING then
      io.write(level, ": ",...)
   end
end

function freeswitch.Session(dialString)
   if DEBUG_COMPATIBILITY then 
      logInfo("COMPAT: DIALING: "..dialString);
   end
   return session;
end

function freeswitch.bridge(aLeg, bLeg)
   if DEBUG_COMPATIBILITY then 
      logInfo("COMPAT: BRIDGING")
   end
end

function freeswitch.Event(event_string)
   if DEBUG_COMPATIBILITY then 
      logInfo("COMPAT: EVENT "..event_string)
   end

   return event
end
