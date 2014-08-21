


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

function route_call_from_internal(source_obj, destination_digits)

   --
   -- Quick sanity check
   --
   if source_obj == nil or destination_digits == nil then
      logError("Invalid arguments")

      -- Use the global "session" since our source session appears invalid.

      sounds.sit(session, "reserved")
      return
   end

   if DEBUG then logInfo("Connecting <"..source_obj.source_digits.."> to <"
			    ..destination_digits..">")
   end

   --
   -- Get some info about the source route...
   --

   if source_obj:get_source_route_obj():get_many_handsets() == true then
      excluded_extension = ""
   else
      excluded_extension = source_obj:get_source_digits()
   end

   --
   -- Fetch the destination route
   --

   local destination_route = gRoutes:route_from_digits(destination_digits)
   local source_session = source_obj:get_fs_session()

   if destination_route == nil then
      logError("No route found to <"..destination_digits..">")
      sounds.sit(source_session, "vacant")
      return
   end

   source_session:execute("ring_ready");

   local destination = Destination:new()
   destination:set_custom_dialstring(destination_route:get_route())
   destination:set_excluded_extension(excluded_extension)

   local source_cname, source_cid = source_obj:get_caller_id_info()
   destination:set_source_caller_id(source_cname, source_cid)

   destination:set_default_domain(destination_route:get_domain())

   local result, message = destination:connect(source_session)

   if result == "COMPLETED" then
      return

   elseif result == "TRY VOICEMAIL" then
      local args = string_split(message, ",")
      local extension = args[1]
      local greeting

      if args[2] then 
	 greeting = args[2]
      else
	 greeting = "1"
      end

      logInfo("Voicemail extension: "..extension);
      logInfo("Voicemail greeting "..greeting);
      
      source_session:setVariable("X-vm_extension", extension);
      source_session:setVariable("X-vm_greeting", greeting);

      source_session:setAutoHangup(false)

      source_session:execute("lua", "voicemail record "..extension.." "..greeting)
      return
   elseif result == "REDIRECT" then
      local extension = message
      
      route_call_from_internal(source_obj, extension)
      return
   else
      logError("Failed to connect <"..source_obj.source_digits
		  .."> to <"..destination_digits..">: "..message)
   end

   sounds.sit(source_session, "reorder-local")
end

function route_call_from_external(source_obj, destination_number)

   if source_obj == nil or destination_number == nil then
      logError("Invalid arguments.")
      sounds.sit(session, "reorder-distant")
      return 
   end

   if DEBUG then
      logInfo("Routing "..destination_number.." to external dialplan processor.")
   end

   -- Sanity check

   if destination_number:sub(1,2) == "+1" or destination_number:sub(1,1) == "1" then
      --
      -- Success!
      --
   else
      logError("Invalid destination number: "..destination_number)
      sounds.sit(source_obj:get_fs_session(), "intercept")
      return
   end

   if (destination_number:sub(1,1) == "+") then
      destination_number = destination_number:sub(2, #destination_number)
   end

   local source_cname, source_cid = source_obj:get_caller_id_info()

   logError("Processing call from <"..source_cname..">/<"..source_cid..
	       "> to <"..destination_number..">")

   --
   -- Do more sanity checking...  The number must have a valid
   -- route in the routing database
   --

   local route = gRoutes:route_from_digits(destination_number)

   if route then
      route_call_from_internal(source_obj, route:get_id())
      return
   end

   logError("No incoming DIDs match: "..destination_number)
   sounds.sit(source_obj:get_fs_session(), "intercept");
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

