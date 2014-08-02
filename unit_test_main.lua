

_ut_test_name = ""
_ut_module_name = ""
_ut_stop_on_fail = false
UNIT_TESTING = true
VERBOSE = true


function PASS()
   if VERBOSE == true then
      print("PASS: ".._ut_module_name..": ".._ut_test_name)
   end
end

function FAIL_BANNER() 
   print("FAIL: Test ".._ut_module_name..": ".._ut_test_name..":")
end

function FAIL()
   if _ut_stop_on_fail == true then
      error("Stopping after error(s).")
   end
end


--
-- Returns true on failure, so it can unwind the recursion with
-- proper error messages
--

function _ut_compare_tables_recursively(results, expected, depth)

   if results == nil and expected == nil then
      return false
   end

   if (results == nil and expected) then
      FAIL_BANNER()
      print("Got nil results, but was expecting a table.")
      FAIL()
      return true
   end

   if (results and expected == nil) then
      FAIL_BANNER()
      print("Got a table of results, but was expecting nil.")
      FAIL()
      return true
   end

   -- Create a list of sorted keys for each table.  They must be the same length...

   expected_keys = {}
   results_keys = {}

   for key in pairs(expected) do
      expected_keys[#expected_keys + 1] = key
   end

   for key in pairs(results) do
      results_keys[#results_keys + 1] = key
   end

   local expected_count = #expected_keys
   local results_count = #results_keys

   table.sort(expected_keys)
   table.sort(results_keys)

   if (#expected_keys ~= #results_keys) then
      FAIL_BANNER()
      print("Key counts do not match: Expected "..#expected_keys..", received "..#results_keys)
      table_dump("Expected Table at depth "..depth, expected)
      table_dump("Results Table at depth "..depth, results)
      print("")
      return true
   end

   -- Ok, the sizes match!
   -- Compare the keys and values

   for i=1,expected_count do
      local expected_key = expected_keys[i]
      local results_key = results_keys[i]

      if expected_key ~= results_key then

	 expected_key = expected_key or "[NIL]"
	 results_key = results_key or "[NIL]"

	 FAIL_BANNER()
	 print("Key mismatch.  Expected <"..expected_key..">, got <"..results_key..">")
	 print("")
	 return true
      end

      local expected_value = expected[results_key] or "[NIL]"
      local results_value = results[results_key] or "[NIL]"

      if type(expected_value) == "table" and type(results_value) == "table" then
	 local failed = _ut_compare_tables_recursively(results_value, expected_value, depth + 1)
	 if (failed == true) then
	    print("Depth: "..depth..": Key: "..expected_key)
	    return true
	 end
      elseif type(expected_value) ~= type(results_value) then
	 FAIL_BANNER()
	 print("Depth: "..depth..": Key: "..expected_key)	 
	 print("Expected type <"..type(expected_value).."> and results type <"..type(results_value).."> are different.")
	 print("")
	 return true;
      elseif (expected_value ~= results_value) then
	 FAIL_BANNER()
	 print("Depth: "..depth..": Key: "..expected_key)
	 print("Expected value <"..expected_value.."> differs from result <"..results_value..">")
	 return true
      end
   end
end

function COMPARE_TABLES(results, expected)
   local failed = _ut_compare_tables_recursively(results, expected, 1)
   if (failed) then FAIL(); end
end



-- trundle through the global context looking for tables beginning with "_ut_"

local test_modules = {}

for key, value in pairs(_G) do
   if key:sub(1,4) == "_ut_" and type(_G[key]) == "table" then
      test_modules[#test_modules + 1] = key
   end
end
   
table.sort(test_modules);

-- for each module, initialize it (if it has an init() routine
-- and run the tests in the module.

for _, module_name in ipairs(test_modules) do

   _ut_module_name = module_name

   -- 
   -- Initialize it
   --
   local init_function = _G[module_name].init
   if (init_function) then
      if DEBUG then logInfo("Initilizing "..module_name); end
      init_function()
   end

   --
   -- Loop through all the items in the module, builing
   -- the list of tests...
   --
   
   local tests = {}
   
   for key, value in pairs(_G[module_name]) do

      if type(value) == "function" then
	 name = key:match("^test")
	 
	 if (name ~= nil) then 
	    if DEBUG then logInfo("Found test: "..key); end
	    tests[#tests + 1] = key
	 end
      end
   end

   table.sort(tests)

   --
   -- Run them
   -- 

   for _, test_name in ipairs(tests) do
      _ut_test_name = test_name
      local test_function = _G[module_name][test_name]
      
      if DEBUG then logInfo("Running "..test_name); end

      test_function()
   end
end


