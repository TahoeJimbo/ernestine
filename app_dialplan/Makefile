
APP_NAME = dialplan

APP_SOURCE_FILES = dialplan_inbound.lua dialplan_outbound.lua dialplan_main.lua
APP_HEADER_FILES = ../DEBUG.lua ../CONFIGURATION.lua
APP_LIBS = ../lib/lib_fs ../lib/lib_lua ../lib/lib_parser

all:
	luac -o $(APP_NAME) $(APP_HEADER_FILES) $(APP_LIBS) $(APP_SOURCE_FILES)
	luac -o sa-$(APP_NAME) ../compatibility_shim.lua $(APP_HEADER_FILES) \
				$(APP_LIBS) $(APP_SOURCE_FILES)

install:
	cp $(APP_NAME) ../bin
	cp dialplan_config.txt ../bin

clean:
	rm -f ../bin/dialplan_config.txt
	rm -f $(APP_NAME) ../bin/$(APP_NAME)
	rm -f $(APP_NAME).inspect.lua

inspect:
	rm -f $(APP_NAME).inspect.lua
	cat ../compatibility_shim.lua $(APP_HEADER_FILES) >> $(APP_NAME).inspect.lua
	@for FILE in ${APP_LIBS} ; do \
	cat $${FILE}.inspect.lua >> $(APP_NAME).inspect.lua ; \
	done
	@cat $(APP_SOURCE_FILES) >> $(APP_NAME).inspect.lua



