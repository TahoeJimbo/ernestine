
-- Phone number tests

test_198 = {}

function test_198.doNumber(aLeg, number) 

   recite.number_as_human(aLeg, number)
   aLeg:sleep(500)

end

function test_198.start(aLeg)

   logError("in test_198")

   aLeg:answer()
   aLeg:sleep(500)

   test_198.doNumber(aLeg, "9")
   test_198.doNumber(aLeg, "15")
   test_198.doNumber(aLeg, "43")
   
   test_198.doNumber(aLeg, "112")
   test_198.doNumber(aLeg, "121")
   test_198.doNumber(aLeg, "8019")
   
   test_198.doNumber(aLeg, "232399")
   
   test_198.doNumber(aLeg, "1000000")
   
   test_198.doNumber(aLeg, "999999999");

   aLeg:hangup()
end
