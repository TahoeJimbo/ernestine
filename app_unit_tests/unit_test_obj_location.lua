
_ut_Location = {}

function _ut_Location.init()
   if DEBUG then logInfo("Intializing location tests."); end
end

function _ut_Location.test_001()
   _t = {}

   _t.id = "test"
   _t.description = "Test Desc."
   _t.activation_code = "*9"
   _t.default_caller_id_name = "Jane Smith"
   _t.default_caller_id_number = "18005551212"
   _t.e911_id = "15305551212"
   _t.local_code = "530"
   _t.numbering_plan = "NANPA"

   local loc = Location:new(_t)

   if loc == nil then
      FAIL_BANNER()
      print("Could not create valid location.")
      FAIL()
   end

   PASS()
end

function _ut_Location.test_002()
   local loc = Location:new(_t)

   if loc:get_id() ~= "test" or loc:get_description() ~= "Test Desc."
   or loc:get_activation_code() ~= "*9" then
       FAIL_BANNER()
       print("Failed accessor test. (A)")
       FAIL()
       return
   end

   local cname, cnumber = loc:get_caller_id_info()

   if cname ~= "Jane Smith" or cnumber ~= "18005551212" then
       FAIL_BANNER()
       print("Failed accessor test. (B)")
       print(cname, cnumber, dnd_start, dnd_end)
       FAIL()
       return
   end

   if loc:get_e911_id() ~= "15305551212" or
      loc:get_local_code() ~= "530" or loc:get_numbering_plan() ~= "NANPA" then

       FAIL_BANNER()
       print("Failed accessor test. (C)")
       FAIL()
       return
   end
      
   PASS()
end

function _ut_Location.test_003()

   local loc1, loc2, loc3, loc4, loc5

   _t.id = nil;              loc1 = Location:new(_t); _t.id = "test"

   _t.default_caller_id_name = nil
   loc2 = Location:new(_t)
   _t.default_caller_id_name = "Jane Smith"

   _t.default_caller_id_number = nil
   loc3 = Location:new(_t)
   _t.default_caller_id_number = "18005551212"

   _t.local_code = nil;      loc4 = Location:new(_t); _t.local_code = "530"
   _t.numbering_plan = nil;  loc5 = Location:new(_t); _t.numbering_plan = "NANPA"

   if loc1 or loc2 or loc3 or loc4 or loc5 then
      FAIL_BANNER()
      print("Invalid configuration produced valid location! (A)")
      print(loc1, loc2, loc3, loc4, loc5)
      FAIL()
      return
   end

   PASS()
end

