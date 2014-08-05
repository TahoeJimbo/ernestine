
APP_NAME = voicemail_cli

APP_SOURCE_FILES = voicemail_cli.lua
APP_LIBS = ../CONFIGURATION.lua ../compatibility_shim.lua ../lib/lib_fs ../lib/lib_lua ../lib/lib_voicemail

all:
	luac -o $(APP_NAME) $(APP_LIBS) $(APP_SOURCE_FILES)

install:
	cp $(APP_NAME) ../bin

clean:
	rm -f $(APP_NAME) ../bin/$(APP_NAME)


