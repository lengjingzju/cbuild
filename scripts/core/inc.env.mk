ifneq ($(BUILD_FOR_HOST), y)
OUT_PREFIX     := $(ENV_OUT_ROOT)
INS_PREFIX     := $(ENV_INS_ROOT)
DEP_PREFIX     := $(ENV_DEP_ROOT)
else
OUT_PREFIX     := $(ENV_OUT_HOST)
INS_PREFIX     := $(ENV_INS_HOST)
DEP_PREFIX     := $(ENV_DEP_HOST)
endif

define link_hdrs
$(addprefix  -I,$(wildcard \
	$(addprefix $(DEP_PREFIX),/include /usr/include /usr/local/include) \
	$(addprefix $(DEP_PREFIX)/include/,$(PACKAGE_DEPS)) \
	$(addprefix $(DEP_PREFIX)/usr/include/,$(PACKAGE_DEPS)) \
	$(addprefix $(DEP_PREFIX)/usr/local/include/,$(PACKAGE_DEPS)) \
))
endef

ifeq ($(KERNELRELEASE), )

comma          :=,
define link_libs
$(addprefix -L,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib))) \
$(addprefix -Wl$(comma)-rpath-link=,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib)))
endef

define safe_copy
$(if $(filter yocto,$(ENV_BUILD_MODE)),cp $1 $2,flock $(INS_PREFIX) -c "cp $1 $2")
endef

ifneq ($(filter y,$(EXPORT_HOST_ENV) $(BUILD_FOR_HOST)), )
export PATH:=$(shell echo $(addprefix $(ENV_DEP_HOST),/bin /usr/bin /usr/local/bin)$(if $(PATH),:$(PATH)) | sed 's/ /:/g')
export LD_LIBRARY_PATH:=$(shell echo $(addprefix $(ENV_DEP_HOST),/lib /usr/lib /usr/local/lib)$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH)) | sed 's/ /:/g')
endif

ifeq ($(EXPORT_PC_ENV), y)
export PKG_CONFIG_LIBDIR=$(DEP_PREFIX)/usr/lib/pkgconfig
export PKG_CONFIG_PATH=$(shell echo $(wildcard $(addprefix $(DEP_PREFIX),$(addsuffix /pkgconfig,/lib /usr/lib /usr/local/lib))) | sed 's@ @:@g')
endif

ifeq ($(ENV_BUILD_MODE), yocto)

# envs should be exported by yocto recipe.

else

ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(OUT_PREFIX)/%,$(shell pwd))
else
OUT_PATH       ?= .
endif

ifneq ($(BUILD_FOR_HOST), y)

ifneq ($(ENV_BUILD_ARCH), )
ARCH           := $(ENV_BUILD_ARCH)
export ARCH
endif

ifneq ($(ENV_BUILD_TOOL), )
ifneq ($(findstring /,$(ENV_BUILD_TOOL)), )
CROSS_TOOLPATH := $(shell dirname $(ENV_BUILD_TOOL))
CROSS_COMPILE  := $(shell basename $(ENV_BUILD_TOOL))
export PATH:=$(PATH):$(CROSS_TOOLPATH)
else
CROSS_COMPILE  := $(ENV_BUILD_TOOL)
endif
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

else

undefine ARCH CROSS_COMPILE
unexport ARCH CROSS_COMPILE

CC             := gcc
CPP            := gcc -E
CXX            := g++
AS             := as
LD             := ld
AR             := ar
RANLIB         := ranlib
OBJCOPY        := objcopy
STRIP          := strip
export CC CXX CPP AS LD AR RANLIB OBJCOPY STRIP

endif
endif
endif
