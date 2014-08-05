
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
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME)
	rm -f helper ../bin/helper


