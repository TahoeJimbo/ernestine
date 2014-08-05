
-- Phone number tests

test_195 = {}

function test_195.doSit(aLeg, message) 

   sounds.sit(aLeg, message, 1)

   aLeg:sleep(1000)

end

function test_195.start(aLeg)

   logError("in test_195")

   aLeg:answer()
   aLeg:sleep(500)

   test_195.doSit(aLeg, "reorder-local")
   test_195.doSit(aLeg, "reorder-distant")
   test_195.doSit(aLeg, "no-circuits-local")
   test_195.doSit(aLeg, "no-circuits-distant")
   test_195.doSit(aLeg, "vacant")
   test_195.doSit(aLeg, "other")
   test_195.doSit(aLeg, "intercept")
   test_195.doSit(aLeg, "reserved")

   test_195.doSit(aLeg, "bekrjn");

   aLeg:hangup()
end
