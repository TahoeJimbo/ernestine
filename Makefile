
TARGETS = lib_fs lib_lua lib_voicemail lib_unit_test lib_parser \
	  app_dialplan app_voicemail app_voicemail_cli app_unit_tests app_ivr_chaos

FREESWITCH = /usr/local/freeswitch

FS_INSTALL_TARGETS = dialplan dialplan_config.txt \
		     voicemail \
		     voicemail_cli \
		     ivr_chaos \
		     helper

all: targets install

targets:
	@echo "Building:"
	@for DIR in ${TARGETS} ; do \
	echo "   $${DIR}" ; \
	make -s -C $${DIR} || exit 1 ; \
	done

	@echo ""
	@echo "Running unit-tests:"
	@lua app_unit_tests/unit_tests || exit 1
	@echo "   Checking dialplan configuration file syntax"
	@lua app_dialplan/sa-dialplan SYNTAX app_dialplan/dialplan_config.txt || exit 1
	@echo ""

clean:
	@echo "Cleaning:"
	@for DIR in ${TARGETS} ; do \
	echo "   $${DIR}" ; \
	make -s -C $${DIR} clean ; \
	done
	@echo ""

install:
	@echo "Installing:"
	@for DIR in ${TARGETS} ; do \
	echo "   $${DIR}" ; \
	make -s -C $${DIR} install || exit 1; \
	done
	@echo ""
	@echo "Staging:"
	@for FS_TARGET in ${FS_INSTALL_TARGETS} ; do \
	echo "   $${FS_TARGET}" ; \
	cp bin/$${FS_TARGET} ${FREESWITCH}/scripts ; \
	done
	@echo ""


# This target builds a monolithic file of all the source
# so a static semantic checking tool (lua-inspect) can process it
# and ferret out unused variables, shadowed globals variables, etc.

LUA_INSPECT_OUTPUT = /home/jim/Desktop/lua-inspect-master
LUA_INSPECT = $(LUA_INSPECT_OUTPUT)/luainspect

LUA_INSPECT_ARGS = -fhtml -lhtmllib

LUA_APP_TARGETS = dialplan voicemail voicemail_cli unit_tests ivr_chaos

inspect: targets
	@echo "Building inspection files for source analysis tools:"
	@for DIR in ${TARGETS} ; do \
	echo "   $${DIR}" ; \
	make -s -C $${DIR} inspect || exit 1 ; \
	done
	@for TARGET in ${LUA_APP_TARGETS} ; do \
	echo -n "   Inspection file for $${TARGET}..." ; \
	rm -f ${LUA_INSPECT_OUTPUT}/$${TARGET}.html ; \
	${LUA_INSPECT} ${LUA_INSPECT_ARGS} app_$${TARGET}/$${TARGET}.inspect.lua \
		 > ${LUA_INSPECT_OUTPUT}/$${TARGET}.html ; \
	echo "done" ; \
	done

