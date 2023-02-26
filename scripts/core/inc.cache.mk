############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

ifeq ($(KERNELRELEASE), )
COLORECHO       ?= $(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e)
FETCH_SCRIPT    := $(ENV_TOOL_DIR)/fetch_package.sh
PATCH_SCRIPT    := $(ENV_TOOL_DIR)/exec_patch.sh
CACHE_SCRIPT    := $(ENV_TOOL_DIR)/process_cache.sh
MACHINE_SCRIPT  := $(ENV_TOOL_DIR)/process_machine.sh
MESON_SCRIPT    := $(ENV_TOOL_DIR)/meson_cross.sh

FETCH_METHOD    ?= tar
SRC_PATH        ?= $(OUT_PATH)/$(SRC_DIR)
SRC_URLS        ?= $(if $(SRC_URL),$(SRC_URL)$(if $(SRC_MD5),;md5=$(SRC_MD5))$(if $(SRC_BRANCH),;branch=$(SRC_BRANCH))$(if $(SRC_TAG),;tag=$(SRC_TAG))$(if $(SRC_REV),;rev=$(SRC_REV)))
OBJ_PATH        ?= $(OUT_PATH)/build
INS_PATH        ?= $(OUT_PATH)/image
INS_SUBDIR      ?= /usr
PC_FILES        ?=

ifneq ($(COMPILE_TOOL), meson)
MAKES           ?= make $(ENV_BUILD_JOBS) $(ENV_MAKE_FLAGS) $(MAKES_FLAGS)
else
MAKES           ?= ninja $(ENV_BUILD_JOBS) $(MAKES_FLAGS)
MESON_WRAP_MODE ?= --wrap-mode=nodownload
MESON_LIBDIR    ?= --libdir=$(INS_PATH)$(INS_SUBDIR)/lib
endif
CROSS_CONFIGURE ?= $(shell $(MACHINE_SCRIPT) cross_configure)
CROSS_CMAKE     ?= $(shell $(MACHINE_SCRIPT) cross_cmake)

CACHE_OUTPATH   ?= $(OUT_PATH)
CACHE_INSPATH   ?= $(INS_PATH)
CACHE_GRADE     ?= 2
CACHE_CHECKSUM  += $(wildcard $(shell pwd)/mk.deps)
CACHE_DEPENDS   ?=
ifneq ($(SRC_MD5)$(SRC_TAG)$(SRC_REV), )
CACHE_APPENDS   += $(SRC_MD5)$(SRC_TAG)$(SRC_REV)
CACHE_SRCFILE    =
CACHE_URL        =
else
CACHE_APPENDS   ?=
CACHE_SRCFILE   ?= $(SRC_NAME)
CACHE_URL       ?= $(if $(SRC_URLS),[$(FETCH_METHOD)]$(SRC_URLS))
endif
CACHE_VERBOSE   ?= 1

ifneq ($(PC_FILES), )
define do_inspc
	sed -i "s@$(INS_PATH)@INS_PREFIX@g" $(addprefix $(INS_PATH)$(INS_SUBDIR)/lib/pkgconfig/,$(PC_FILES))
endef

define do_syspc
	sed -i "s@INS_PREFIX@$(INS_PREFIX)@g" $(addprefix $(INS_PREFIX)$(INS_SUBDIR)/lib/pkgconfig/,$(PC_FILES))
endef
endif

define do_fetch
	mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock && \
	flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME) $(OUT_PATH) $(SRC_DIR)"
endef

define do_patch
	$(PATCH_SCRIPT) patch $(PATCH_FOLDER) $(SRC_PATH)
endef

ifeq ($(do_compile), )
define do_compile
	set -e; \
	$(if $(SRC_URLS),$(call do_fetch),true); \
	$(if $(PATCH_FOLDER),$(call do_patch),true); \
	mkdir -p $(OBJ_PATH); \
	$(if $(do_prepend),$(call do_prepend),true); \
	if [ "$(COMPILE_TOOL)" = "cmake" ]; then \
		cd $(OBJ_PATH) && cmake $(SRC_PATH) $(if $(CROSS_COMPILE),$(CROSS_CMAKE)) \
			-DCMAKE_INSTALL_PREFIX=$(INS_PATH)$(INS_SUBDIR) $(CMAKE_FLAGS) $(LOGOUTPUT); \
	elif [ "$(COMPILE_TOOL)" = "configure" ]; then \
		cd $(OBJ_PATH) && $(SRC_PATH)/configure $(if $(CROSS_COMPILE),$(CROSS_CONFIGURE)) \
			--prefix=$(INS_PATH)$(INS_SUBDIR) $(CONFIGURE_FLAGS) $(LOGOUTPUT); \
	elif [ "$(COMPILE_TOOL)" = "meson" ]; then \
		$(if $(CROSS_COMPILE),$(MESON_SCRIPT) $(OBJ_PATH),true); \
		$(if $(do_meson_cfg),$(call do_meson_cfg),true); \
		cd $(SRC_PATH) && meson $(if $(CROSS_COMPILE),--cross-file $(OBJ_PATH)/cross.ini) \
			--prefix=$(INS_PATH)$(INS_SUBDIR) $(MESON_LIBDIR) $(MESON_WRAP_MODE) \
			$(MESON_FLAGS) $(OBJ_PATH) $(LOGOUTPUT); \
		cd $(OBJ_PATH); \
	fi; \
	rm -rf $(INS_PATH) && $(MAKES) $(LOGOUTPUT) && $(MAKES) install $(LOGOUTPUT); \
	$(if $(PC_FILES),$(call do_inspc),true); \
	$(if $(do_append),$(call do_append),true); \
	set +e
