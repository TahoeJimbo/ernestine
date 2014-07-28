
-- Phone number tests

test_199 = {}


function test_199.doPhone(aLeg, number) 

   recite.phone_number(aLeg, number)
   aLeg:sleep(500)

end

function test_199.start(aLeg)

   logError("in test_199")

   aLeg:answer()
   aLeg:sleep(500)

   test_199.doPhone(aLeg, "8314197859")
   test_199.doPhone(aLeg, "9168011399")

   test_199.doPhone(aLeg, "15305231043")
   test_199.doPhone(aLeg, "18885303073")

   test_199.doPhone(aLeg, "447952007849")
   test_199.doPhone(aLeg, "8001")

   aLeg:hangup()
end
