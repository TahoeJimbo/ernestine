
APP_NAME = ivr_chaos

APP_SOURCE_FILES = ivr_chaos.lua
APP_HEADER_FILES = ../DEBUG.lua ../CONFIGURATION.lua
APP_LIBS = ../lib/lib_fs ../lib/lib_lua

all:
	luac -o $(APP_NAME) $(APP_HEADER_FILES) $(APP_LIBS) $(APP_SOURCE_FILES)

install:
	cp $(APP_NAME) ../bin

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


