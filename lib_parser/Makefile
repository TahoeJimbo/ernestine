
LIB_SRC_FILES = obj_parse.lua

LIB_NAME = lib_parser

all: 
	luac -o $(LIB_NAME) $(LIB_SRC_FILES)
	cp $(LIB_NAME) ../lib

install:

clean:
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME)
	rm -f $(LIB_NAME).inspect.lua ../lib/$(LIB_NAME).inspect.lua

inspect:
	rm -f $(LIB_NAME).inspect.lua ../lib/$(LIB_NAME).inspect.lua
	cat $(LIB_SRC_FILES) > $(LIB_NAME).inspect.lua
	cp $(LIB_NAME).inspect.lua ../lib

