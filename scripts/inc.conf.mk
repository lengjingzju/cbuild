ifeq ($(USING_EXT_BUILD), y)
OUT_PATH         ?= $(shell pwd | sed 's:$(ENV_TOP_DIR):$(ENV_TOP_OUT):')
CONF_PATH        ?= $(ENV_TOP_OUT)/scripts/kconfig
else
OUT_PATH         ?= .
CONF_PATH        ?= $(ENV_TOP_DIR)/scripts/kconfig
endif

CONF_SRC         ?= $(ENV_TOP_DIR)/scripts/kconfig
KCONFIG          ?= Kconfig
CONF_SAVE_PATH   ?= config

.PHONY: buildconfig menuconfig cleanconfig

CONFIG_PATH       = $(OUT_PATH)/.config
AUTOCONFIG_PATH   = $(OUT_PATH)/autoconfig/auto.conf
AUTOHEADER_PATH   = $(OUT_PATH)/config.h
CONF_OPTIONS      = $(KCONFIG) --configpath $(CONFIG_PATH) \
					--autoconfigpath $(AUTOCONFIG_PATH) \
					--autoheaderpath $(AUTOHEADER_PATH)

define gen_config_header
	sed -e 's/^# \(.*\) is not set$$/#define \1\t0/g' \
		-e 's/^\(.*\)=y$$/#define \1\t1/g' \
		-e 's/^\(.*\)=m$$/#define \1\t1/g' \
		-e 's/^\(.*\)=\([^ym].*\)$$/#define \1\t\2/g' \
		$(CONFIG_PATH) | grep "^#define"> $(AUTOHEADER_PATH)
endef

buildconfig:
	@make -C $(CONF_SRC)

cleanconfig:
	@make -C $(CONF_SRC) clean
	@rm -rf $(CONFIG_PATH) $(CONFIG_PATH).old $(dir $(AUTOCONFIG_PATH)) $(AUTOHEADER_PATH)

menuconfig: buildconfig
	@-mkdir -p $(OUT_PATH)
	@$(CONF_PATH)/mconf $(CONF_OPTIONS)
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --silent --oldconfig

%_config: $(CONF_SAVE_PATH)/%_config buildconfig
	@-mkdir -p $(OUT_PATH)
	@cp -f $< $(CONFIG_PATH)
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --defconfig $<
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --silent --oldconfig

%_saveconfig: $(CONFIG_PATH) buildconfig
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --savedefconfig=$(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)
	@echo Save .config to $(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)

