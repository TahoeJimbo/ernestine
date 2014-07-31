
APPS = helper unit_tests insitu_tests dispatch ivr_chaos sa_dispatch
INSTALL_DIR=/usr/local/freeswitch/scripts

CFLAGS=-g

#
# LIBRARIES
#
CORE_LIBS = CONFIGURATION.lua \
	    utilities_string.lua \
	    utilities_logging.lua \
	    utilities_files.lua \
	    utilities_execute.lua \
	    utilities_dialplan.lua \
	    utilities_dialplan_private.lua \
	    utilities_sounds.lua \
	    utilities_tables.lua \
	    utilities_recite.lua \
	    utilities_ivr.lua

VOICEMAIL_LIB = vm_box.lua \
		vm_box_menu.lua \
		vm_cli.lua \
		vm.lua \
		vm_main_menu.lua

LOCATION_LIB = location.lua

#
# UNIT TEST FILES
#

UNIT_TEST_SRC = unit_test_recite.lua \
		unit_test_dialplan.lua \
		unit_test_main.lua

#
# INSITU TEST FILES
#

INSITU_TEST_SRC = test_record_menu.lua \
		  test_dispatch.lua \
		  test_199.lua \
		  test_198.lua \
		  test_197.lua \
		  test_196.lua \
		  test_195.lua
#
# APPLICATIONS
#

DISPATCH_APP = CONFIGURATION.lua \
	       $(CORE_LIBS) \
	       $(VOICEMAIL_LIB) \
	       $(LOCATION_LIB) \
	       dialplan_outbound.lua \
	       dialplan_inbound.lua \
	       dispatcher.lua

CHAOS_IVR_APP = CONFIGURATION.lua \
	        $(CORE_LIBS) \
		dialplan_outbound.lua \
		ivr_chaos.lua 

INSITU_TEST_APP = CONFIGURATION.lua \
		  $(CORE_LIBS) \
		  $(INSITU_TEST_SRC) \
	          test_menu.lua

UNIT_TEST_APP = CONFIGURATION.lua \
	        compatibility.lua \
		$(CORE_LIBS) \
		$(UNIT_TEST_SRC)

HELPER_APP=helper.o

#
# RULES
#

all: clean $(APPS) test

clean:
	@(cd $(INSTALL_DIR); rm -f $(APPS) $(HELPER_APP))
	@rm -f $(APPS) $(HELPER_APP)

test:
	@lua unit_tests DIALPLAN | diff -c - unit_test_dialplan.expected.txt
	@lua unit_tests RECITE   | diff -c - unit_test_recite.expected.txt


helper: $(HELPER_APP)
	@echo "HELPER:"
	@rm -f $(INSTALL_DIR)/helper
	@cc -o helper $(HELPER_APP)
	@cp helper $(INSTALL_DIR)


#
# Production dialplan/voicemail app
# 
dispatch:
	@echo "DISPATCH:"
	@rm -f $(INSTALL_DIR)/dispatch
	@luac -o dispatch $(DISPATCH_APP)
	@cp dispatch $(INSTALL_DIR)
	@cp dialplan_config.txt $(INSTALL_DIR)


# Stand-alone dispatch using compatibility shim for testing.

sa_dispatch:
	@echo "SA DISPATCH:"
	@rm -f $(INSTALL_DIR)/dispatch
	@luac -o sa_dispatch compatibility.lua $(DISPATCH_APP)
	@cp dispatch $(INSTALL_DIR)


#
# Production Carpe Chaos IVR app
#
ivr_chaos:
	@echo "Carpe Chaos IVR"
	@rm -f $(INSTALL_DIR)/ivr_chaos
	@luac -o ivr_chaos $(CHAOS_IVR_APP)
	@cp ivr_chaos $(INSTALL_DIR)

#
# IN-SITU TEST APP
#
insitu_tests:
	@echo "IN-SITU TESTS:"
	@rm -f $(INSTALL_DIR)/insitu_tests
	@luac -o insitu_tests $(INSITU_TEST_APP)
	@cp insitu_tests $(INSTALL_DIR)

#
# Stand-along unit tests
#

unit_tests:
	@echo "UNIT TESTS:"
	@rm -f unit_tests
	@luac -o unit_tests compatibility.lua $(UNIT_TEST_APP)


