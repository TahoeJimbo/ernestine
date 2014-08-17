
_ut_Number = {}

function _ut_Number.init()
   if DEBUG then logInfo("Intializing number tests."); end
end


function _ut_Number.parse_test(plan, local_code, number, expecting_canonical, expecting_kind)
   
   local theNumber = Number:new(plan, local_code, number)

   if COMPARE_FOR_NIL(theNumber, expecting_kind) then return; end

   if theNumber.kind ~= expecting_kind then
      FAIL_BANNER()
      print("Expecting <"..expecting_kind..">, but got <"..theNumber.kind.."> instead.")
      FAIL()
      return
   end

   if theNumber.canonical_number ~= expecting_canonical then
      FAIL_BANNER()
      print("Expecting <"..expecting_canonical..">, but got <"
	       ..theNumber.canonical_number.."> instead.")
      FAIL()
      return
   end

   PASS()
end


function _ut_Number.format_test(plan, local_code, number,
				format_string, expected_result)
   
   local theNumber = Number:new(plan, local_code, number)

   if theNumber == nil then
      FAIL_BANNER()
      print("Got nil back when creating number object. Not cool.")
      FAIL()
      return
   end

   local result = theNumber:format(format_string)

   if COMPARE_FOR_NIL(result, expected_result) then return; end

   if expected_result ~= result then
      FAIL_BANNER()
      print("Expecting <"..expected_result.."> but got <"
	    ..result.."> instead.")
   end
end

------------------------------------------------------------------ BASIC CREATE TESTS --

-- Bad numbering plan name

function _ut_Number.test_001()
   local result = Number:new("xxx", "332", "1234")
   if result ~= nil then
      FAIL_BANNER()
      print("Expected nil, but received object instead.")
      FAIL()
   end
end

-- Nil local code

function _ut_Number.text_002()
   local result = Number:new("NANPA", nil, "12345")

   if result ~= nil then
      FAIL_BANNER()
      print("Expected nil, but received object instead.")
      FAIL()
   end
end

-- Nil numbering plan name

function _ut_Number.test_003()

   local result = Number:new(nil, "530", "15305231043")

   if result ~= nil then
      FAIL_BANNER()
      print("Expected nil, but received object instead.")
      FAIL()
   end
end

-- Nil number 

function _ut_Number.test_004()

   local result = Number:new("NANPA", "530", nil)

   if result ~= nil then
      FAIL_BANNER()
      print("Expected nil, but received object instead.")
      FAIL()
   end
end

-- Empty plan name

function _ut_Number.test_005()

   local result = Number:new("", "530", "15305231043")

   if result ~= nil then
      FAIL_BANNER()
      print("Expected nil, but received object instead.")
      FAIL()
   end
end

-- Empty number

function _ut_Number.test_006()

   local result = Number:new("NANPA", "530", "")

   if result ~= nil then
      FAIL_BANNER()
      print("Expected nil, but received object instead.")
      FAIL()
   end
end

----------------------------------------------------------------------------------------
---------------------------------------- PARSING ---------------------------------------


---------------------------------------------------------------- INTERNATIONAL PARSING --

function _ut_Number.test_100()
   _ut_Number.parse_test("NANPA", "", "+442089103600", "442089103600", "intl")
end

function _ut_Number.test_101()
   _ut_Number.parse_test("NANPA", "", "011442089103600", "442089103600", "intl")
end

function _ut_Number.test_100()
   _ut_Number.parse_test("NANPA", "420", "+442089103600", "442089103600", "intl")
end

function _ut_Number.test_101()
   _ut_Number.parse_test("NANPA", "114", "011442089103600", "442089103600", "intl")
end

--------------------------------------------------------------------- DOMESTIC PARSING --

function _ut_Number.test_110()
   _ut_Number.parse_test("NANPA", "530", "18314650752", "18314650752", "domestic")
end

function _ut_Number.test_111()
   _ut_Number.parse_test("NANPA", "530", "+18314650752", "18314650752", "domestic")
end

