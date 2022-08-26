ifneq ($(KERNELRELEASE),)

MOD_NAME       ?= hello
obj-m          := $(patsubst %,%.o,$(MOD_NAME))

ccflags-y      += $(patsubst %,-I%/,$(src) $(src)/include $(obj))
ifneq ($(PACKAGE_DEPS), )
ccflags-y      += $(patsubst %,-I$(ENV_DEP_ROOT)%,/usr/include/ /usr/local/include/)
ccflags-y      += $(patsubst %,-I$(ENV_DEP_ROOT)/usr/include/%/,$(PACKAGE_DEPS))
endif

define translate_obj
$(patsubst $(src)/%,%,$(patsubst %,%.o,$(basename $(1))))
endef

define set_flags
$(foreach v,$(2),$(eval $(1)_$(call translate_obj,$(v)) = $(3)))
endef

ifeq ($(words $(MOD_NAME)), 1)

IGNORE_PATH    ?= .git scripts output
REG_SUFFIX     ?= c S
SRCS           ?= $(filter-out %.mod.c,$(shell find $(src) \
                          $(patsubst %,-path '*/%' -prune -o,$(IGNORE_PATH)) \
                          $(shell echo '$(patsubst %,-o -name "*.%" -print,$(REG_SUFFIX))' | sed 's/^...//') \
                     | xargs))
OBJS            = $(call translate_obj,$(SRCS))

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

OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(ENV_OUT_ROOT)/%,$(shell pwd))
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

.PHONY: modules modules_clean modules_install install_hdr install_data

modules:
	@make $(MOD_MAKES) $(if $(PACKAGE_DEPS), KBUILD_EXTRA_SYMBOLS="$(patsubst %,$(ENV_DEP_ROOT)/usr/include/%/Module.symvers,$(PACKAGE_DEPS))") modules

modules_clean:
	@make $(MOD_MAKES) clean

modules_install:
	@make $(MOD_MAKES) $(if $(ENV_INS_ROOT), INSTALL_MOD_PATH=$(ENV_INS_ROOT)) modules_install

install_hdr:
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@cp -fp $(OUT_PATH)/Module.symvers $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@cp -rfp $(INSTALL_HEADER) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)

install_data:
	@install -d $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
	@cp -rf $(INSTALL_DATA) $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)

install_data_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_DATA_$(patsubst install_data_%,%,$@)))),cp -rfp,cp -rf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_DATA_$(patsubst install_data_%,%,$@))),,$(INSTALL_DATA_$(patsubst install_data_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)/usr/share$(lastword $(INSTALL_DATA_$(patsubst install_data_%,%,$@)))"; \
		install -d $${idst} && $${icp} $${isrc} $${idst}

install_todir_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))),cp -rfp,cp -rf)"; \
		isrc="$(patsubst $(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@))),,$(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		install -d $${idst} && $${icp} $${isrc} $${idst}

install_tofile_%:
	@icp="$(if $(findstring /include,$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))),cp -fp,cp -f)"; \
		isrc="$(word 1,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		idst="$(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))"; \
		install -d $(dir $(ENV_INS_ROOT)$(lastword $(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))) && $${icp} $${isrc} $${idst}

endif

