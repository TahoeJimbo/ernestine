
LIB_SRC_FILES = fs_ivr.lua \
		fs_logging.lua \
		fs_recite.lua \
		fs_sounds.lua \
		obj_dialstring.lua \
		obj_destination.lua

LIB_NAME = lib_fs

all: 
	luac -o $(LIB_NAME) $(LIB_SRC_FILES)
	cp $(LIB_NAME) ../lib

install:

clean:
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME)

