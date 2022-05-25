$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_add

else

PACKAGE_NAME ?= test-hello-add
INSTALL_HEADERS ?= hello_add.h

all: modules

clean: modules_clean

ifneq ($(ENV_BUILD_MODE), yocto)
all: install
endif
install: modules_install modules_install_hdrs

endif

include $(ENV_TOP_DIR)/scripts/inc.mod.mk
