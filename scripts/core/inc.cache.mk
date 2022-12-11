FETCH_SCRIPT    := $(ENV_TOOL_DIR)/fetch_package.sh
PATCH_SCRIPT    := $(ENV_TOOL_DIR)/exec_patch.sh
CACHE_SCRIPT    := $(ENV_TOOL_DIR)/process_cache.sh

FETCH_METHOD    ?= tar
SRC_PATH        ?= $(OUT_PATH)/$(SRC_DIR)
OBJ_PATH        ?= $(OUT_PATH)/build
INS_PATH        ?= $(OUT_PATH)/image
MAKES           ?= make -s $(ENV_BUILD_JOBS) $(MAKES_FLAGS)

CACHE_PACKAGE   ?= $(PACKAGE_NAME)
CACHE_SRCFILE   ?= $(SRC_NAME)
CACHE_OUTPATH   ?= $(OUT_PATH)
CACHE_INSPATH   ?= $(INS_PATH)
CACHE_GRADE     ?= 2
CACHE_CHECKSUM  += $(wildcard $(shell pwd)/mk.deps)
CACHE_DEPENDS   ?= none
CACHE_URL       ?= $(if $(SRC_URL),[$(FETCH_METHOD)]$(SRC_URL))
CACHE_VERBOSE   ?= 1

define do_fetch
	$(FETCH_SCRIPT) $(FETCH_METHOD) "$(SRC_URL)" $(SRC_NAME) $(OUT_PATH) $(SRC_DIR)
endef

define do_patch
	$(PATCH_SCRIPT) patch $(PATCH_FOLDER) $(SRC_PATH)
endef

ifeq ($(do_compile), )
define do_compile
	$(if $(SRC_URL),$(call do_fetch),true); \
	$(if $(PATCH_FOLDER),$(call do_patch),true); \
	mkdir -p $(OBJ_PATH); \
	$(if $(do_prepend),$(call do_prepend),true); \
	if [ "$(COMPILE_TOOL)" = "cmake" ]; then \
		mkdir -p $(OBJ_PATH) && cd $(OBJ_PATH) && \
			cmake $(SRC_PATH) $(CMAKE_FLAGS) -DCMAKE_INSTALL_PREFIX=$(INS_PATH) 1>/dev/null; \
	elif [ "$(COMPILE_TOOL)" = "configure" ]; then \
		mkdir -p $(OBJ_PATH) && cd $(OBJ_PATH) && \
			$(SRC_PATH)/configure $(CONFIGURE_FLAGS) --prefix=$(INS_PATH) \
				$(if $(CROSS_COMPILE),--host=$(shell echo $(CROSS_COMPILE) | sed 's/-$//g')) 1>/dev/null; \
	fi; \
	rm -rf $(INS_PATH) && $(MAKES) 1>/dev/null && $(MAKES) install 1>/dev/null; \
	$(if $(do_append),$(call do_append),true)
endef
endif

define do_check
	$(CACHE_SCRIPT) -m check -p $(CACHE_PACKAGE) -o $(CACHE_OUTPATH) \
		-i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') $(if $(CACHE_URL),-u '$(CACHE_URL)')
endef

define do_pull
	$(CACHE_SCRIPT) -m pull  -p $(CACHE_PACKAGE) -o $(CACHE_OUTPATH) \
		-i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) && \
	echo "Use $(CACHE_PACKAGE) Cache in $(ENV_CACHE_DIR)."
endef

define do_push
	$(CACHE_SCRIPT) -m push  -p $(CACHE_PACKAGE) -o $(CACHE_OUTPATH) \
		-i $(CACHE_INSPATH) -g $(CACHE_GRADE) -v $(CACHE_VERBOSE) \
		$(if $(CACHE_SRCFILE),-s $(CACHE_SRCFILE)) $(if $(CACHE_CHECKSUM),-c '$(CACHE_CHECKSUM)') \
		$(if $(CACHE_DEPENDS),-d '$(CACHE_DEPENDS)') && \
	echo "Push $(CACHE_PACKAGE) Cache to $(ENV_CACHE_DIR)."
endef

define do_setforce
	$(CACHE_SCRIPT) -m setforce -p $(CACHE_PACKAGE) -o $(CACHE_OUTPATH) \
		-v $(CACHE_VERBOSE) && \
	echo "Set $(CACHE_PACKAGE) Force Build."
endef

define do_unsetforce
	$(CACHE_SCRIPT) -m unsetforce -p $(CACHE_PACKAGE) -o $(CACHE_OUTPATH) \
		-i $(CACHE_INSPATH) -v $(CACHE_VERBOSE) && \
	echo "Unset $(CACHE_PACKAGE) Force Build."
endef

ifneq ($(USER_DEFINED_TARGET), y)

.PHONY: all install clean

all: cachebuild

clean:
	@rm -rf $(OUT_PATH)
	@echo "Clean $(PACKAGE_NAME) Done."

install:
	@install -d $(ENV_INS_ROOT)
	@$(call safecp,-rfp,$(INS_PATH)/* $(ENV_INS_ROOT))
	@echo "Install $(PACKAGE_NAME) Done."

endif

.PHONY: srcbuild cachebuild setforce unsetforce

srcbuild:
	@$(call do_compile)
	@echo "Build $(PACKAGE_NAME) Done."

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
	@echo "Build $(CACHE_PACKAGE) Done."

setforce:
	@$(call do_setforce)

unsetforce:
	@$(call do_unsetforce)
