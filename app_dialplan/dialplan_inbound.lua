
--[[ UTILITIES --]]

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

   local destination_route = gRoutes:route_from_digits(destination_digits)
   local source_session = source_obj:get_fs_session()

   local source_route_obj = source_obj:get_source_route_obj()
   local excluded_extension = ""

   if source_route_obj and source_route_obj:get_many_handsets() == false then
      excluded_extension = source_obj:get_source_digits()
   end

   --
   -- Check for special destinations setting location...
   --

   local location = gLocations:location_from_activation_code(destination_digits)
   
   if location then

      logInfo("Location access code "..destination_digits.." found.")

      --
      -- Get the owner mailbox, so we set the location...
      -- 

      if source_route_obj then
	 local location_box = source_route_obj:get_owner_vm_box()

	 if location_box then
	    local confirmation_message = location:get_confirmation_msg()
	    local id = location:get_id()

	    gLocations:set(location_box, id)
	    
	    --
	    -- Play the confirmation message if it exists...
	    --
	    source_session:answer()
	    source_session:sleep(400)
	    if confirmation_message then
	       ivr.play(source_session, SOUNDS..confirmation_message)
	    else 
	       sounds.confirmation_tone(session)
	    end
	    logInfo("Location for <"..location_box.."> set to <"..id..">")
	    return
	 end

      end
      return
   end


   --
   -- Fetch the destination route
   --


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

   if destination_number:sub(1,2) == "+1" or destination_number:sub(1,1) == "1" 
      or destination_number:match("^EMERGENCY_.+$") then
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
   fs_session:hangup()
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

