
APP_NAME = dialplan

APP_SOURCE_FILES = dialplan_inbound.lua dialplan_outbound.lua dialplan_main.lua
APP_LIBS = ../CONFIGURATION.lua ../lib/lib_fs ../lib/lib_lua ../location.lua

all:
	luac -o $(APP_NAME) $(APP_LIBS) $(APP_SOURCE_FILES)

install:
	cp $(APP_NAME) ../bin
	cp dialplan_config.txt ../bin

clean:
	rm -f $(APP_NAME) ../bin/$(APP_NAME)
	rm -f ../bin/dialplan_config.txt


