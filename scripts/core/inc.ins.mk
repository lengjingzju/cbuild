ifeq ($(KERNELRELEASE), )

.PHONY: install_libs install_base_libs install_bins install_base_bins install_hdrs install_datas

install_libs:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@cp -drf $(INSTALL_LIBRARIES) $(ENV_INS_ROOT)/usr/lib

INSTALL_BASE_LIBRARIES ?= $(INSTALL_LIBRARIES)
install_base_libs:
	@install -d $(ENV_INS_ROOT)/lib
	@cp -drf $(INSTALL_BASE_LIBRARIES) $(ENV_INS_ROOT)/lib

install_bins:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@cp -drf $(INSTALL_BINARIES) $(ENV_INS_ROOT)/usr/bin

INSTALL_BASE_BINARIES ?= $(INSTALL_BINARIES)
install_base_bins:
	@install -d $(ENV_INS_ROOT)/bin
	@cp -drf $(INSTALL_BASE_BINARIES) $(ENV_INS_ROOT)/bin

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

install_todir_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))),cp -drfp,cp -drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@))),,$(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		install -d $${idst} && $${icp} $${isrc} $${idst}

install_tofile_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))),cp -dfp,cp -df)"; \
		isrc="$(word 1,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		install -d $(dir $(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))) && $${icp} $${isrc} $${idst}

endif
