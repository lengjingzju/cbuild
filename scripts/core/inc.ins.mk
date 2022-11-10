ifeq ($(KERNELRELEASE), )

.PHONY: install_libs install_base_libs install_bins install_base_bins install_hdrs install_datas

define safe_cp
$(if $(filter yocto,$(ENV_BUILD_MODE)),cp $1 $2,flock $(ENV_INS_ROOT) -c "cp $1 $2")
endef

install_libs:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@$(call safe_cp,-drf,$(INSTALL_LIBRARIES) $(ENV_INS_ROOT)/usr/lib)

INSTALL_BASE_LIBRARIES ?= $(INSTALL_LIBRARIES)
install_base_libs:
	@install -d $(ENV_INS_ROOT)/lib
	@$(call safe_cp,-drf,$(INSTALL_BASE_LIBRARIES) $(ENV_INS_ROOT)/lib)

install_bins:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@$(call safe_cp,-drf,$(INSTALL_BINARIES) $(ENV_INS_ROOT)/usr/bin)

INSTALL_BASE_BINARIES ?= $(INSTALL_BINARIES)
install_base_bins:
	@install -d $(ENV_INS_ROOT)/bin
	@$(call safe_cp,-drf,$(INSTALL_BASE_BINARIES) $(ENV_INS_ROOT)/bin)

install_hdrs:
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@$(call safe_cp,-drfp,$(INSTALL_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME))

install_datas:
	@install -d $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
	@$(call safe_cp,-drf,$(INSTALL_DATAS) $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME))

install_datas_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))),-drfp,-drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@))),,$(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)/usr/share$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		install -d $${idst} && $(call safe_cp,$${icp},$${isrc} $${idst})

install_todir_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))),-drfp,-drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@))),,$(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		install -d $${idst} && $(call safe_cp,$${icp},$${isrc} $${idst})

install_tofile_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))),-dfp,-df)"; \
		isrc="$(word 1,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		install -d $(dir $(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))) && $(call safe_cp,$${icp},$${isrc} $${idst})

endif

