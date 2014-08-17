


--[[ UTILITIES --]]




function dispatch_inbound(source_obj, context, destination_digits)

   if (context == "private") then
      dispatch_from_internal(fs_session, dest);
   elseif (context == "public") then
      dispatch_from_external(fs_session, dest);
   else
      logError("Invalid context <"..context..">")
      sounds.sit(fs_session, "reorder-local");
   end
end


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


function extension_546()

   local where = location.get("546")

   if (selectVoicemailGreeting("546") ~= 1) then
      return extensions["JimDirectVM"]

   elseif (where == kTAHOE) then
      return extensions["JimTahoe"];

   elseif (where == kOUTSIDE) then
      return extensions["JimOutside"];

   elseif (where == kSCRUZ) then
      return extensions["JimScruz"];
   end
   
   logError("Couldn't choose call disposition for extension 546")
   return nil
end

function extension_JimWake()

   local where = location.get("546")
   local extension = nil

   if (where == kTAHOE) then
      return extensions["JimWakeTahoe"];
   end

   if (where == kOUTSIDE) then
      return extensions["JimWakeOutside"];
   end

   if (where == kSCRUZ) then
      return  extensions["JimWakeScruz"];
   end

   logError("Failed to properly wake Jim: ")
   return nil
end

-----------------------------------------------------------------------------------------
-- Calls from internal extensions to internal extensions are handled here...
-----------------------------------------------------------------------------------------

function dispatch_from_internal(source_obj, destination_digits)

   

   local source_extension_digits = aLeg:getVariable("sip_from_user_stripped");
   local excluded_extension
   local extension = nil

   if DEBUG then logInfo("Connecting to <"..destination_digits
			 .."> from <"..source_extension_digits..">"); end

   local source_extension = extensions[source_extension_digits]

   if source_extension and source_extension.many_handsets == true then
      excluded_extension = ""
   else
      excluded_extension = source_extension_digits
   end

   -- Pseudo extensions with custom logic  (location, or special hunting)
   -- They'll return an extension object we should use, or nil if not.

   if (destination_digits == "546") then
      extension = extension_546()
   end

   if (destination_digits == "JimWake") then
      extension = extension_JimWake()

      if extension then
	 ivr.play(aLeg, SOUNDS.."Custom/ill-try-to-wake-him.wav");
      end
   end

   if extension == nil then 
      --
      -- Custom functions didn't recommend anything...  So use the dialed digits.
      --
      extension = extensions[destination_digits]
   end

   if (extension == nil) then
      logError("Could not locate extension <"..destination_digits.."> in dialplan_config.txt file")
      sounds.sit(aLeg, "intercept")
      return
   end

   aLeg:execute("ring_ready");

   local destination = Destination:new()
   destination:set_custom_dialstring(extension.dialstring)
   destination:set_excluded_extension(excluded_extension)
   destination:set_source_caller_id(aLeg:getVariable("sip_from_display"),
				    source_extension_digits)

   destination:set_default_domain(extension.domain)

   local result, message = destination:connect(aLeg)

   if result == "COMPLETED" then
      return

   elseif result == "TRY VOICEMAIL" then
      local extension = message

      logInfo("Voicemail extension: "..extension);
      greeting = selectVoicemailGreeting(extension);
      logInfo("Voicemail greeting "..greeting);
      
      aLeg:setVariable("X-vm_extension", extension);
      aLeg:setVariable("X-vm_greeting", greeting);

      aLeg:setAutoHangup(false)

      aLeg:execute("lua", "voicemail record "..extension.." "..greeting)
      return
   else
      logError("Failed to connect "..source_extension_digits.." to "..extension.dialstring..": "..message)
   end

   sounds.sit(aLeg, "reorder-local")
end

function dispatch_external(aLeg, dest)

   if DEBUG then logInfo("Dispatching "..dest.." to external dialplan processor."); end
   aLeg:execute("info")

   local caller_id_name = aLeg:getVariable("sip_from_display");
   
   if (caller_id_name == nil) then
      caller_id_name = aLeg:getVariable("sip_from_user_stripped");
      if caller_id_name ~= nil then aLeg:setVariable("sip_from_display", caller_id_name); end
   end

   if (caller_id_name == nil) then
      caller_id_name = "[No ID Provided]"
      aLeg:setVariable("sip_from_display", caller_id_name);
   end

   local caller_id_number = aLeg:getVariable("sip_from_user_stripped");

   -- Sanity check

   if dest:sub(1,2) == "+1" or dest:sub(1,1) == "1" then
      --
      -- Success!
      --
   else
      logError("Invalid destination number: "..dest)
      sounds.sit(aLeg, "intercept")
      return
   end

   if (dest:sub(1,1) == "+") then
      dest = dest:sub(2, #dest)
   end

   logError("Processing call from <"..caller_id_name..">/<"..caller_id_number.."> to <"..dest..">")

   -- TAHOE

   if dest == "15305231043" or "15305233073" then 
      dispatch_internal(aLeg, "546")
      return
   elseif dest == "15305259155" then
      aLeg:setVariable("sip_from_display", "55:"..caller_id_name)
      dispatch_internal(aLeg, "546")
      return
   elseif (dest == "15305231044") then
      dispatch_internal(aLeg, "JimDirectVM")
      return
   -- SCRUZ

   elseif (dest == "18314650752") then
     dispatch_internal(aLeg, "546");
     return
   -- EASTCLIFF

   elseif (dest == "18314658399") then
      aLeg:setVariable("sip_from_display", "ECF: "..caller_id_name)
      dispatch_internal(aLeg, "546");
      return
   end

   logError("No incoming DIDs match: "..dest)
   sounds.sit(aLeg, "intercept");
end

--
-- CALLABLE UTILITIES
--

function DP_FUNC_echo_test(fs_session)
   fs_session:answer()
   fs_session:sleep(500)
   ivr.play(fs_session, ANNOUNCEMENTS.."demo-echotest.wav")
   sounds.voicemail_beep(fs_session)
   fs_session:execute("echo")
   ivr.play(fs_session, ANNOUNCEMENTS.."demo-echodone.wav")
   ds_session:hangup()
end

function DP_FUNC_echo_test_delayed(fs_session)
   fs_session:answer()
   fs_session:sleep(500)
   ivr.play(fs_session, ANNOUNCEMENTS.."demo-echotest.wav")
   sounds.voicemail_beep(fs_session)

   fs_session:execute("echo_delay", 5000)
   ivr.play(fs_session, ANNOUNCEMENTS.."demo-echodone.wav")
   fs_session:hangup()
end

