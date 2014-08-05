
APP_NAME = voicemail

APP_SOURCE_FILES = voicemail_main.lua
APP_LIBS = ../CONFIGURATION.lua ../lib/lib_fs ../lib/lib_lua ../lib/lib_voicemail

all:
	luac -o $(APP_NAME) $(APP_LIBS) $(APP_SOURCE_FILES)

install:
	cp $(APP_NAME) ../bin

clean:
	rm -f $(APP_NAME) ../bin/$(APP_NAME)


