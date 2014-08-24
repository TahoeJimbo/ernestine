
APP_NAME = voicemail

APP_SOURCE_FILES = vm_box_menu.lua vm_main_menu.lua voicemail_main.lua
APP_HEADER_FILES = ../DEBUG.lua ../CONFIGURATION.lua 
APP_LIBS = ../lib/lib_fs ../lib/lib_lua ../lib/lib_parser ../lib/lib_voicemail

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

