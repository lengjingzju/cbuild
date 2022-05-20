$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello

else

ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_TOP_OUT):")
MOD_DEPS  = $(patsubst %,$(dir $(OUT_PATH))%,test_hello_add test_hello_sub)
else ifeq ($(ENV_BUILD_MODE), yocto)
MOD_DEPS  = $(shell realpath ../test_hello_add/oe-workdir ../test_hello_sub/oe-workdir | xargs)
else
MOD_DEPS  = $(shell realpath ../test_hello_add ../test_hello_sub | xargs)
endif

$(info MOD_DEPS=$(MOD_DEPS))

all: modules

clean: modules_clean

endif

include $(ENV_TOP_DIR)/scripts/inc.mod.mk
