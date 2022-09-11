ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(ENV_OUT_ROOT)/%,$(shell pwd))
else
OUT_PATH       ?= .
endif

.PHONY: install_libs install_bins install_hdrs install_datas

install_libs:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@cp -drf $(INSTALL_LIBRARIES) $(ENV_INS_ROOT)/usr/lib

install_bins:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@cp -drf $(INSTALL_BINARIES) $(ENV_INS_ROOT)/usr/bin

install_hdrs:
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@cp -drfp $(INSTALL_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)

install_datas:
	@install -d $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
	@cp -drf $(INSTALL_DATAS) $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)

install_datas_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))),cp -drfp,cp -drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@))),,$(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)/usr/share$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		install -d $${idst} && $${icp} $${isrc} $${idst}

install_todirs_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TODIRS_$(patsubst install_todirs_%,%,$@)))),cp -drfp,cp -drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_TODIRS_$(patsubst install_todirs_%,%,$@))),,$(INSTALL_TODIRS_$(patsubst install_todirs_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TODIRS_$(patsubst install_todirs_%,%,$@)))"; \
		install -d $${idst} && $${icp} $${isrc} $${idst}

install_tofiles_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TOFILES_$(patsubst install_tofiles_%,%,$@)))),cp -dfp,cp -df)"; \
		isrc="$(word 1,$(INSTALL_TOFILES_$(patsubst install_tofiles_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILES_$(patsubst install_tofiles_%,%,$@)))"; \
		install -d $(dir $(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILES_$(patsubst install_tofiles_%,%,$@)))) && $${icp} $${isrc} $${idst}

