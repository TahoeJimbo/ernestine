
function runner(test, exclude_ext)
   exclude_ext = exclude_ext or ""

   print("Testing <"..test..">, excluding <"..exclude_ext..">")
   results = dialplan.parse(test, exclude_ext)
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

   test = "wait=30"
   runner(test, nil)

   test = "8000"
   runner(test)
   runner(test, "8000")

   test = "wait=29,8000:wait=31,4000"
   runner(test, nil)
   runner(test, "4000")
   runner(test, "8000")

   test = "wait=30|8001:4001|VM(546)"
   runner(test, nil)

   test = "wait=39|X(28)"
   runner(test, nil)

   DEBUG = debugState
end

