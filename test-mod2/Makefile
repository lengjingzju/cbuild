$(info KERNELRELEASE=$(KERNELRELEASE) pwd=$(shell pwd) PWD=$(PWD))

ifneq ($(KERNELRELEASE),)
MOD_NAME = hello_op hello
hello_op-objs = hello_main.o hello_add.o hello_sub.o hello_mul.o hello_div.o

else

all: modules

clean: modules_clean

endif

include $(ENV_TOP_DIR)/scripts/inc.mod.mk
