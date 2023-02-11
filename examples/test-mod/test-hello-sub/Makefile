PACKAGE_NAME ?= test-hello-sub
INSTALL_HEADERS ?= hello_sub.h

all: modules
	@echo "Build $(PACKAGE_NAME) Done."

clean: modules_clean
	@echo "Clean $(PACKAGE_NAME) Done."

install: modules_install install_hdrs

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.mod.mk
include $(ENV_MAKE_DIR)/inc.ins.mk
