
TARGETS = lib_fs lib_lua lib_voicemail lib_unit_test \
	  app_dialplan app_voicemail app_voicemail_cli app_unit_tests app_ivr_chaos

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
	make -s -C $${DIR} ; \
	done

	@echo ""
	@echo "Running unit-tests:"
	@lua app_unit_tests/unit_tests
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
	make -s -C $${DIR} install ; \
	done
	@echo ""
	@echo "Staging:"
	@for FS_TARGET in ${FS_INSTALL_TARGETS} ; do \
	echo "   $${FS_TARGET}" ; \
	cp bin/$${FS_TARGET} /fs/scripts ; \
	done
	@echo ""


