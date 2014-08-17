
LIB_SRC_FILES = obj_parse_DEBUG.lua obj_parse.lua

LIB_NAME = lib_parser

all: 
	luac -o $(LIB_NAME) $(LIB_SRC_FILES)
	cp $(LIB_NAME) ../lib

install:

clean:
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME)

