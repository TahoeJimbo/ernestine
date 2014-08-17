
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
   logInfo("Setting variable "..var.." to <"..value..">")
end

function session.execute(s, execString) logInfo("EXECUTE: "..execString); end

function session.answer(s) logInfo("ANSWERING SESSION"); end
function session.sleep(s, sleep) logInfo("SLEEPING "..sleep.." ms."); end
function session.streamFile(s, file) logInfo("PLAY FILE: "..file); end
function session.hangup(s) logInfo("HANGING UP"); end
function session.ready(s) logInfo("READY RETURNING TRUE"); return true; end

function session.destroy(s) logInfo("DESTROY"); end

function session.playAndGetDigits(s, min,max,timeout,term,prompt,error,regex,opt1,opt2,opt3)
    logInfo("Prompt: "..prompt..", Error: "..error..", Reg-Ex: "..regex)
    return "#"
end

function session.getState(s)
   return "SC_NORMAL";
end

function session.hangupCause(s)
   return "SUCCESS";
end

event = {}

function event.addHeader(dummy,header, data)
   logInfo("COMPAT: Event add header: "..header..", "..data)
end

function event.fire(dummy)
   logInfo("COMPAT: Event fired")
end


freeswitch = {}

function freeswitch.consoleLog(level, ...)
   if not UNIT_TESTING then
      io.write(level, ": ",...)
   end
end

function freeswitch.Session(dialString)
   logInfo("COMPAT: DIALING: "..dialString);
   return session;
end

function freeswitch.bridge(aLeg, bLeg)
   logInfo("COMPAT: BRIDGING")
end

function freeswitch.Event(event_string)
   logInfo("COMPAT: EVENT "..event_string)
   return event
end
