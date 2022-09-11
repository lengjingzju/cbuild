.PHONY: deps all clean config

all:

include $(ENV_TOP_DIR)/scripts/core/inc.conf.mk
-include $(OUT_PATH)/.config
-include auto.mk

all: all_targets

clean: cleanconfig $(ALL_CLEAN_TARGETS)
	-rm -f auto.mk Kconfig Target

deps:
	@python3 $(ENV_TOP_DIR)/scripts/bin/analyse_deps.py -m auto.mk -k Kconfig -d mk.deps -c mk.kconf -s pa:pb:pc:pd:pe

