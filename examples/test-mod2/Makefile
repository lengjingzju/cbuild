$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_op hello_sec
hello_op-objs = hello_main.o hello_add.o hello_sub.o hello_mul.o hello_div.o

else

PACKAGE_NAME ?= test-mod2

all: modules

clean: modules_clean

ifneq ($(ENV_BUILD_MODE), yocto)
all: install
endif
install: modules_install

endif

include $(ENV_TOP_DIR)/scripts/inc.mod.mk
