PACKAGE_NAME ?= test-hello-sub
INSTALL_HEADER ?= hello_sub.h

all: modules
	@echo "Build $(PACKAGE_NAME) Done."

clean: modules_clean
	@echo "Clean $(PACKAGE_NAME) Done."

install: modules_install install_hdr

include $(ENV_TOP_DIR)/scripts/core/inc.mod.mk
