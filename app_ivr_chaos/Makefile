
APP_NAME = ivr_chaos

APP_SOURCE_FILES = ivr_chaos.lua
APP_LIBS = ../lib/lib_fs ../lib/lib_lua

all:
	luac -o $(APP_NAME) $(APP_LIBS) $(APP_SOURCE_FILES)

install:
	cp $(APP_NAME) ../bin

clean:
	rm -f $(APP_NAME) ../bin/$(APP_NAME)


