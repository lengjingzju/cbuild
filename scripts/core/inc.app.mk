ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_OUT_ROOT):")
else
OUT_PATH       ?= .
endif

define translate_obj
$(patsubst %.c,%.o,\
	$(patsubst %.cpp,%.o,\
	$(patsubst %.S,%.o,\
	$(patsubst %,$(OUT_PATH)/%,$(1)\
))))
endef

define all_ver_obj
$(strip \
	$(if $(word 4,$(1)), \
		$(if $(word 4,$(1)),$(word 1,$(1)).$(word 2,$(1)).$(word 3,$(1)).$(word 4,$(1))) \
		$(if $(word 2,$(1)),$(word 1,$(1)).$(word 2,$(1))) \
		$(word 1,$(1)) \
		,\
		$(if $(word 3,$(1)),$(word 1,$(1)).$(word 2,$(1)).$(word 3,$(1))) \
		$(if $(word 2,$(1)),$(word 1,$(1)).$(word 2,$(1))) \
		$(word 1,$(1)) \
	)
)
endef

SRC_PATH       ?= .
SRCS           ?= $(shell find $(SRC_PATH) -name "*.c" -o -name "*.cpp" -o -name "*.S" \
                  | grep -v "scripts/" | sed "s/\(\.\/\)\(.*\)/\2/g" | xargs)
OBJS            = $(call translate_obj,$(SRCS))
DEPS            = $(patsubst %.o,%.d,$(OBJS))

CFLAGS         += -I./include/ $(patsubst %,-I%/,$(filter-out .,$(SRC_PATH))) $(patsubst %,-I%/inlcude/,$(filter-out .,$(SRC_PATH))) -I$(OUT_PATH)/

comma          :=,
ifneq ($(PACKAGE_DEPS), )
CFLAGS         += $(patsubst %,-I$(ENV_DEP_ROOT)%,/usr/include/ /usr/local/include/)
CFLAGS         += $(patsubst %,-I$(ENV_DEP_ROOT)/usr/include/%/,$(PACKAGE_DEPS))
LDFLAGS        += $(patsubst %,-L$(ENV_DEP_ROOT)%,/lib/ /usr/lib/ /usr/local/lib/)
LDFLAGS        += $(patsubst %,-Wl$(comma)-rpath-link=$(ENV_DEP_ROOT)%,/lib/ /usr/lib/ /usr/local/lib/)
endif

CFLAGS         += -ffunction-sections -fdata-sections -O2
#CFLAGS        += -O0 -g -ggdb
LDFLAGS        += -Wl,--gc-sections
#LDFLAGS       += -static

