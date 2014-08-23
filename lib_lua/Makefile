
LIB_SRC_FILES = lua_execute.lua lua_files.lua lua_string.lua lua_tables.lua
LIB_NAME = lib_lua

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
