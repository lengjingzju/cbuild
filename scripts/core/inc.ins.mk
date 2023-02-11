############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

ifeq ($(KERNELRELEASE), )

.PHONY: install_libs install_base_libs install_bins install_base_bins install_hdrs install_datas

install_libs:
	@install -d $(INS_PREFIX)/usr/lib
	@$(call safe_copy,-drf,$(INSTALL_LIBRARIES) $(INS_PREFIX)/usr/lib)

INSTALL_BASE_LIBRARIES ?= $(INSTALL_LIBRARIES)
install_base_libs:
	@install -d $(INS_PREFIX)/lib
	@$(call safe_copy,-drf,$(INSTALL_BASE_LIBRARIES) $(INS_PREFIX)/lib)

install_bins:
	@install -d $(INS_PREFIX)/usr/bin
	@$(call safe_copy,-drf,$(INSTALL_BINARIES) $(INS_PREFIX)/usr/bin)

INSTALL_BASE_BINARIES ?= $(INSTALL_BINARIES)
install_base_bins:
	@install -d $(INS_PREFIX)/bin
	@$(call safe_copy,-drf,$(INSTALL_BASE_BINARIES) $(INS_PREFIX)/bin)

install_hdrs:
	@install -d $(INS_PREFIX)/usr/include/$(INSTALL_HDR)
	@$(call safe_copy,-drfp,$(INSTALL_HEADERS) $(INS_PREFIX)/usr/include/$(INSTALL_HDR))

install_datas:
	@install -d $(INS_PREFIX)/usr/share
	@$(call safe_copy,-drf,$(INSTALL_DATAS) $(INS_PREFIX)/usr/share)

install_datas_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))),-drfp,-drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@))),,$(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		idst="$(INS_PREFIX)/usr/share$(lastword $(INSTALL_DATAS_$(patsubst install_datas_%,%,$@)))"; \
		install -d $${idst} && $(call safe_copy,$${icp},$${isrc} $${idst})

install_todir_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))),-drfp,-drf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@))),,$(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		idst="$(INS_PREFIX)$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		install -d $${idst} && $(call safe_copy,$${icp},$${isrc} $${idst})

install_tofile_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))),-dfp,-df)"; \
		isrc="$(word 1,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		idst="$(INS_PREFIX)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		install -d $(dir $(INS_PREFIX)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))) && $(call safe_copy,$${icp},$${isrc} $${idst})

endif
