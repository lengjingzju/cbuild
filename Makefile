############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

OUT_PATH       := $(ENV_CFG_ROOT)
KCONFIG        := $(OUT_PATH)/Kconfig
CONF_SAVE_PATH := $(ENV_TOP_DIR)/configs
CONF_HEADER    := __CBUILD_GLOBAL_CONFIG__
DEF_CONFIG     := default_config

IGNORE_DIRS    := .git:.svn:scripts:output:configs:examples:notes
KEYWORDS       := none
MAXLEVEL       := 3
TIME_FORMAT    := /usr/bin/time -a -o $(OUT_PATH)/time_statistics -f \"%e\\t\\t%U\\t\\t%S\\t\\t\$$@\"

.PHONY: all clean insclean distclean toolchain deps all-deps total_time time_statistics

all: loadconfig
	@make $(ENV_BUILD_JOBS) $(ENV_MAKE_FLAGS) MAKEFLAGS= all_targets
	@echo "Build done!"

-include $(OUT_PATH)/.config
-include $(OUT_PATH)/auto.mk
-include $(ENV_MAKE_DIR)/inc.conf.mk

clean:
	@rm -rf $(ENV_OUT_ROOT)
	@echo "Clean Done."

insclean:
	@$(PRECMD)rm -rf $(ENV_INS_ROOT)
	@echo "Install Clean Done."

distclean:
	@rm -rf $(ENV_TOP_OUT)
	@echo "Distclean Done."

deps:
	@mkdir -p $(OUT_PATH)
	@$(PRECMD)python3 $(ENV_TOOL_DIR)/gen_build_chain.py -m $(OUT_PATH)/auto.mk -k $(OUT_PATH)/Kconfig \
		-t $(OUT_PATH)/Target -a $(OUT_PATH)/DEPS -d mk.deps -v mk.vdeps -c mk.kconf \
		-s $(ENV_TOP_DIR) -i $(IGNORE_DIRS) -l $(MAXLEVEL) -w $(KEYWORDS)

toolchain:
	@$(PRECMD)make -C $(ENV_TOP_DIR)/scripts/toolchain

buildkconfig: deps

%-deps:
	@$(ENV_TOOL_DIR)/gen_depends_image.sh $(patsubst %-deps,%,$@) $(OUT_PATH)/depends $(OUT_PATH)/DEPS  $(OUT_PATH)/.config

all-deps:
	@for package in $$(cat $(OUT_PATH)/DEPS  | cut -d = -f 1); do \
		$(ENV_TOOL_DIR)/gen_depends_image.sh $${package} $(OUT_PATH)/depends $(OUT_PATH)/DEPS  $(OUT_PATH)/.config; \
	done

total_time: loadconfig
	@$(PRECMD)make $(ENV_MAKE_FLAGS) all_targets
	@echo "Build done!"

time_statistics:
	@mkdir -p $(OUT_PATH)
	@$(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e) "real\t\tuser\t\tsys\t\tpackage" > $(OUT_PATH)/$@
	@make $(ENV_MAKE_FLAGS) PRECMD="$(TIME_FORMAT) " total_time
