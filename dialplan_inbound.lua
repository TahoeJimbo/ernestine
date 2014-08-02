


--[[ UTILITIES --]]


--
-- Extension file processor
--

extensions = {}

function Extension(ext)
   if ext.id == nil then
      logError("Extension's id must be set.")
      return
   end

   if ext.dialstring == nil then
      logError("Extension's dialstring must be set.")
   end

   ext.domain = ext.domain or default_domain
   ext.external_caller_id_name = ext.external_caller_id_name or default_external_caller_id_name
   ext.external_caller_id_number = ext.external_caller_id_number or default_external_caller_id_number
   ext.many_handsets = ext.many_handsets or default_many_handsets

   extensions[ext.id] = ext
end


dofile(SCRIPTS.."dialplan_config.txt")

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

   local extension = nil;
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

   local dialString = nil;
   local where = location.get("546")
   local extension = nil

   if (where == kTAHOE) then
      extension = extensions["JimWakeTahoe"];

   elseif (where == kOUTSIDE) then
      extension = extensions["JimWakeOutside"];

   elseif (where == kSCRUZ) then
      extension = extensions["JimWakeScruz"];
   end
   
   if extension then
      ivr.play(aLeg, SOUNDS.."Custom/ill-try-to-wake-him.wav");
      return extension
   end

   logError("Failed to properly wake Jim: "..message)
   return nil
end

function dispatch_internal(aLeg, destination_digits)

   local source_extension_digits = aLeg:getVariable("sip_from_user_stripped");
   local excluded_extension
   local extension = nil

   if DEBUG then logInfo("Connecting to <"..destination_digits.."> from <"..source_extension_digits..">"); end

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
      
      vm_record_entrypoint(aLeg, extension, greeting);
      return
   else
      logError("Failed to connect "..source_extension_digits.." to "..extension.dialstring..": "..message)
   end

   sounds.sit(aLeg, "reorder-local")
end

function dispatch_external(aLeg, dest)

   local callerIDName = aLeg:getVariable("sip_from_display");

   -- TAHOE

   if (dest == "15305231043") then
      dispatch_internal(aLeg, "546");
   elseif (dest == "15305231044") then
      dispatch_internal(aLeg, "JimDirectVM");

   -- SCRUZ

   elseif (dest == "18314650752") then
     dispatch_internal(aLeg, "546");

   -- EASTCLIFF

   elseif (dest == "18314658399") then
      aLeg:setVariable("sip_from_display", "ECF: "..callerIDName);
      dispatch_internal(aLeg, "546");
   end

   sounds.sit(aLeg, "intercept");
end

function dispatch(aLeg, context, dest)

   logInfo("dispatch({session}, "..dest..", "..context..")");

   if (context == "private") then
      dispatch_internal(aLeg, dest);
   elseif (context == "public") then
      dispatch_external(aLeg, dest);
   else
      sounds.sit(aLeg, "reorder-local");
   end
end

-- ######
--  MAIN
-- ######

function dialplan_entrypoint_inbound(session, context, destination)

   logError("STARTING INTERNAL DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");
	    dispatch(aLeg, context, destination);
   logError("ENDING INTERNAL DIALPLAN: dest=<"..destination..">, "
	                        .."context=<"..context..">");
end