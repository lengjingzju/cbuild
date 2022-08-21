ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(patsubst $(ENV_TOP_DIR)/%,$(ENV_OUT_ROOT)/%,$(shell pwd))
else
OUT_PATH       ?= .
endif

define translate_obj
$(patsubst %,$(OUT_PATH)/%.o,$(basename $(1)))
endef

SRC_PATH       ?= .
IGNORE_PATH    ?= .git scripts output
REG_SUFFIX     ?= c cpp S
CPP_SUFFIX     ?= cc cp cxx cpp CPP c++ C
ASM_SUFFIX     ?= S s asm

SRCS           ?= $(shell find $(SRC_PATH) $(patsubst %,-path '*/%' -prune -o,$(IGNORE_PATH)) \
                      $(shell echo '$(patsubst %,-o -name "*.%" -print,$(REG_SUFFIX))' | sed 's/^...//') \
                  | sed "s/\(\.\/\)\(.*\)/\2/g" | xargs)
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

CFLAGS         += -Wall # This enables all the warnings about constructions that some users consider questionable.
CFLAGS         += -Wextra # This enables some extra warning flags that are not enabled by -Wall (This option used to be called -W).
CFLAGS         += -Wlarger-than=$(if $(object_byte_size),$(object_byte_size),1024) # Warn whenever an object is defined whose size exceeds object_byte_size.
CFLAGS         += -Wframe-larger-than=$(if $(object_byte_size),$(object_byte_size),8192) # Warn if the size of a function frame exceeds byte-size.
#CFLAGS        += -Wdate-time #Warn when macros __TIME__, __DATE__ or __TIMESTAMP__ are encountered as they might prevent bit-wise-identical reproducible compilations.

ifeq ($(DEBUG), y)
CFLAGS         += -O0 -g -ggdb
else
CFLAGS         += -ffunction-sections -fdata-sections -O2
LDFLAGS        += -Wl,--gc-sections
endif
#LDFLAGS       += -static

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

define compile_tool
$(if $(filter $(patsubst %,\%.%,$(CPP_SUFFIX)),$(1)),$(CXX),$(CC))
endef

define set_flags
$(foreach v,$(2),$(eval $(1)_$(patsubst %,%.o,$(basename $(v))) = $(3)))
endef

define compile_obj
ifeq ($(filter $(1),$(REG_SUFFIX)),$(1))
ifneq ($(filter %.$(1),$(SRCS)), )
$$(patsubst %.$(1),$$(OUT_PATH)/%.o,$$(filter %.$(1),$$(SRCS))): $$(OUT_PATH)/%.o: %.$(1)
	@mkdir -p $$(dir $$@)
	@$$(if $$(filter-out $$(patsubst %,\%.%,$$(ASM_SUFFIX)),$$<),$(2) -c $$(CFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) -MM -MT $$@ -MF $$(patsubst %.o,%.d,$$@) $$<)
	@echo "\033[032m$(2)\033[0m	$$<"
	@$$(if $$(filter-out $$(AS),$(2)),$(2) -c $$(CFLAGS) $$(CFLAGS_$$(patsubst %.$(1),%.o,$$<)) -fPIC -o $$@ $$<,$(AS) $$(AFLAGS) $$(AFLAGS_$$(patsubst %.$(1),%.o,$$<)) -o $$@ $$<)
endif
endif
endef

$(eval $(call compile_obj,c,$$(CC)))
$(eval $(call compile_obj,cc,$$(CXX)))
$(eval $(call compile_obj,cp,$$(CXX)))
$(eval $(call compile_obj,cxx,$$(CXX)))
$(eval $(call compile_obj,cpp,$$(CXX)))
$(eval $(call compile_obj,CPP,$$(CXX)))
$(eval $(call compile_obj,c++,$$(CXX)))
$(eval $(call compile_obj,C,$$(CXX)))
$(eval $(call compile_obj,S,$$(CC)))
$(eval $(call compile_obj,s,$$(AS)))
$(eval $(call compile_obj,asm,$$(AS)))

$(OBJS): $(MAKEFILE_LIST)
-include $(DEPS)

.PHONY: clean_objs install_lib install_bin install_hdr install_data

clean_objs:
	@-rm -rf $(OBJS) $(DEPS)

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
	@$$(call compile_tool,$(2)) -shared -fPIC -o $$@ $$^ $$(LDFLAGS) $(3) \
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
	@$$(call compile_tool,$(2)) -o $$@ $$^ $$(LDFLAGS) $(3)
endef

ifneq ($(LIBA_NAME), )
$(eval $(call add-liba-build,$(LIBA_NAME),$(SRCS)))
endif

ifneq ($(LIBSO_NAME), )
$(eval $(call add-libso-build,$(LIBSO_NAME),$(SRCS)))
endif

ifneq ($(BIN_NAME), )
$(eval $(call add-bin-build,$(BIN_NAME),$(SRCS)))
endif

INSTALL_LIBRARY ?= $(LIB_TARGETS)
install_lib:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@cp -rf $(INSTALL_LIBRARY) $(ENV_INS_ROOT)/usr/lib

INSTALL_BINARY ?= $(BIN_TARGETS)
install_bin:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@cp -rf $(INSTALL_BINARY) $(ENV_INS_ROOT)/usr/bin

install_hdr:
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
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

