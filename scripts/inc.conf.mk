CONF_SRC         ?= $(ENV_TOP_DIR)/scripts/kconfig
ifeq ($(ENV_BUILD_MODE), external)
CONF_PATH        ?= $(patsubst $(ENV_TOP_DIR)/%,$(ENV_TOP_OUT)/%,$(CONF_SRC))
OUT_PATH         ?= $(shell pwd | sed 's:$(ENV_TOP_DIR):$(ENV_TOP_OUT):')
else ifeq ($(ENV_BUILD_MODE), yocto)
CONF_PATH        ?= $(CONF_SRC)/oe-workdir
OUT_PATH         ?= .
else
CONF_PATH        ?= $(CONF_SRC)
OUT_PATH         ?= .
endif

KCONFIG          ?= Kconfig
CONF_SAVE_PATH   ?= config

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

ifneq ($(ENV_BUILD_MODE), yocto)

.PHONY: buildkconfig cleankconfig

buildkconfig:
	@make -C $(CONF_SRC)

cleankconfig:
	@make -C $(CONF_SRC) clean

menuconfig: buildkconfig

%_config: buildkconfig

%_saveconfig: buildkconfig

cleanconfig: cleankconfig

endif

.PHONY: menuconfig cleanconfig

menuconfig:
	@-mkdir -p $(OUT_PATH)
	@$(CONF_PATH)/mconf $(CONF_OPTIONS)
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --silent --oldconfig

%_config: $(CONF_SAVE_PATH)/%_config
	@-mkdir -p $(OUT_PATH)
	@cp -f $< $(CONFIG_PATH)
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --defconfig $<
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --silent --oldconfig

%_saveconfig: $(CONFIG_PATH)
	@$(CONF_PATH)/conf $(CONF_OPTIONS) --savedefconfig=$(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)
	@echo Save .config to $(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)

cleanconfig:
	@rm -rf $(CONFIG_PATH) $(CONFIG_PATH).old $(dir $(AUTOCONFIG_PATH)) $(AUTOHEADER_PATH)
