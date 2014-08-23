
LIB_SRC_FILES = fs_ivr.lua \
		fs_logging.lua \
		fs_recite.lua \
		fs_sounds.lua \
		obj_dialstring.lua \
		obj_destination.lua \
		obj_route.lua \
		obj_route_ctrl.lua \
		obj_gateway.lua \
		obj_gateway_ctrl.lua \
		obj_location.lua \
		obj_location_ctrl.lua \
		obj_number.lua \
		obj_number_NANPA.lua \
		obj_source.lua

LIB_NAME = lib_fs

all: 
	luac -o $(LIB_NAME) $(LIB_SRC_FILES)
	cp $(LIB_NAME) ../lib

install:

clean:
	rm -f $(LIB_NAME) ../lib/$(LIB_NAME) ../lib/$(LIB_NAME).inspect.lua
	rm -f $(LIB_NAME).inspect.lua ../lib/$(LIB_NAME).inspect.lua

inspect:
	rm -f $(LIB_NAME).inspect.lua ../lib/$(LIB_NAME).inspect.lua
	cat $(LIB_SRC_FILES) > $(LIB_NAME).inspect.lua
	cp $(LIB_NAME).inspect.lua ../lib

