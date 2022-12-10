ifeq ($(KERNELRELEASE), )
ifeq ($(ENV_BUILD_MODE), yocto)

# envs should be exported by yocto recipe.

else

ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(ENV_OUT_ROOT)/%,$(shell pwd))
else
OUT_PATH       ?= .
endif

ifneq ($(ENV_BUILD_ARCH), )
ARCH           := $(ENV_BUILD_ARCH)
export ARCH
endif

ifneq ($(ENV_BUILD_TOOL), )
CROSS_COMPILE  := $(ENV_BUILD_TOOL)
export CROSS_COMPILE
endif

CC             := $(CROSS_COMPILE)gcc
CPP            := $(CROSS_COMPILE)gcc -E
CXX            := $(CROSS_COMPILE)g++
AS             := $(CROSS_COMPILE)as
LD             := $(CROSS_COMPILE)ld
AR             := $(CROSS_COMPILE)ar
RANLIB         := $(CROSS_COMPILE)ranlib
OBJCOPY        := $(CROSS_COMPILE)objcopy
STRIP          := $(CROSS_COMPILE)strip
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

endif

define safecp
$(if $(filter yocto,$(ENV_BUILD_MODE)),cp $1 $2,flock $(ENV_INS_ROOT) -c "cp $1 $2")
endef

endif
