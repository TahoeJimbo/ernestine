
-----IVRUTILS-----------------------------------------------------------------

-- API
--
-- ivr.play(session, audiopath)
-- 
--    Plays the audio file (full path)
-- 
-- ivr.prompt(session, audiopath, timeout_seconds)
--
--    Plays the audiopath, and collects a digit, or timeout_seconds
--    passes.
--
--    Returns digit, status
--       digit  = "" if nothing entered,
--       status = "timed-out" or "valid"
--
-- ivr.prompt_multi_digit(session, audiopath, timeout_seconds)
--
--    Plays the audiopath and collects multiple digits, or
--    timeout_seconds passes.  Entering a "#" terminates
--    collection.
--
--    Returns digits, status
--       digits = "" if nothing entered,
--       status = "timed-out" or "valid"
--
-- ivr.prompt_list(session, path_list, timeout_seconds)
--
--    Plays an array of audiopaths and returns when a digit
--    is pressed, or timeout_seconds passes.
--
--    Returns digit, status
--       digit  = "" if nothing entered,
--       status = "timed-out" or "valid"
--

ivr = {}

--
-- ivr.play - Plays audio path.
--
                                                                       --[[ IVR.PLAY ]]--
function ivr.play(session, audioFile)
   if session:ready() == false then
      logError("ivr.play: Session not ready. NOT Playing "..audioFile);
      return;
   else
    logInfo("ivr.play: Playing "..audioFile);
   end

   session:streamFile(audioFile);
end

-- ivr.prompt(session, audiopath, timeout_seconds)
--
--    Plays the audiopath, and collects a digit, or timeout_seconds
--    passes.
--
--    Returns digit, status
--       digit  = "" if nothing entered,
--       status = "timed-out" or "valid"
--
                                                                     --[[ IVR.PROMPT ]]--
function ivr.prompt(session, audioFile, timeout)

   local digits;
   
   if timeout == nil then
      timeout = 4000;
   end

   if session:ready() == false then
      logError("ivr.prompt: Session not ready. NOT Playing "..audioFile);
      return "", "timed-out";
   else
      logInfo("ivr.prompt: Playing "..audioFile);
   end

   session:flushDigits();
   
   digits = session:playAndGetDigits(1, -- min digits
       1, -- max digits
       1, -- max attempts
       timeout, -- digit timeout
       "", -- digit terminators
       audioFile, -- prompt audio file
       "", -- input_error_audio_file
       ".*" -- digit regular expression to validate digits
       );

   --[[ Valid digits?  If any? --]]

   if #digits == 0 then
      logInfo("ivr.prompt: Timed out.")
      return "", "timed-out";
   end

    logInfo("ivr.prompt: Received digits: "..digits);

    return digits, "valid";
end

--    Plays the audiopath and collects multiple digits, or
--    timeout_seconds passes.  Entering a "#" terminates
--    collection.
--
--    Returns digits, status
--       digits = "" if nothing entered,
--       status = "timed-out" or "valid"
--
                                                         --[[ IVR.PROMPT_MULTI_DIGIT ]]--

function ivr.prompt_multi_digit(session, audioFile, terminator)

   local digits;

   if session == nil then
      logError("Session is nil?");
      return "", "timed-out";
   end

   if session:ready() == false then
      logError("ivr.prompt_multi_digit: Session not ready. NOT Playing "
	       ..audioFile);

      return "", "timed-out";
   else
      logInfo("ivr.prompt_multi_digit: Playing "..audioFile);
   end

   session:flushDigits();

   digits = session:playAndGetDigits(1, -- min digits
       50, -- max digits
       1, -- max attempts
       4000, -- digit timeout
       terminator, -- digit terminators
       audioFile, -- prompt audio file
       "", -- input_error_audio_file
       ".*" -- digit regular expression to validate digits
       );

    --[[ Valid digits?  If any? --]]

    if #digits == 0 then
       logInfo("ivr.prompt_multi_digit: Timed out.")
       return "", "timed-out";
    end

    logInfo("ivr.prompt_multi_digit: Received digits: "..digits);

    return digits, "valid";
end

-- ivr.prompt_list(session, path_list, timeout_seconds)
--
--    Plays an array of audiopaths and returns when a digit
--    is pressed, or timeout_seconds passes.
--
--    Returns digit, status
--       digit  = "" if nothing entered,
--       status = "timed-out" or "valid"
--
                                                                --[[ IVR.PROMPT_LIST ]]--
function ivr.prompt_list(session, menu_list, timeout)
   
   local digits;
   local actual_timeout = 100;

   session:flushDigits();
   
   for index, file in ipairs(menu_list) do
      if session:ready() == false then
	 logError("ivr.prompt_list: Session not ready. NOT Playing "..file);
	 return "", "timed-out";
      end

      if index == #menu_list then 
	 actual_timeout = timeout
      end
      
      logInfo("ivr.prompt_list: Playing index "..index..":"..file);

      digits = session:playAndGetDigits(1, -- min digits
	    1, -- max digits
	    1, -- max attempts
	    actual_timeout, -- digit timeout
	    "", -- digit terminators
	    file, -- prompt audio file
	    "", -- input_error_audio_file
	    ".*" -- digit regular expression to validate digits
      );

      if digits ~= "" then
	 return digits, "valid"
      end
   end

   return "", "timed-out";
end
