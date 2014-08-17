
APP_NAME = dialplan

APP_SOURCE_FILES = dialplan_inbound.lua dialplan_outbound.lua dialplan_main.lua
APP_LIBS = ../DEBUG.lua ../CONFIGURATION.lua ../lib/lib_fs ../lib/lib_lua ../lib/lib_parser \
	   ../location.lua

all:
	luac -o $(APP_NAME) $(APP_LIBS) $(APP_SOURCE_FILES)
	luac -o sa-$(APP_NAME) ../compatibility_shim.lua $(APP_LIBS) $(APP_SOURCE_FILES)

install:
	cp $(APP_NAME) ../bin
	cp dialplan_config.txt ../bin

clean:
	rm -f $(APP_NAME) ../bin/$(APP_NAME)
	rm -f ../bin/dialplan_config.txt



