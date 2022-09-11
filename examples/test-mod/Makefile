.PHONY: deps all clean

all:

include $(ENV_TOP_DIR)/scripts/core/inc.conf.mk
-include $(OUT_PATH)/.config
-include auto.mk

all: $(ALL_TARGETS)

clean: cleanconfig $(ALL_CLEAN_TARGETS)
	-rm -f auto.mk Kconfig Target

deps:
	@python3 $(ENV_TOP_DIR)/scripts/bin/analyse_deps.py -m auto.mk -k Kconfig -d mk.deps -c mk.kconf -s test-hello:test-hello-add:test-hello-sub