endef
endif

define do_check
	$(CACHE_SCRIPT) -m check -p $(PACKAGE_NAME) $(if $(filter y,$(BUILD_FOR_HOST)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)') \
		$(if $(CACHE_URL),-u '$(CACHE_URL)')
endef

define do_pull
	$(CACHE_SCRIPT) -m pull  -p $(PACKAGE_NAME) $(if $(filter y,$(BUILD_FOR_HOST)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) && \
	$(COLORECHO) "\033[33mUse $(PACKAGE_ID) Cache in $(ENV_CACHE_DIR).\033[0m"
endef

define do_push
	$(CACHE_SCRIPT) -m push  -p $(PACKAGE_NAME) $(if $(filter y,$(BUILD_FOR_HOST)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_APPENDS),-a '$(CACHE_APPENDS)') && \
	$(COLORECHO) "\033[33mPush $(PACKAGE_ID) Cache to $(ENV_CACHE_DIR).\033[0m"
endef

define do_setforce
	$(CACHE_SCRIPT) -m setforce -p $(PACKAGE_NAME) $(if $(filter y,$(BUILD_FOR_HOST)),-n) \
		-o $(CACHE_OUTPATH) -v $(CACHE_VERBOSE) && \
	echo "Set $(PACKAGE_ID) Force Build."
endef

define do_set1force
	$(CACHE_SCRIPT) -m set1force -p $(PACKAGE_NAME) $(if $(filter y,$(BUILD_FOR_HOST)),-n) \
		-o $(CACHE_OUTPATH) -v $(CACHE_VERBOSE) && \
	echo "Set $(PACKAGE_ID) Force Build."
endef

define do_unsetforce
	$(CACHE_SCRIPT) -m unsetforce -p $(PACKAGE_NAME) $(if $(filter y,$(BUILD_FOR_HOST)),-n) \
		-o $(CACHE_OUTPATH) -i $(CACHE_INSPATH) -v $(CACHE_VERBOSE) && \
	echo "Unset $(PACKAGE_ID) Force Build."
endef

ifneq ($(USER_DEFINED_TARGET), y)

.PHONY: all install clean

all: cachebuild

clean:
	@rm -rf $(OUT_PATH)
	@echo "Clean $(PACKAGE_ID) Done."

install:
	@install -d $(INS_PREFIX)
	@$(call safe_copy,-rfp,$(INS_PATH)/* $(INS_PREFIX))
	@$(if $(PC_FILES),$(call do_syspc))
	@$(if $(do_install_append),$(call do_install_append))
	@echo "Install $(PACKAGE_ID) Done."

endif

ifeq ($(PREPARE_SYSROOT), y)
.PHONY: psysroot

psysroot:
	@checksum=$$($(call do_check)); \
	matchflag=$$(echo "$${checksum}" | grep -wc MATCH); \
	checkinfo=$$(echo "$${checksum}" | sed '/MATCH/ d'); \
	if [ ! -z "$${checkinfo}" ]; then \
		echo "$${checkinfo}"; \
	fi; \
	if [ $${matchflag} -eq 0 ]; then \
		$(call prepare_sysroot); \
	fi
endif

.PHONY: srcbuild cachebuild dofetch setforce set1force unsetforce

srcbuild:
	@$(call do_compile)
	@echo "Build $(PACKAGE_ID) Done."

cachebuild:
	@checksum=$$($(call do_check)); \
	matchflag=$$(echo "$${checksum}" | grep -wc MATCH); \
	errorflag=$$(echo "$${checksum}" | grep -c ERROR); \
	checkinfo=$$(echo "$${checksum}" | sed '/MATCH/ d'); \
	if [ ! -z "$${checkinfo}" ]; then \
		echo "$${checkinfo}"; \
	fi; \
	if [ $${matchflag} -ne 0 ]; then \
		$(call do_pull); \
	elif [ $${errorflag} -ne 0 ]; then \
		exit 1; \
	else \
		$(call do_compile); \
		$(call do_push); \
	fi
	@echo "Build $(PACKAGE_ID) Done."

dofetch:
ifneq ($(SRC_URLS), )
	@mkdir -p $(ENV_DOWN_DIR)/lock && echo > $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock
	@flock $(ENV_DOWN_DIR)/lock/$(SRC_NAME).lock -c "bash $(FETCH_SCRIPT) $(FETCH_METHOD) \"$(SRC_URLS)\" $(SRC_NAME) $(if $(filter -s,$(ENV_MAKE_FLAGS)),,$(OUT_PATH) $(SRC_DIR))"
else
	@
endif

setforce:
	@$(call do_setforce)

set1force:
	@$(call do_set1force)

unsetforce:
	@$(call do_unsetforce)

endif
