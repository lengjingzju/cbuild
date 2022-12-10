# Uppper Makefile should set the following variables first.

CACHE_SCRIPT    ?= $(ENV_TOOL_DIR)/process_cache.sh
CACHE_PACKAGE   ?= $(PACKAGE_NAME)
CACHE_SRCFILE   ?= $(DOWNLOAD_NAME)
CACHE_OUTPATH   ?= $(OUT_PATH)
CACHE_INSPATH   ?= $(OUT_PATH)/image
CACHE_GRADE     ?= 2
CACHE_CHECKSUM  ?=
CACHE_DEPENDS   ?=
CACHE_URL       ?=
CACHE_VERBOSE   ?= 1

# define do_compile
# Uppper Makefile should set do_compile function first.
# endef

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

.PHONY: cachebuild setforce unsetforce

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
