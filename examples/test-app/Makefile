PACKAGE_NAME ?= test-app

BIN_NAME = test
LIB_NAME_A = libtest.a
LIB_NAME_SO = libtest.so
INSTALL_HEADERS = include/add.h include/sub.h

.PHONY: all clean install

all clean install:

include $(ENV_TOP_DIR)/scripts/inc.app.mk

all: $(OUT_PATH)/$(LIB_NAME_A) $(OUT_PATH)/$(LIB_NAME_SO) $(OUT_PATH)/$(BIN_NAME)
	@echo "\033[32m---- build ok ----\033[0m"

clean: clean_objs
	@rm -f $(OUT_PATH)/$(LIB_NAME_A) $(OUT_PATH)/$(LIB_NAME_SO) $(OUT_PATH)/$(BIN_NAME)
	@echo "\033[32m---- clean ok ----\033[0m"

ifneq ($(ENV_BUILD_MODE), yocto)
all: install
endif
install: install_liba install_libso install_bin install_hdrs

