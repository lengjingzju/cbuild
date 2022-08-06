ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_OUT_ROOT):")
else
OUT_PATH       ?= .
endif

.PHONY: install_hdrs install_libs install_bins

ifneq ($(INSTALL_HEADERS)$(INSTALL_PRIVATE_HEADERS), )
install_hdrs:
ifneq ($(INSTALL_HEADERS), )
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@cp -rfp $(INSTALL_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
endif
ifneq ($(INSTALL_PRIVATE_HEADERS), )
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private
	@cp -rfp $(INSTALL_PRIVATE_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private
endif
endif

ifneq ($(INSTALL_LIBRARIES), )
install_libs:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@cp -rf $(INSTALL_LIBRARIES) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(INSTALL_BINARIES), )
install_bins:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@cp -rf $(INSTALL_BINARIES) $(ENV_INS_ROOT)/usr/bin
endif

ifneq ($(INSTALL_DATAS), )
install_datas:
	@install -d $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
	@cp -rf $(INSTALL_DATAS) $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
endif

install_datas_%:
	@isrc="$(patsubst $(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@))),,$(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		idst=$(ENV_INS_ROOT)/usr/share$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@))); \
		install -d $${idst} && cp -f $${isrc} $${idst}

install_todirs_%:
	@isrc="$(patsubst $(lastword $(INSTALL_TODIRS_$(patsubst install_todirs_%,%,$@))),,$(INSTALL_TODIRS_$(patsubst install_todirs_%,%,$@)))"; \
		idst=$(ENV_INS_ROOT)$(lastword $(INSTALL_TODIRS_$(patsubst install_todirs_%,%,$@))); \
		install -d $${idst} && cp -f $${isrc} $${idst}

install_tofiles_%:
	@isrc=$(word 1,$(INSTALL_TOFILES_$(patsubst install_tofiles_%,%,$@))); \
		idst=$(ENV_INS_ROOT)$(word 2,$(INSTALL_TOFILES_$(patsubst install_tofiles_%,%,$@))); \
		install -d $(dir $(ENV_INS_ROOT)$(word 2,$(INSTALL_TOFILES_$(patsubst install_tofiles_%,%,$@)))) && cp -f $${isrc} $${idst}

