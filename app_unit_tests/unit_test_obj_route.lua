
_ut_Route = {}

_t_cont = {}

function _ut_Route.init()
   if DEBUG then logInfo("Intializing location tests."); end
end


function _ut_Route.test_001()
   _t = {}

   _t.id = "test"
   _t.domain = "10.0.0.1"
   _t.route = "wait=30:1234,5678|9876"
   _t.many_handsets = "false"
   _t.location = "lusaka"

   local route = Route:new(_t, _t_cont)

   if route == nil then
      FAIL_BANNER()
      print("Could not create valid extension.")
      FAIL()
      return
   end

   PASS()
end

function _ut_Route.test_002()

   local route = Route:new(_t, _t_cont)

   if route  == nil then
      FAIL_BANNER()
      print("Could not create valid extension.")
      FAIL()
      return
   end

   if route:get_id() ~= "test" or route:get_domain() ~= "10.0.0.1"
      or route:get_route() ~= "wait=30:1234,5678|9876" 
      or route:get_many_handsets() ~= false
      or route:get_location_id() ~= "lusaka" then

	 FAIL_BANNER()
	 print("Failed accessor test.")
	 FAIL()
	 return
   end

   PASS()
end

function _ut_Route.test_003()

   local route1, route2, route3, route4, route5

   _t.id = nil;           route1 = Route:new(_t, _t_cont); _t.id = "test"
   _t.domain = nil;       route2 = Route:new(_t, _t_cont); _t.domain = "10.0.0.1"
   _t.route = nil;        route3 = Route:new(_t, _t_cont); _t.route = "VM(546)"
   _t.location = nil;     route4 = Route:new(_t, _t_cont); _t_location = "tahoe"
   _t.many_handsets = nil; route5 = Route:new(_t, _t_cont); _t.many_handsets = "true"

   if route1 or route2 or route3 or route4 or route5 then
      FAIL_BANNER()
      print("Invalid configuration produced valid extension!")
      print(ext1, ext2, ext3, ext4, ext5)
      FAIL()
      return
   end

   PASS()
end

