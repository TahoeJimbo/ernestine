
-- Phone number tests

test_196 = {}

function test_196.doNumber(aLeg, number) 

   recite.number_digits_smart(aLeg, number)
   aLeg:sleep(500)

end

function test_196.start(aLeg)

   logError("in test_196")

   aLeg:answer()
   aLeg:sleep(500)

   test_196.doNumber(aLeg, "9")
   test_196.doNumber(aLeg, "15")
   test_196.doNumber(aLeg, "43")

   test_196.doNumber(aLeg, "112")
   test_196.doNumber(aLeg, "121")
   test_196.doNumber(aLeg, "8019")
   
   test_196.doNumber(aLeg, "232399")

   test_196.doNumber(aLeg, "1000000")

   test_196.doNumber(aLeg, "999999999");

   aLeg:hangup()
end
