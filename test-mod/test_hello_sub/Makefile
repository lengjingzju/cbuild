$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_sub

else

all: modules

clean: modules_clean

endif

include $(ENV_TOP_DIR)/scripts/inc.mod.mk
