
LIB_SRC_FILES = unit_test_main.lua
LIB_NAME = lib_unit_test

all: 
	luac -o $(LIB_NAME) $(LIB_SRC_FILES)
	cp $(LIB_NAME) ../lib

install:

clean:
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME)

