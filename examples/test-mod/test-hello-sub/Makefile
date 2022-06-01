$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_sub

else

PACKAGE_NAME ?= test-hello-sub
INSTALL_HEADERS ?= hello_sub.h

all: modules
	@echo "Build $(PACKAGE_NAME) Done."

clean: modules_clean
	@echo "Clean $(PACKAGE_NAME) Done."

install: modules_install modules_install_hdrs

endif

include $(ENV_TOP_DIR)/scripts/core/inc.mod.mk
