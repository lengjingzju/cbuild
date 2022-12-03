$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_dep

else

PACKAGE_NAME ?= test-hello
PACKAGE_DEPS ?= test-hello-add test-hello-sub

all: modules
	@echo "Build $(PACKAGE_NAME) Done."

clean: modules_clean
	@echo "Clean $(PACKAGE_NAME) Done."

install: modules_install
endif

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.mod.mk
