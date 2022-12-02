CONF_SRC         ?= $(ENV_TOP_DIR)/scripts/kconfig
ifeq ($(ENV_BUILD_MODE), external)
CONF_PATH        ?= $(patsubst $(ENV_TOP_DIR)/%,$(ENV_OUT_ROOT)/%,$(CONF_SRC))
OUT_PATH         ?= $(patsubst $(ENV_TOP_DIR)/%,$(ENV_OUT_ROOT)/%,$(shell pwd))
else ifeq ($(ENV_BUILD_MODE), yocto)
CONF_PATH        ?= $(CONF_SRC)/oe-workdir/build
OUT_PATH         ?= .
else
CONF_PATH        ?= $(CONF_SRC)
OUT_PATH         ?= .
endif

KCONFIG          ?= Kconfig
CONF_SAVE_PATH   ?= config
CONF_PREFIX      ?= srctree=$(shell pwd)
CONF_HEADER      ?= $(shell echo __$(PACKAGE_NAME)_CONFIG_H__ | tr '[:lower:]' '[:upper:]')
CONF_APPEND_CMD  ?=

CONFIG_PATH       = $(OUT_PATH)/.config
AUTOCONFIG_PATH   = $(OUT_PATH)/autoconfig/auto.conf
AUTOHEADER_PATH   = $(OUT_PATH)/config.h
CONF_OPTIONS      = $(KCONFIG) --configpath $(CONFIG_PATH) \
					--autoconfigpath $(AUTOCONFIG_PATH) \
					--autoheaderpath $(AUTOHEADER_PATH)

define gen_config_header
	$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --silent --syncconfig && \
		sed -i -e "1 i #ifndef $(CONF_HEADER)" -e "1 i #define $(CONF_HEADER)" -e '1 i \\' \
		-e '$$ a \\' -e "\$$ a #endif" $(AUTOHEADER_PATH) && \
		$(if $(CONF_APPEND_CMD),$(CONF_APPEND_CMD),:)
endef

define sync_config_header
	if [ -e $(CONFIG_PATH) ]; then \
		if [ -e $(AUTOHEADER_PATH) ]; then \
			if [ $$(stat -c %Y $(CONFIG_PATH)) -gt $$(stat -c %Y $(AUTOHEADER_PATH)) ]; then \
				$(call gen_config_header); \
			fi; \
		else \
			$(call gen_config_header); \
		fi; \
	fi
endef

.PHONY: buildkconfig cleankconfig menuconfig loadconfig cleanconfig

ifneq ($(ENV_BUILD_MODE), yocto)

buildkconfig:
	@make -s -C $(CONF_SRC)

cleankconfig:
	@make -s -C $(CONF_SRC) clean

else

buildkconfig:
	@do_thing=none

cleankconfig:
	@do_thing=none
endif

menuconfig: buildkconfig
	@-mkdir -p $(OUT_PATH)
	@mtime="$(if $(wildcard $(CONFIG_PATH)),$(if $(wildcard $(AUTOHEADER_PATH)),$$(stat -c %Y $(CONFIG_PATH)),0),0)"; \
		$(CONF_PREFIX) $(CONF_PATH)/mconf $(CONF_OPTIONS); \
		if [ "$${mtime}" != "$$(stat -c %Y $(CONFIG_PATH))" ]; then \
			$(call gen_config_header); \
		else \
			$(call sync_config_header); \
		fi

ifneq ($(DEF_CONFIG), )
loadconfig: buildkconfig
	@-mkdir -p $(OUT_PATH)
	@if [ ! -e $(AUTOHEADER_PATH) ]; then \
		if [ ! -e $(CONFIG_PATH) ]; then \
			cp -f $(CONF_SAVE_PATH)/$(DEF_CONFIG) $(CONFIG_PATH); \
		fi; \
		$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --defconfig $(CONF_SAVE_PATH)/$(DEF_CONFIG); \
		$(call gen_config_header); \
	else \
		$(call sync_config_header); \
	fi
endif

syncconfig:
	@$(call sync_config_header)

%_config: $(CONF_SAVE_PATH)/%_config buildkconfig
	@-mkdir -p $(OUT_PATH)
	@cp -f $< $(CONFIG_PATH)
	@$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --defconfig $<
	@$(call gen_config_header)

%_defconfig: $(CONF_SAVE_PATH)/%_defconfig buildkconfig
	@-mkdir -p $(OUT_PATH)
	@cp -f $< $(CONFIG_PATH)
	@$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --defconfig $<
	@$(call gen_config_header)

%_saveconfig: $(CONFIG_PATH) buildkconfig
	@$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --savedefconfig=$(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)
	@echo Save .config to $(CONF_SAVE_PATH)/$(subst _saveconfig,_config,$@)

%_savedefconfig: $(CONFIG_PATH) buildkconfig
	@$(CONF_PREFIX) $(CONF_PATH)/conf $(CONF_OPTIONS) --savedefconfig=$(CONF_SAVE_PATH)/$(subst _savedefconfig,_defconfig,$@)
	@echo Save .config to $(CONF_SAVE_PATH)/$(subst _savedefconfig,_defconfig,$@)

cleanconfig: cleankconfig
	@rm -rf $(CONFIG_PATH) $(CONFIG_PATH).old $(dir $(AUTOCONFIG_PATH)) $(AUTOHEADER_PATH)

