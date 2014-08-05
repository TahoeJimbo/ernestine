
LIB_SRC_FILES = lua_execute.lua lua_files.lua lua_string.lua lua_tables.lua
LIB_NAME = lib_lua

all: 
	luac -o $(LIB_NAME) $(LIB_SRC_FILES)
	cp $(LIB_NAME) ../lib

install:

clean:
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME)
