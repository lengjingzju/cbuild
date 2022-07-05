.PHONY: deps all clean config

all:

include $(ENV_TOP_DIR)/scripts/core/inc.conf.mk
-include $(OUT_PATH)/.config
-include auto.mk

all: all_targets

clean: cleanconfig $(ALL_CLEAN_TARGETS)
	-rm -f auto.mk Kconfig
	@make -s -f params.mk clean

deps:
	@python3 $(ENV_TOP_DIR)/scripts/bin/analyse_deps.py -m auto.mk -k Kconfig -f mk.deps -d pa:pb:pc:pd:pe

config:
	@make -f params.mk
