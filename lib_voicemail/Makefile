
LIB_NAME = lib_voicemail
LIB_SRC_FILES = vm.lua \
		vm_box.lua \
		vm_box_menu.lua \
		vm_main_menu.lua \
		vm_cli.lua 

all: 
	luac -o $(LIB_NAME) $(LIB_SRC_FILES)
	cp $(LIB_NAME) ../lib
	cc -o helper helper.c

install:
	cp helper ../bin

clean:
	rm -f helper ../bin/helper
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME)
	rm -f $(LIB_NAME).inspect.lua ../lib/$(LIB_NAME).inspect.lua

inspect:
	rm -f $(LIB_NAME).inspect.lua ../lib/$(LIB_NAME).inspect.lua
	cat $(LIB_SRC_FILES) > $(LIB_NAME).inspect.lua
	cp $(LIB_NAME).inspect.lua ../lib

