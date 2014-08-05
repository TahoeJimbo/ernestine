
-- Phone number tests

test_197 = {}

function test_197.doNumber(aLeg, number) 

   recite.number_digits_monotone(aLeg, number)
   aLeg:sleep(500)

end

function test_197.start(aLeg)

   logError("in test_197")

   aLeg:answer()
   aLeg:sleep(500)

   test_197.doNumber(aLeg, "9")
   test_197.doNumber(aLeg, "15")
   test_197.doNumber(aLeg, "43")

   test_197.doNumber(aLeg, "112")
   test_197.doNumber(aLeg, "121")
   test_197.doNumber(aLeg, "8019")

   test_197.doNumber(aLeg, "232399")

   test_197.doNumber(aLeg, "1000000")

   test_197.doNumber(aLeg, "999999999");

   aLeg:hangup()
end