CSRCS           = $(filter %.c,$(SRCS))
ifneq ($(CSRCS), )
$(patsubst %.c,$(OUT_PATH)/%.o,$(CSRCS)): $(OUT_PATH)/%.o: %.c
	@-mkdir -p $(dir $@)
	@$(CC) -c $(CFLAGS) $(CFLAGS_$(patsubst %.c,%.o,$<)) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[032m$(CC)\033[0m	$<"
	@$(CC) -c $(CFLAGS) $(CFLAGS_$(patsubst %.c,%.o,$<)) -fPIC -o $@ $<
endif

CPPSRCS         = $(filter %.cpp,$(SRCS))
ifneq ($(CPPSRCS), )
$(patsubst %.cpp,$(OUT_PATH)/%.o,$(CPPSRCS)): $(OUT_PATH)/%.o: %.cpp
	@-mkdir -p $(dir $@)
	@$(CXX) -c $(CFLAGS) $(CFLAGS_$(patsubst %.cpp,%.o,$<)) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[032m$(CXX)\033[0m	$<"
	@$(CXX) -c $(CFLAGS) $(CFLAGS_$(patsubst %.cpp,%.o,$<)) -fPIC -o $@ $<
endif

SSRCS           = $(filter %.S,$(SRCS))
ifneq ($(SSRCS), )
$(patsubst %.S,$(OUT_PATH)/%.o,$(SSRCS)): $(OUT_PATH)/%.o: %.S
	@-mkdir -p $(dir $@)
	@echo "\033[032m$(CC)\033[0m	$<"
	@$(CC) -c $(CFLAGS) $(CFLAGS_$(patsubst %.S,%.o,$<)) -fPIC -o $@ $<
endif

$(OBJS): $(MAKEFILE_LIST)
-include $(DEPS)

.PHONY: clean_objs install_liba install_libso install_bin

clean_objs:
	@-rm -rf $(OBJS) $(DEPS)

ifneq ($(LIBA_NAME), )
LIB_TARGETS += $(OUT_PATH)/$(LIBA_NAME)
$(OUT_PATH)/$(LIBA_NAME): $(OBJS)
	@echo "\033[032mlib:\033[0m	\033[44m$@\033[0m"
	@$(AR) r $@ $^ -c

install_liba:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@cp -rf $(OUT_PATH)/$(LIBA_NAME) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(LIBSO_NAME), )
LIBSO_NAMES := $(call all_ver_obj,$(LIBSO_NAME))
LIB_TARGETS += $(patsubst %,$(OUT_PATH)/%,$(LIBSO_NAMES))

$(OUT_PATH)/$(firstword $(LIBSO_NAMES)): $(OBJS)
	@echo "\033[032mlib:\033[0m	\033[44m$@\033[0m"
	@$(if $(CPPSRCS),$(CXX),$(CC)) -shared -fPIC -o $@ $^ $(LDFLAGS) \
		$(if $(findstring -soname=,$(LDFLAGS)),,-Wl$(comma)-soname=$(if $(word 2,$(LIBSO_NAME)),$(firstword $(LIBSO_NAME)).$(word 2,$(LIBSO_NAME)),$(LIBSO_NAME)))

ifneq ($(word 2,$(LIBSO_NAMES)), )
$(OUT_PATH)/$(word 2,$(LIBSO_NAMES)): $(OUT_PATH)/$(word 1,$(LIBSO_NAMES))
	@cd $(OUT_PATH) && ln -sf $(patsubst $(OUT_PATH)/%,%,$<) $(patsubst $(OUT_PATH)/%,%,$@)
endif

ifneq ($(word 3,$(LIBSO_NAMES)), )
$(OUT_PATH)/$(word 3,$(LIBSO_NAMES)): $(OUT_PATH)/$(word 2,$(LIBSO_NAMES))
	@cd $(OUT_PATH) && ln -sf $(patsubst $(OUT_PATH)/%,%,$<) $(patsubst $(OUT_PATH)/%,%,$@)
endif

ifneq ($(word 4,$(LIBSO_NAMES)), )
$(OUT_PATH)/$(word 4,$(LIBSO_NAMES)): $(OUT_PATH)/$(word 3,$(LIBSO_NAMES))
	@cd $(OUT_PATH) && ln -sf $(patsubst $(OUT_PATH)/%,%,$<) $(patsubst $(OUT_PATH)/%,%,$@)
endif

install_libso:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@cp -rf $(patsubst %,$(OUT_PATH)/%,$(LIBSO_NAMES)) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(BIN_NAME), )
BIN_TARGETS += $(OUT_PATH)/$(BIN_NAME)
$(OUT_PATH)/$(BIN_NAME): $(OBJS)
	@echo "\033[032mbin:\033[0m	\033[44m$@\033[0m"
	@$(if $(CPPSRCS),$(CXX),$(CC)) -o $@ $^ $(LDFLAGS)

install_bin:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@cp -rf $(OUT_PATH)/$(BIN_NAME) $(ENV_INS_ROOT)/usr/bin
endif

define add-liba-build
LIB_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(call translate_obj,$(2))
	@echo "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(AR) r $$@ $$^ -c
endef

define add-libso-build
libso_names := $(call all_ver_obj,$(1))
LIB_TARGETS += $(patsubst %,$(OUT_PATH)/%,$(call all_ver_obj,$(1)))

$$(OUT_PATH)/$$(firstword $$(libso_names)): $$(call translate_obj,$(2))
	@echo "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(if $$(filter %.cpp,$(2)),$$(CXX),$$(CC)) -shared -fPIC -o $$@ $$^ $$(LDFLAGS) $(3) \
		$$(if $$(findstring -soname=,$(3)),,-Wl$$(comma)-soname=$$(if $$(word 2,$(1)),$$(firstword $(1)).$$(word 2,$(1)),$(1)))

ifneq ($$(word 2,$$(libso_names)), )
$$(OUT_PATH)/$$(word 2,$$(libso_names)): $$(OUT_PATH)/$$(word 1,$$(libso_names))
	@cd $$(OUT_PATH) && ln -sf $$(patsubst $$(OUT_PATH)/%,%,$$<) $$(patsubst $$(OUT_PATH)/%,%,$$@)
endif

ifneq ($$(word 3,$$(libso_names)), )
$$(OUT_PATH)/$$(word 3,$$(libso_names)): $$(OUT_PATH)/$$(word 2,$$(libso_names))
	@cd $$(OUT_PATH) && ln -sf $$(patsubst $$(OUT_PATH)/%,%,$$<) $$(patsubst $$(OUT_PATH)/%,%,$$@)
endif

ifneq ($$(word 4,$$(libso_names)), )
$$(OUT_PATH)/$$(word 4,$$(libso_names)): $$(OUT_PATH)/$$(word 3,$$(libso_names))
	@cd $$(OUT_PATH) && ln -sf $$(patsubst $$(OUT_PATH)/%,%,$$<) $$(patsubst $$(OUT_PATH)/%,%,$$@)
endif

endef

define add-bin-build
BIN_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(call translate_obj,$(2))
	@echo "\033[032mbin:\033[0m	\033[44m$$@\033[0m"
	@$$(if $$(filter %.cpp,$(2)),$$(CXX),$$(CC)) -o $$@ $$^ $$(LDFLAGS) $(3)
endef

ifneq ($(INSTALL_HEADER)$(INSTALL_PRIVATE_HEADER), )
install_hdr:
ifneq ($(INSTALL_HEADER), )
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@cp -rfp $(INSTALL_HEADER) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
endif
ifneq ($(INSTALL_PRIVATE_HEADER), )
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private
	@cp -rfp $(INSTALL_PRIVATE_HEADER) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private
endif
endif

ifneq ($(INSTALL_DATA), )
install_data:
	@install -d $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
	@cp -rf $(INSTALL_DATA) $(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)
endif

install_data_%:
	@isrc="$(patsubst $(lastword $(INSTALL_DATA_$(patsubst install_data_%,%,$@))),,$(INSTALL_DATA_$(patsubst install_data_%,%,$@)))"; \
		idst=$(ENV_INS_ROOT)/usr/share$(lastword $(INSTALL_DATA_$(patsubst install_data_%,%,$@))); \
		install -d $${idst} && cp -f $${isrc} $${idst}

install_todir_%:
	@isrc="$(patsubst $(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@))),,$(INSTALL_TODIR_$(patsubst install_todir_%,%,$@)))"; \
		idst=$(ENV_INS_ROOT)$(lastword $(INSTALL_TODIR_$(patsubst install_todir_%,%,$@))); \
		install -d $${idst} && cp -f $${isrc} $${idst}

install_tofile_%:
	@isrc=$(word 1,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@))); \
		idst=$(ENV_INS_ROOT)$(word 2,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@))); \
		install -d $(dir $(ENV_INS_ROOT)$(word 2,$(INSTALL_TOFILE_$(patsubst install_tofile_%,%,$@)))) && cp -f $${isrc} $${idst}

