.PHONY: deps all clean config

all:
	@make -j`nproc` -s MAKEFLAGS= all_targets

include $(ENV_MAKE_DIR)/inc.conf.mk
-include $(OUT_PATH)/.config
-include auto.mk


clean: cleanconfig $(ALL_CLEAN_TARGETS)
	-rm -rf auto.mk Kconfig Target DEPS depends

deps:
	@python3 $(ENV_TOOL_DIR)/gen_build_chain.py -m auto.mk -k Kconfig -t Target -a DEPS -d mk.deps -c mk.kconf -s pa:pb:pc:pd:pe:pf

%-deps:
	@$(ENV_TOOL_DIR)/gen_depends_image.sh $(patsubst %-deps,%,$@) depends DEPS $(OUT_PATH)/.config
