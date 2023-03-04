############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

COLORECHO      ?= $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
LOGOUTPUT      ?= $(if $(filter -s,$(ENV_MAKE_FLAGS)),1>/dev/null)

INSTALL_HDR    ?= $(PACKAGE_NAME)
SEARCH_HDRS    ?= $(PACKAGE_DEPS)

ifneq ($(BUILD_FOR_HOST), y)
PACKAGE_ID     := $(PACKAGE_NAME)
OUT_PREFIX     ?= $(ENV_OUT_ROOT)
INS_PREFIX     ?= $(ENV_INS_ROOT)
ifneq ($(PREPARE_SYSROOT), y)
DEP_PREFIX     ?= $(ENV_DEP_ROOT)
else
DEP_PREFIX     ?= $(OUT_PATH)/sysroot
endif

else

PACKAGE_ID     := $(PACKAGE_NAME)-native
OUT_PREFIX     ?= $(ENV_OUT_HOST)
INS_PREFIX     ?= $(ENV_INS_HOST)
ifneq ($(PREPARE_SYSROOT), y)
DEP_PREFIX     ?= $(ENV_DEP_HOST)
else
DEP_PREFIX     ?= $(OUT_PATH)/sysroot-native
endif
endif

ifneq ($(PREPARE_SYSROOT), y)
PATH_PREFIX    ?= $(ENV_DEP_HOST)
else
PATH_PREFIX    ?= $(OUT_PATH)/sysroot-native
endif

ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(OUT_PREFIX)/%,$(shell pwd))
else
OUT_PATH       ?= .
endif

define link_hdrs
$(addprefix  -I,$(wildcard \
	$(addprefix $(DEP_PREFIX),/include /usr/include /usr/local/include) \
	$(addprefix $(DEP_PREFIX)/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/include/,$(SEARCH_HDRS)) \
	$(addprefix $(DEP_PREFIX)/usr/local/include/,$(SEARCH_HDRS)) \
))
endef

ifeq ($(KERNELRELEASE), )

comma          :=,
define link_libs
$(addprefix -L,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib))) \
$(addprefix -Wl$(comma)-rpath-link=,$(wildcard $(addprefix $(DEP_PREFIX),/lib /usr/lib /usr/local/lib)))
endef

define prepare_sysroot
	make ENV_INS_ROOT=$(OUT_PATH)/sysroot ENV_INS_HOST=$(OUT_PATH)/sysroot-native INSTALL_OPTION=link \
		-C $(ENV_TOP_DIR) $(PACKAGE_ID)_install_depends
endef

define safe_copy
$(if $(filter yocto,$(ENV_BUILD_MODE)),cp $1 $2,flock $(INS_PREFIX) -c "cp $1 $2")
endef

ifneq ($(filter y,$(EXPORT_HOST_ENV) $(BUILD_FOR_HOST)), )
export PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/bin /usr/bin /usr/local/bin /sbin /usr/sbin /usr/local/sbin)$(if $(PATH),:$(PATH)) | sed 's/ /:/g')
export LD_LIBRARY_PATH:=$(shell echo $(addprefix $(PATH_PREFIX),/lib /usr/lib /usr/local/lib)$(if $(LD_LIBRARY_PATH),:$(LD_LIBRARY_PATH)) | sed 's/ /:/g')
endif

# yocto envs should be exported by yocto recipe.

ifneq ($(ENV_BUILD_MODE), yocto)

export PKG_CONFIG_LIBDIR=$(DEP_PREFIX)/usr/lib/pkgconfig
export PKG_CONFIG_PATH=$(shell echo $(wildcard $(addprefix $(DEP_PREFIX),$(addsuffix /pkgconfig,/lib /usr/lib /usr/local/lib))) | sed 's@ @:@g')

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
