
sounds = {}

sit_tones = {}
sit_messages1 = {}
sit_messages2 = {}

sit_tones["reorder-local"]       = "SLLHLL"
sit_tones["reorder-distant"]     = "SHLLLL"
sit_tones["no-circuits-local"]   = "LHLHLL"
sit_tones["no-circuits-distant"] = "LLLLLL"
sit_tones["vacant"]              = "LHSLLL"
sit_tones["other"]               = "LLSHLL"
sit_tones["intercept"]           = "SLSLLL"
sit_tones["reserved"]            = "SHSHLL"

sit_messages1["reorder-local"]      = ANNOUNCEMENTS.."cannot-complete-as-dialed.wav"
sit_messages2["reorder-local"]      = ANNOUNCEMENTS.."hangup-try-again.wav"

sit_messages1["reorder-distant"]    = ANNOUNCEMENTS.."cannot-complete-otherend-error.wav"
sit_messages2["reorder-distant"]    = ANNOUNCEMENTS.."hangup-try-again.wav"

sit_messages1["no-circuits-local"]  = ANNOUNCEMENTS.."cannot-complete-all-circuits-busy-now.wav"
sit_messages2["no-circuits-local"]  = ANNOUNCEMENTS.."hangup-try-again.wav"

sit_messages1["no-circuits-distant"]= ANNOUNCEMENTS.."cannot-complete-all-circuits-busy-now.wav"
sit_messages2["no-circuits-distant"]= ANNOUNCEMENTS.."hangup-try-again.wav"

sit_messages1["vacant"]             = ANNOUNCEMENTS.."that-is-not-rec-phn-num.wav"
sit_messages2["vacant"]             = ANNOUNCEMENTS.."check-number-dial-again.wav"

sit_messages1["other"]              = ANNOUNCEMENTS.."an-error-has-occured.wav"
sit_messages2["other"]              = ANNOUNCEMENTS.."hangup-try-again.wav"

sit_messages1["intercept"]          = ANNOUNCEMENTS.."cannot-complete-as-dialed.wav"
sit_messages2["intercept"]          = ANNOUNCEMENTS.."check-number-dial-again.wav"

sit_messages1["reserved"]            = ANNOUNCEMENTS.."we-apologize.wav"
sit_messages2["reserved"]           = ANNOUNCEMENTS.."weasels-have-eaten.wav"

--
-- Plays a SIT tone for the specified number of times, or 3 of not repeat count
-- is provided.
--
-- kind = [reorder-local, reorder-distant, no-circuits-local, no-circuits-distant
--         vacant, other, intercept, reserved]
--
                                                                     --[[ SOUNDS.SIT ]]--
function sounds.sit(session, kind, repeats)

   local tone = sit_tones[kind]
   local message1 = sit_messages1[kind]
   local message2 = sit_messages2[kind]
   
   if tone == nil then
      tone = sit_tones["other"]
      message1 = ANNOUNCEMENTS.."weasels-have-eaten.wav"
      message2 = ANNOUNCEMENTS.."hangup-try-again.wav"
      logError("Invalid sit-tone <"..kind.."> requested.")
   end

   repeats = repeats or 3

   local tone_stream = "tone_stream://v=-20;"

   local len, freq

   len = tone:sub(1,1)
   freq = tone:sub(2,2)

   if len == "S" then
      tone_stream = tone_stream.."%(380,0,"
   else
      tone_stream = tone_stream.."%(274,0,"
   end

   if freq == "L" then
      tone_stream = tone_stream.."913.8);"
   else
      tone_stream = tone_stream.."985.2);"
   end

   len = tone:sub(3,3)
   freq = tone:sub(4,4)

   if len == "S" then
      tone_stream = tone_stream.."%(380,0,"
   else
      tone_stream = tone_stream.."%(274,0,"
   end

   if freq == "L" then
      tone_stream = tone_stream.."1370.6);"
   else
      tone_stream = tone_stream.."1428.5);"
   end

   tone_stream = tone_stream.."%(380,0,1776.7)"

   for i=1,repeats do
      session:execute("playback", tone_stream)
      session:sleep(100)
      
      if message1 then
	 session:streamFile(message1)
      end
      
      if message2 then
	 session:sleep(250)
	 session:streamFile(message2)
      end

      if message1 or message2 then
	 session:sleep(1000)
      else
	 session:sleep(500)
      end
   end

end

                                                          --[[ SOUNDS.VOICEMAIL_BEEP ]]--
function sounds.voicemail_beep(session)

   session:execute("playback",
		   "tone_stream://v=-7;%(100,0,440);v=-7;>=2;+=.1;%(400,0,440)");

end

function sounds.confirmation_tone(session)

   session:execute("playback", "tone_stream://L=3;%(100,100,350,440)")

end
