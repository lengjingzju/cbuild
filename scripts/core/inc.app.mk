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

SRC_PATH       ?= .
SRCS           ?= $(shell find $(SRC_PATH) -name "*.c" -o -name "*.cpp" -o -name "*.S" \
                  | grep -v "scripts/" | sed "s/\(\.\/\)\(.*\)/\2/g" | xargs)
OBJS            = $(call translate_obj,$(SRCS))
DEPS            = $(patsubst %.o,%.d,$(OBJS))

CFLAGS         += -I$(SRC_PATH)/ -I$(SRC_PATH)/include/ -I$(OUT_PATH)/

ifneq ($(PACKAGE_DEPS), )
CFLAGS         += $(patsubst %,-I$(ENV_DEP_ROOT)%,/usr/include/ /usr/local/include/)
CFLAGS         += $(patsubst %,-I$(ENV_DEP_ROOT)/usr/include/%/,$(PACKAGE_DEPS))
LDFLAGS        += $(patsubst %,-L$(ENV_DEP_ROOT)%,/lib/ /usr/lib/ /usr/local/lib/)
endif

CFLAGS         += -ffunction-sections -fdata-sections -O2
#CFLAGS        += -O0 -g -ggdb
LDFLAGS        += -Wl,--gc-sections
#LDFLAGS       += -static

CSRCS           = $(filter %.c,$(SRCS))
ifneq ($(CSRCS), )
$(patsubst %.c,$(OUT_PATH)/%.o,$(CSRCS)): $(OUT_PATH)/%.o: %.c
	@-mkdir -p $(dir $@)
	@$(CC) -c $(CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[032m$(CC)\033[0m	$<"
	@$(CC) -c $(CFLAGS) -fPIC -o $@ $<
endif

CPPSRCS         = $(filter %.cpp,$(SRCS))
ifneq ($(CPPSRCS), )
$(patsubst %.cpp,$(OUT_PATH)/%.o,$(CPPSRCS)): $(OUT_PATH)/%.o: %.cpp
	@-mkdir -p $(dir $@)
	@$(CXX) -c $(CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[032m$(CXX)\033[0m	$<"
	@$(CXX) -c $(CFLAGS) -fPIC -o $@ $<
endif

SSRCS           = $(filter %.S,$(SRCS))
ifneq ($(SSRCS), )
$(patsubst %.S,$(OUT_PATH)/%.o,$(SSRCS)): $(OUT_PATH)/%.o: %.S
	@-mkdir -p $(dir $@)
	@echo "\033[032m$(CC)\033[0m	$<"
	@$(CC) -c $(CFLAGS) -fPIC -o $@ $<
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
	@install $(OUT_PATH)/$(LIBA_NAME) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(LIBSO_NAME), )
LIB_TARGETS += $(OUT_PATH)/$(LIBSO_NAME)
$(OUT_PATH)/$(LIBSO_NAME): $(OBJS)
	@echo "\033[032mlib:\033[0m	\033[44m$@\033[0m"
	@$(if $(CPPSRCS),$(CXX),$(CC)) -shared -fPIC -o $@ $^

install_libso:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@install $(OUT_PATH)/$(LIBSO_NAME) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(BIN_NAME), )
BIN_TARGETS += $(OUT_PATH)/$(BIN_NAME)
$(OUT_PATH)/$(BIN_NAME): $(OBJS)
	@echo "\033[032mbin:\033[0m	\033[44m$@\033[0m"
	@$(if $(CPPSRCS),$(CXX),$(CC)) -o $@ $^ $(LDFLAGS)

install_bin:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@install $(OUT_PATH)/$(BIN_NAME) $(ENV_INS_ROOT)/usr/bin
endif

define add-liba-build
LIB_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(call translate_obj,$(2))
	@echo "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(AR) r $$@ $$^ -c
endef

define add-libso-build
LIB_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(call translate_obj,$(2))
	@echo "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(if $$(filter %.cpp,$(2)),$$(CXX),$$(CC)) -shared -fPIC -o $$@ $$^
endef

define add-bin-build
BIN_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(call translate_obj,$(2))
	@echo "\033[032mbin:\033[0m	\033[44m$$@\033[0m"
	@$$(if $$(filter %.cpp,$(2)),$$(CXX),$$(CC)) -o $$@ $$^ $$(LDFLAGS) $(3)
endef

