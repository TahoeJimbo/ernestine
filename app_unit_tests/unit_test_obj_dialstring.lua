
_ut_Dialstring = {}

function _ut_Dialstring.init()
   if DEBUG then logInfo("Intializing dialstring tests."); end
end


function _ut_Dialstring.run_custom_test(test)

   dialstring = Dialstring:new_custom(test.dialstring)

   dialstring:set_excluded_extension(test.excluded_extension)
   dialstring:set_default_domain(test.default_domain)

   if (test.additional_vars) then 
      for _, assignment in ipairs(test.additional_vars) do
	 local parts = string_split(assignment, "=")
	 
	 dialstring:set_variable(parts[1], parts[2])
      end
   end

   local results = dialstring:get()

   COMPARE_TABLES(results, test.expected)
end


function _ut_Dialstring.test_001()

   local test = {
      dialstring = "wait=30",
      default_domain = nil,
      excluded_extension = nil,
      expected = {}
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_002()

   local test = {
      dialstring = "8000",
      default_domain = nil,
      excluded_extension = nil,
      expected = {
	 { kind = "DS", dialstring = "[hangup_after_bridge=true]User/8000" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_003()

   local test = {
      dialstring = "8000",
      default_domain = "1.2.3.4",
      excluded_extension = nil,
      expected = {
	 { kind = "DS", dialstring = "[hangup_after_bridge=true]User/8000@1.2.3.4" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_004()

   local test = {
      dialstring = "8000@5.6.7.8",
      default_domain = "1.2.3.4",
      excluded_extension = nil,
      expected = {
	 { kind = "DS", dialstring = "[hangup_after_bridge=true]User/8000@5.6.7.8" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_005()

   local test = {
      dialstring = "8000@5.6.7.8",
      default_domain = "1.2.3.4",
      excluded_extension = "8000",
      expected = {}
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_006()

   local test = {
      dialstring = "wait=29,8000:wait=31,4000",
      default_domain = "1.2.3.4",
      excluded_extension = nil,
      expected = {
	 {kind = "DS", dialstring = "[call_timeout=29,hangup_after_bridge=true]User/8000@1.2.3.4:_:[call_timeout=31,hangup_after_bridge=true]User/4000@1.2.3.4" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_007()

   local test = {
      dialstring = "wait=29,8000:wait=31,4000",
      default_domain = "1.2.3.4",
      excluded_extension = "8000",
      expected = {
	 {kind = "DS", dialstring = "[call_timeout=31,hangup_after_bridge=true]User/4000@1.2.3.4" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_008()

   local test = {
      dialstring = "wait=29,8000:wait=31,4000",
      default_domain = "1.2.3.4",
      excluded_extension = "4000",
      expected = {
	 { kind = "DS", dialstring = "[call_timeout=29,hangup_after_bridge=true]User/8000@1.2.3.4" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_009()

   local test = {
      dialstring = "wait=30|8001:4001|VM(546)",
      default_domain = "1.2.3.4",
      excluded_extension = nil,
      expected = {
	 {kind = "DS", dialstring = "[call_timeout=30,hangup_after_bridge=true]User/8001@1.2.3.4:_:[call_timeout=30,hangup_after_bridge=true]User/4001@1.2.3.4" },
	 {kind = "FU_VM", dialstring = "546" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_010()

   local test = {
      dialstring = "wait=39|X(28)",
      default_domain = "1.2.3.4",
      excluded_extension = nil,
      expected = nil
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_011()

   local test = {
      dialstring = "wait=30|8001@5.6.7.8:4001%9.8.7.6|VM(546)",
      default_domain = "1.2.3.4",
      excluded_extension = nil,
      expected = {
	 { kind = "DS", dialstring = "[call_timeout=30,hangup_after_bridge=true]User/8001@5.6.7.8:_:[call_timeout=30,hangup_after_bridge=true]User/4001%9.8.7.6" },
	 { kind = "FU_VM", dialstring = "546" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

function _ut_Dialstring.test_012()

   local test = {
      dialstring = "wait=30|8001:4001%9.8.7.6|VM(546)",
      default_domain = "1.2.3.4",
      excluded_extension = nil,
      additional_vars = { "testVar=10", "other=222" },
      expected = {
	 { kind = "DS", dialstring = "[call_timeout=30,hangup_after_bridge=true,other=222,testVar=10]User/8001@1.2.3.4:_:[call_timeout=30,hangup_after_bridge=true,other=222,testVar=10]User/4001%9.8.7.6" },
	 { kind = "FU_VM", dialstring = "546" }
      }
   }

   _ut_Dialstring.run_custom_test(test)
end

