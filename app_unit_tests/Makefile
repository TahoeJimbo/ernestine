
APP_NAME = unit_tests

APP_SOURCE_FILES = unit_test_obj_dialstring.lua unit_test_recite.lua
APP_LIBS = ../compatibility_shim.lua \
	   ../CONFIGURATION.lua \
	   ../lib/lib_fs \
	   ../lib/lib_lua \
	   ../lib/lib_unit_test \
	   ../location.lua

all:
	luac -o $(APP_NAME) $(APP_SOURCE_FILES) $(APP_LIBS)

install:
	cp $(APP_NAME) ../bin/$(APP_NAME)

clean:
	rm -f $(APP_NAME) ../bin/$(APP_NAME)



