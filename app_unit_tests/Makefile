
APP_NAME = unit_tests
APP_HEADER_FILES = ../DEBUG.lua ../CONFIGURATION.lua ../compatibility_shim.lua
APP_SOURCE_FILES = unit_test_obj_dialstring.lua \
		   unit_test_recite.lua \
		   unit_test_obj_number.lua \
		   unit_test_obj_location.lua \
		   unit_test_obj_route.lua

APP_LIBS = ../lib/lib_fs \
	   ../lib/lib_lua \
	   ../lib/lib_parser \
	   ../lib/lib_unit_test

all:
	luac -o $(APP_NAME) $(APP_HEADER_FILES) $(APP_SOURCE_FILES) $(APP_LIBS)

install:
	cp $(APP_NAME) ../bin/$(APP_NAME)

clean:
	rm -f $(APP_NAME) ../bin/$(APP_NAME)
	rm -f $(APP_NAME).inspect.lua

inspect:
	rm -f $(APP_NAME).inspect.lua
	cat $(APP_HEADER_FILES) >> $(APP_NAME).inspect.lua
	@for FILE in ${APP_LIBS} ; do \
	cat $${FILE}.inspect.lua >> $(APP_NAME).inspect.lua ; \
	done
	@cat $(APP_SOURCE_FILES) >> $(APP_NAME).inspect.lua



