ifneq ($(KERNELRELEASE),)

MOD_NAME       ?= hello
obj-m          := $(patsubst %,%.o,$(MOD_NAME))

ifneq ($(PACKAGE_DEPS), )
ccflags-y      += $(patsubst %,-I$(ENV_DEP_ROOT)%,/usr/include/ /usr/local/include/)
ccflags-y      += $(patsubst %,-I$(ENV_DEP_ROOT)/usr/include/%/,$(PACKAGE_DEPS))
endif

ifeq ($(words $(MOD_NAME)), 1)

SRCS           ?= $(shell find $(src) -name "*.c" | grep -v "scripts/" | grep -v "\.mod\.c" | xargs)
OBJS            = $(patsubst $(src)/%,%,$(patsubst %.c,%.o,$(SRCS)))
ifneq ($(words $(OBJS))-$(OBJS), 1-$(MOD_NAME).o)
$(MOD_NAME)-y  := $(OBJS)
endif

else

# If multiple modules are compiled at the same time, user should
# set objs under every module himself.

endif

########################################

else

KERNEL_SRC     ?= /lib/modules/$(shell uname -r)/build
MOD_MAKES      += $(BUILD_JOBS) -s -C $(KERNEL_SRC) $(if $(KERNEL_OUT),O=$(KERNEL_OUT))

ifeq ($(findstring $(ENV_BUILD_MODE),external yocto),)

MOD_MAKES      += M=$(shell pwd)

else

OUT_PATH       ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_OUT_ROOT):")
MOD_MAKES      += M=$(OUT_PATH) src=$(shell pwd)
KBUILD_MK       = $(if $(wildcard Kbuild),Kbuild,Makefile)

modules modules_clean modules_install: $(OUT_PATH)/$(KBUILD_MK)

$(OUT_PATH)/$(KBUILD_MK): $(KBUILD_MK)
	@-mkdir -p $(dir $@)
	@-cp -f $< $@

#
# Note:
# Users should copy the Kbuild or Makefile to avoid compilation failures.
# If they don't want to copy it, they should modify the
# "$(KERNEL_SRC)/scripts/Makefile.modpost" as follow:
#   -include $(if $(wildcard $(KBUILD_EXTMOD)/Kbuild), \
#   -             $(KBUILD_EXTMOD)/Kbuild, $(KBUILD_EXTMOD)/Makefile)
#   +include $(if $(wildcard $(src)/Kbuild), $(src)/Kbuild, $(src)/Makefile)
#

endif

export PACKAGE_DEPS ENV_DEP_ROOT

modules:
	@make $(MOD_MAKES) $(if $(PACKAGE_DEPS), KBUILD_EXTRA_SYMBOLS="$(patsubst %,$(ENV_DEP_ROOT)/usr/include/%/Module.symvers,$(patsubst %/private,,$(PACKAGE_DEPS)))") modules

modules_clean:
	@make $(MOD_MAKES) clean

modules_install:
	@make $(MOD_MAKES) $(if $(ENV_INS_ROOT), INSTALL_MOD_PATH=$(ENV_INS_ROOT)) modules_install

ifneq ($(INSTALL_HEADERS)$(INSTALL_PRIVATE_HEADERS), )
modules_install_hdrs:
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@cp -fp $(OUT_PATH)/Module.symvers $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
ifneq ($(INSTALL_HEADERS), )
	@cp -rfp $(INSTALL_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
endif
ifneq ($(INSTALL_PRIVATE_HEADERS), )
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private
	@cp -rfp $(INSTALL_PRIVATE_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private
endif
endif

endif
