
function test_dispatch(session, test_number)

   test_number = test_number + 0

   if (test_number == 199) then
      test_199.start(session)
   elseif (test_number == 198) then
      test_198.start(session)
   elseif (test_number == 197) then
      test_197.start(session)
   elseif (test_number == 196) then
      test_196.start(session)
   elseif (test_number == 195) then
      test_195.start(session)
   elseif (test_number == 101) then
      echo_test(session)
   else 
      ivr.play(session, ANNOUNCEMENTS.."cannot-complete-not-in-service.wav")
   end
end