function _ut_Number.test_112()
   _ut_Number.parse_test("NANPA", "530", "01118314650752", "18314650752",
			      "domestic")
end

-- Illegal domestic numbers

function _ut_Number.test_113()
   _ut_Number.parse_test("NANPA", "530", "11314650752", nil, nil)
end

function _ut_Number.test_114()
   _ut_Number.parse_test("NANPA", "530", "18311650752", nil, nil)
end

function _ut_Number.test_115()
   _ut_Number.parse_test("NANPA", "530", "10314650752", nil, nil)
end

function _ut_Number.test_116()
   _ut_Number.parse_test("NANPA", "530", "18310650752", nil, nil)
end

------------------------------------------------------------------------ LOCAL PARSING --

function _ut_Number.test_120()
   _ut_Number.parse_test("NANPA", "530", "15305231043", "15305231043", "local")
end

function _ut_Number.test_121()
   _ut_Number.parse_test("NANPA", "530", "+15305231043", "15305231043", "local")
end

function _ut_Number.test_121()
   _ut_Number.parse_test("NANPA", "530", "01115305231043", "15305231043", "local")
end

function _ut_Number.test_122()
   _ut_Number.parse_test("NANPA", "999", "4650752", "19994650752", "local")
end

-- Illegal local numbers

function _ut_Number.test_123()
   _ut_Number.parse_test("NANPA", "530", "0231043", nil, nil)
end

function _ut_Number.test_124()
   _ut_Number.parse_test("NANPA", "530", "1231043", nil, nil)
end

function _ut_Number.test_125()
   _ut_Number.parse_test("NANPA", "999", "+2650752", "2650752", "intl")
end

------------------------------------------------------------------- EMERGENCY PARSING --

function _ut_Number.test_130()
   _ut_Number.parse_test("NANPA", "999", "911", "911", "emergency")
end

--------------------------------------------------------------------- SERVICE PARSING --

function _ut_Number.test_140()
   _ut_Number.parse_test("NANPA", "999", "411", "411", "service")
end

----------------------------------------------------------------------------------------
-------------------------------------- FORMATTING --------------------------------------

function _ut_Number.test_200()
   _ut_Number.format_test("NANPA", "530", "15305231043", 
			  "HELLO%r", "HELLO15305231043")
end   

function _ut_Number.test_201()
   _ut_Number.format_test("NANPA", "530", "15305231043", 
			  "HELLO%%", "HELLO%")
end   

function _ut_Number.test_202()
   _ut_Number.format_test("NANPA", "530", "01115305231043", 
			  "HEL%cLO", "HEL15305231043LO")
end   

function _ut_Number.test_203()
   _ut_Number.format_test("NANPA", "530", "01115305231043", 
			  "HEL%cLO", "HEL15305231043LO")
end   

function _ut_Number.test_204()
   _ut_Number.format_test("NANPA", "530", "01115305231043", 
			  "%lHELLO", "5231043HELLO")
end   

function _ut_Number.test_205()
   _ut_Number.format_test("NANPA", "530", "01115305231043", 
			  "%%%a%l%%", "%5305231043%")
end   

function _ut_Number.test_206()
   _ut_Number.format_test("NANPA", "420", "+442089103600",
			  "%%%a%l%%", nil)
end   

function _ut_Number.test_207()
   _ut_Number.format_test("NANPA", "420", "+442089103600",
			  "%c", "442089103600")
end   

function _ut_Number.test_208()
   _ut_Number.format_test("NANPA", "420", "+442089103600",
			  "%r", "+442089103600")
end   

-- Illegal constructs

function _ut_Number.test_210()
   _ut_Number.format_test("NANPA", "530", "15305231043", 
			  "HELLO%x", nil)
end   

function _ut_Number.test_211()
   _ut_Number.format_test("NANPA", "530", "15305231043", 
			  "x", nil)
end   

function _ut_Number.test_212()
   _ut_Number.format_test("NANPA", "530", "15305231043", 
			  nil, nil)
end   

