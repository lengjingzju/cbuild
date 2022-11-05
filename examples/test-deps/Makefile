.PHONY: deps all clean config

all:
	@make -j`nproc` -s MAKEFLAGS= all_targets

include $(ENV_TOP_DIR)/scripts/core/inc.conf.mk
-include $(OUT_PATH)/.config
-include auto.mk


clean: cleanconfig $(ALL_CLEAN_TARGETS)
	-rm -f auto.mk Kconfig Target

deps:
	@python3 $(ENV_TOP_DIR)/scripts/bin/gen_build_chain.py -m auto.mk -k Kconfig -t Target -d mk.deps -c mk.kconf -s pa:pb:pc:pd:pe

