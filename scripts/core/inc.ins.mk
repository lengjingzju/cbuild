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
	@cp -rfp $(INSTALL_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private
endif
endif

ifneq ($(INSTALL_LIBRARIES), )
install_libs:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@install $(INSTALL_LIBRARIES) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(INSTALL_BINARIES), )
install_bins:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@install $(INSTALL_BINARIES) $(ENV_INS_ROOT)/usr/bin
endif

ifneq ($(INSTALL_DATAS), )
install_datas:
	@install -d $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
	@cp -rfp $(INSTALL_DATAS) $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
endif

