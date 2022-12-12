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
ifneq ($(findstring /,$(ENV_BUILD_TOOL)), )
CROSS_TOOLPATH := $(shell dirname $(ENV_BUILD_TOOL))
CROSS_COMPILE  := $(shell basename $(ENV_BUILD_TOOL))
export PATH:=$(PATH):$(CROSS_TOOLPATH)
export CROSS_TOOLPATH CROSS_COMPILE
else
CROSS_COMPILE  := $(ENV_BUILD_TOOL)
export CROSS_COMPILE
endif
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
endif

define safe_copy
$(if $(filter yocto,$(ENV_BUILD_MODE)),cp $1 $2,flock $(ENV_INS_ROOT) -c "cp $1 $2")
endef

define link_hdrs
$(addprefix  -I,$(wildcard \
	$(addprefix $(ENV_DEP_ROOT),/include /usr/include /usr/local/include) \
	$(addprefix $(ENV_DEP_ROOT)/include/,$(PACKAGE_DEPS)) \
	$(addprefix $(ENV_DEP_ROOT)/usr/include/,$(PACKAGE_DEPS)) \
	$(addprefix $(ENV_DEP_ROOT)/usr/local/include/,$(PACKAGE_DEPS)) \
))
endef

comma          :=,
define link_libs
$(addprefix -L,$(wildcard $(addprefix $(ENV_DEP_ROOT),/lib /usr/lib /usr/local/lib))) \
$(addprefix -Wl$(comma)-rpath-link=,$(wildcard $(addprefix $(ENV_DEP_ROOT),/lib /usr/lib /usr/local/lib)))
endef
