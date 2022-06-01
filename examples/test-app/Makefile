PACKAGE_NAME ?= test-app

BIN_NAME = test
LIB_NAME_A = libtest.a
LIB_NAME_SO = libtest.so
INSTALL_HEADERS = include/add.h include/sub.h

.PHONY: all clean install

all clean install:

include $(ENV_TOP_DIR)/scripts/core/inc.app.mk
include $(ENV_TOP_DIR)/scripts/core/inc.ins.mk

all: $(OUT_PATH)/$(LIB_NAME_A) $(OUT_PATH)/$(LIB_NAME_SO) $(OUT_PATH)/$(BIN_NAME)
	@echo "Build $(PACKAGE_NAME) Done."

clean: clean_objs
	@rm -f $(OUT_PATH)/$(LIB_NAME_A) $(OUT_PATH)/$(LIB_NAME_SO) $(OUT_PATH)/$(BIN_NAME)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_liba install_libso install_bin install_hdrs
