PACKAGE_NAME ?= test-app

BIN_NAME = test
LIBA_NAME = libtest.a
LIBSO_NAME = libtest.so 1 2 3
INSTALL_HEADER = include/add.h include/sub.h

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_TOP_DIR)/scripts/core/inc.app.mk

all: $(LIB_TARGETS) $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS) $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_liba install_libso install_bin install_hdr
