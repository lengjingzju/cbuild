.PHONY: deps all clean

deps:
	@python3 $(ENV_TOP_DIR)/scripts/analyse_deps.py -m auto.mk -k Kconfig -f mk.deps -d test_hello:test_hello_add:test_hello_sub

include $(ENV_TOP_DIR)/scripts/inc.conf.mk
-include $(OUT_PATH)/.config
-include auto.mk

all: $(ALL_TARGETS)

clean: cleanconfig $(ALL_CLEAN_TARGETS)
	-rm -f auto.mk Kconfig

