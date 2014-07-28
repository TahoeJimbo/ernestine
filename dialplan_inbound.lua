
HOUR_BED  = 21;  -- 10pm
HOUR_WAKE = 10;  -- 10am

--
-- Extensions
--

-- 546 = Jim's hunt group.

-- 1001 = hillside camera
-- 1002 = driveway camera
-- 1003 = entryway camera
-- 1004 = hillside camera

-- 4001 = iphone
-- 4002 = ipad
-- 8001 = Panasonic SIP Tahoe
-- 8002 = Snom Basement
-- 8003 = Snom Office
-- 8004 = Snom Spare
-- 8010 = SpeakerPhone

extensions = {}
canDialSelf = {}

extensions["JimTahoe"]   = "wait=30|8001:4001|VM(546)"
extensions["JimOutside"] = "wait=30:4001|VM(546)"
extensions["JimScruz"]   = "wait=30:7001|VM(546)"

extensions["JimWakeTahoe"]   = "8001:4001:JimsCell"
extensions["JimWakeOutside"] = "4001:JimsCell"
extensions["JimWakeScruz"]   = "7001:JimsCell"

extensions["JimDirectVM"] = "VM(546)"

extensions["4001"] = "wait=120|4001"
extensions["4002"] = "wait=120|4002"

extensions["7001"] = "wait=120|7001"
canDialSelf["7001"] = true;

extensions["8000"] = "wait=120|8001:8002:8003:8004:8010"

extensions["8001"] = "wait=120|8001"
canDialSelf["8001"] = true;

extensions["8002"] = "wait=120|8002"
extensions["8003"] = "wait=120|8003"
extensions["8004"] = "wait=120|8004"
extensions["8010"] = "wait=120|8010"

extensions["1001"] = "wait=120|1001"
extensions["1002"] = "wait=120|1002"
extensions["1003"] = "wait=120|1003"
extensions["1004"] = "wait=120|1004"

extensions["72688"] = "wait=120|72688"

--[[ UTILITIES --]]

--
-- Returns 1 for the user's standard greeting
-- Returns 2-4 for Jim's custom greeting...
--
-- CFNA-VOICEMAIL  X-vm_extension X-vm_greeting 
--

function selectVoicemailGreeting(extension)

   if (extension == "546") then
      local currentTime = os.time();
      local dateFields = os.date("*t", currentTime);
      local hours = dateFields.hour;

      if (hours >= HOUR_BED and hours <= 23) then return 2; end;
      if (hours >= 0 and hours < 2) then return 2; end;
      if (hours >= 2 and hours < HOUR_WAKE) then return 3; end;
   end

   return 1;
end


function extension_546(aLeg, excludeExtension)

   local dialString = nil;

   if (selectVoicemailGreeting("546") ~= 1) then
      -- straight to VM
      dialString = "VM(546)";
   elseif (location.get("546") == kTAHOE) then
      dialString = extensions["JimTahoe"];

   elseif (location.get("546") == kOUTSIDE) then
      dialString = extensions["JimOutside"];

   elseif (location.get("546") == kSCRUZ) then
      dialString = extensions["JimScruz"];
   end

   if (dialString) then
      aLeg:execute("ring_ready");

      local result, message = dialplan.connect_custom_style(aLeg, dialString, excludeExtension);

      if (result == "COMPLETED") then
	 return
      end
      
      if (result == "TRY VOICEMAIL") then
	 local extension = message

	 logInfo("Voicemail extension: "..extension);
	 greeting = selectVoicemailGreeting(extension);
	 logInfo("Voicemail greeting "..greeting);

	 aLeg:setVariable("X-vm_extension", extension);
	 aLeg:setVariable("X-vm_greeting", greeting);

	 vm_record_entrypoint(aLeg, extension, greeting);
	 return
      end
   end
   
-- Anything else is a failure.

   aLeg:answer()
   session:execute("playback","tone_stream://%(500,500,480,620);loops=10")
end

function extension_JimWake(aLeg, excludeExtension)

   local dialString = nil;

   if (location.get("546") == kTAHOE) then
      dialString = extensions["JimWakeTahoe"];

   elseif (location.get("546") == kOUTSIDE) then
      dialString = extensions["JimWakeOutside"];

   elseif (location.get("546") == kSCRUZ) then
      dialString = extensions["JimWakeScruz"];
   end

   ivr.play(aLeg, SOUNDS.."Custom/ill-try-to-wake-him.wav");

   if (dialString) then
      local result, message = dialplan.connect_custom_style(aLeg, dialString, excludeExtension);
      if result == "COMPLETED" then
	 return
      else 
	 logError("Failed to properly wake Jim: "..message)
      end
   end

   aLeg:answer()
   session:execute("playback","tone_stream://%(500,500,480,620);loops=10")
end

function dispatchInternal(aLeg, dest)

   sourceExtension = aLeg:getVariable("sip_from_user_stripped");

   if (canDialSelf[dest] == true and dest == sourceExtension) then
      excludeExtension = ""
   else
      excludeExtension = sourceExtension
   end

   local dialString = nil

   if (dest == "546") then
      extension_546(aLeg, excludeExtension);
      return;
   end

   if (dest == "JimWake") then
      extension_JimWake(aLeg, excludeExtension);
      return;
   end

   dialString = extensions[dest];
      
   if (dialString ~= nil) then
      aLeg:execute("ring_ready");
      local result, message = dialplan.connect_custom_style(aLeg, dialString, excludeExtension)
      if (result == "COMPLETED") then
	 return
      else
	 logError("Failed to connect "..sourceExtension.." to "..dest..": "..message)
      end
   end

   aLeg:answer()
   session:execute("playback","tone_stream://%(500,500,480,620);loops=10")
end

function dispatchExternal(aLeg, dest)

   local callerIDName = aLeg:getVariable("sip_from_display");

   -- TAHOE

   if (dest == "15305231043") then
      dialplan_entrypoint(aLeg, "private", "546");
   elseif (dest == "15305231044") then
      dialplan_entrypoint(aLeg, "private", "JimDirectVM");

   -- SCRUZ

   elseif (dest == "18314650752") then
      dialplan_entrypoint(aLeg, "private", "546");

   -- EASTCLIFF

   elseif (dest == "18314658399") then
      aLeg:setVariable("sip_from_display", "ECF: "..callerIDName);
      dialplan_entrypoint(aLeg, "private", "546");
   end
end

function dispatch(aLeg, context, dest)

   logInfo("dispatch({session}, "..dest..", "..context..")");

   if (context == "private") then
      dispatchInternal(aLeg, dest);
   elseif (context == "public") then
      dispatchExternal(aLeg, dest);
   else
      play_sit(aLeg);
   end

end

-- ######
--  MAIN
-- ######

function dialplan_entrypoint(session, context, destination)

   logError("STARTING DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");
	    dispatch(aLeg, context, destination);
   logError("ENDING  DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");
end
