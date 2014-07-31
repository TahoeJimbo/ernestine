
function runner(test, exclude_ext)
   exclude_ext = exclude_ext or ""

   print("Testing <"..test..">, excluding <"..exclude_ext..">")

   local extObj = {}
   extObj.id = "1234"
   extObj.dialstring = test
   extObj.domain = "1.2.3.4"

   results = dialplan.parse(extObj, exclude_ext)
   if (results == nil) then
      print "Results: Nil"
   else
      table_dump("Results:", results)
   end
   print ""
end

function dialplan_unittest()

   local debugState = DEBUG or nil

   DEBUG = nil


   local default_domain = nil
   local test

   test = "wait=30"
   runner(test, nil, default_domain)

   test = "8000"
   runner(test, nil, default_domain)
   runner(test, "8000", default_domain)

   test = "wait=29,8000:wait=31,4000"
   runner(test, nil, default_domain)
   runner(test, "4000", default_domain)
   runner(test, "8000", default_domain)

   test = "wait=30|8001:4001|VM(546)"
   runner(test, nil, default_domain)

   test = "wait=39|X(28)"
   runner(test, nil, default_domain)

   default_domain = "1.2.3.4"

   test = "wait=30"
   runner(test, nil, default_domain)

   test = "8000@5.6.7.8"
   runner(test, nil, default_domain)
   runner(test, "8000", default_domain)

   test = "wait=29,8000:wait=31,4000"
   runner(test, nil, default_domain)
   runner(test, "4000", default_domain)
   runner(test, "8000", default_domain)

   test = "wait=30|8001@5.6.7.8:4001%9.8.7.6|VM(546)"
   runner(test, nil, default_domain)

   test = "wait=39|X(28)"
   runner(test, nil, default_domain)



   DEBUG = debugState
end

