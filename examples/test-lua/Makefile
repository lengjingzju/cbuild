PACKAGE_NAME = lua

include $(ENV_TOP_DIR)/scripts/core/inc.env.mk

VERSION             := 5.4.4
SRC_DNAME           := lua-$(VERSION)
SRC_FNAME           := $(SRC_DNAME).tar.gz
SRC_URL             := http://www.lua.org/ftp/$(SRC_FNAME)
INSTALL_PATH        := $(OUT_PATH)/image
PATCH_FOLDER        := $(shell pwd)/patches
FETCH_SCRIPT        := $(ENV_TOP_DIR)/scripts/bin/fetch_package.sh
PATCH_SCRIPT        := $(ENV_TOP_DIR)/scripts/bin/exec_patch.sh

MAKES               := make -s CC=$(CC) AR="$(AR) rcs" RANLIB="$(RANLIB) -D" \
                       INSTALL_TOP=$(INSTALL_PATH) INSTALL_DATA="cp -rfp" -C $(OUT_PATH)/$(SRC_DNAME)

INSTALL_HEADERS     := $(INSTALL_PATH)/include/*
INSTALL_LIBRARIES   := $(INSTALL_PATH)/lib/liblua.*
INSTALL_BINARIES    := $(INSTALL_PATH)/bin/*

.PHONY: all clean install

all:
	@$(FETCH_SCRIPT) tar $(SRC_URL) $(SRC_FNAME) $(OUT_PATH) $(SRC_DNAME)
	@$(PATCH_SCRIPT) patch $(PATCH_FOLDER) $(OUT_PATH)/$(SRC_DNAME)
	@$(MAKES) && $(MAKES) install
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_TOP_DIR)/scripts/core/inc.ins.mk

clean:
	@rm -rf $(OUT_PATH)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_hdrs install_libs install_bins
