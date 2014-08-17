
_ut_Extension = {}

_t_cont = {}

function _ut_Extension.init()
   if DEBUG then logInfo("Intializing location tests."); end
end


function _ut_Extension.test_001()
   _t = {}

   _t.id = "test"
   _t.domain = "10.0.0.1"
   _t.route = "wait=30:1234,5678|9876"
   _t.many_handsets = false
   _t.location = "lusaka"

   local ext = Route:new(_t, _t_cont)

   if ext == nil then
      FAIL_BANNER()
      print("Could not create valid extension.")
      FAIL()
   end

   PASS()
end

function _ut_Extension.test_002()

   local ext = Route:new(_t, _t_cont)

   if ext == nil then
      FAIL_BANNER()
      print("Could not create valid extension.")
      FAIL()
   end

   if ext:get_id() ~= "test" or ext:get_domain() ~= "10.0.0.1"
      or ext:get_route() ~= "wait=30:1234,5678|9876" 
      or ext:get_many_handsets() ~= false
      or ext:get_location() ~= "lusaka" then

	 FAIL_BANNER()
	 print("Failed accessor test.")
	 FAIL()
	 return
   end

   PASS()
end

function _ut_Extension.test_003()

   local ext1, ext2, ext3, ext4, ext5

   _t.id = nil;            ext1 = Route:new(_t, _t_cont); _t.id = "test"
   _t.domain = nil;        ext2 = Route:new(_t, _t_cont); _t.domain = "10.0.0.1"
   _t.route = nil;         ext3 = Route:new(_t, _t_cont); _t.route = "VM(546)"
   _t.location = nil;      ext4 = Route:new(_t, _t_cont); _t_location = "tahoe"
   _t.many_handsets = nil; ext5 = Route:new(_t, _t_cont); _t.many_handsets = true

   if ext1 or ext2 or ext3 or ext4 or ext5 then
      FAIL_BANNER()
      print("Invalid configuration produced valid extension!")
      print(ext1, ext2, ext3, ext4, ext5)
      FAIL()
      return
   end

   PASS()
end

