ifneq ($(KERNELRELEASE),)

MOD_NAME       ?= hello

ifneq ($(MOD_NAME),)
SRCS           ?= $(shell find $(src) -name "*.c" | grep -v "scripts/" | grep -v "\.mod\.c" | xargs)
OBJS            = $(patsubst $(src)/%,%,$(patsubst %.c,%.o,$(SRCS)))

obj-m := $(MOD_NAME).o
ifneq ($(words $(OBJS)), 1)
$(MOD_NAME)-objs := $(OBJS)
endif
endif

else

KERNAL_PATH    ?= /lib/modules/$(shell uname -r)/build
MOD_MAKES      += -C $(KERNAL_PATH) $(if $(KERNAL_OUTPUT),O=$(KERNAL_OUTPUT))

#KBUILD_EXTRA_SYMBOLS
#INSTALL_MOD_PATH

ifneq ($(USING_EXT_BUILD), y)

MOD_MAKES      += M=$(shell pwd)

else

OUT_PATH       ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_TOP_OUT):")
MOD_MAKES      += M=$(OUT_PATH) src=$(shell pwd)

modules modules_clean modules_install: $(OUT_PATH)/Makefile

$(OUT_PATH)/Makefile: Makefile
	@-mkdir -p $(dir $@)
	@-cp -f $< $@

#
# Note:
# Users should copy the Makefile to avoid compilation failures.
# If they don't want to copy it, they should modify the
# "$(KERNAL_PATH)/scripts/Makefile.modpost" as follow:
#   -include $(if $(wildcard $(KBUILD_EXTMOD)/Kbuild), \
#   -             $(KBUILD_EXTMOD)/Kbuild, $(KBUILD_EXTMOD)/Makefile)
#   +include $(if $(wildcard $(src)/Kbuild), \
#   +             $(src)/Kbuild, $(src)/Makefile)
#

endif

modules:
	@make $(MOD_MAKES) $(if $(MOD_DEPS), KBUILD_EXTRA_SYMBOLS="$(patsubst %,%/Module.symvers,$(patsubst %/,%,$(MOD_DEPS)))") modules

modules_clean:
	@make $(MOD_MAKES) clean

modules_install:
	@make $(MOD_MAKES) $(if $(MOD_PATH), INSTALL_MOD_PATH=$(MOD_PATH)) modules_install

endif
