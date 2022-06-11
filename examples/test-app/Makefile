PACKAGE_NAME ?= test-app

BIN_NAME = test
LIBA_NAME = libtest.a
LIBSO_NAME = libtest.so
INSTALL_HEADERS = include/add.h include/sub.h

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_TOP_DIR)/scripts/core/inc.app.mk
include $(ENV_TOP_DIR)/scripts/core/inc.ins.mk

all: $(LIB_TARGETS) $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS) $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_liba install_libso install_bin install_hdrs
