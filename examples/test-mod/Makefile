.PHONY: deps all clean

all:

include $(ENV_TOP_DIR)/scripts/core/inc.conf.mk
-include $(OUT_PATH)/.config
-include auto.mk

all: $(ALL_TARGETS)

clean: cleanconfig $(ALL_CLEAN_TARGETS)
	-rm -f auto.mk Kconfig

deps:
	@python3 $(ENV_TOP_DIR)/scripts/bin/analyse_deps.py -m auto.mk -k Kconfig -f mk.deps -d test-hello:test-hello-add:test-hello-sub
