$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello

else

PACKAGE_NAME ?= test-hello
PACKAGE_DEPS ?= test-hello-add test-hello-sub

all: modules

clean: modules_clean

ifneq ($(ENV_BUILD_MODE), yocto)
all: install
endif
install: modules_install
endif

include $(ENV_TOP_DIR)/scripts/inc.mod.mk
