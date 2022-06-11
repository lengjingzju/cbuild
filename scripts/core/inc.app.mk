ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_OUT_ROOT):")
else
OUT_PATH       ?= .
endif

SRC_PATH       ?= .
SRCS           ?= $(shell find $(SRC_PATH) -name "*.c" | grep -v "scripts/" | sed "s/\(\.\/\)\(.*\)/\2/g" | xargs)
OBJS            = $(patsubst %.c,$(OUT_PATH)/%.o,$(SRCS))
DEPS            = $(patsubst %.c,$(OUT_PATH)/%.d,$(SRCS))

CFLAGS         += -I$(SRC_PATH)/ -I$(SRC_PATH)/include/ -I$(OUT_PATH)/

ifneq ($(PACKAGE_DEPS), )
CFLAGS         += $(patsubst %,-I$(ENV_DEP_ROOT)/usr/include/%/,$(PACKAGE_DEPS))
CFLAGS         += $(patsubst %,-I$(ENV_DEP_ROOT)/usr/local/include/%/,$(PACKAGE_DEPS))
LDFLAGS        += -L$(ENV_DEP_ROOT)/lib/ -L$(ENV_DEP_ROOT)/usr/lib/ -L$(ENV_DEP_ROOT)/usr/local/lib/
endif

CFLAGS         += -ffunction-sections -fdata-sections -O2
#CFLAGS        += -O0 -g -ggdb
LDFLAGS        += -Wl,--gc-sections
#LDFLAGS       += -static

-include $(DEPS)

.PHONY: clean_objs install_liba install_libso install_bin

$(OBJS): $(OUT_PATH)/%.o: %.c
	@-mkdir -p $(dir $@)
	@$(CC) -c $(CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[032m$(CC)\033[0m	$<"
	@$(CC) -c $(CFLAGS) -fPIC -o $@ $<

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
	@$(CC) -shared -fPIC -o $@ $^

install_libso:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@install $(OUT_PATH)/$(LIBSO_NAME) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(BIN_NAME), )
BIN_TARGETS += $(OUT_PATH)/$(BIN_NAME)
$(OUT_PATH)/$(BIN_NAME): $(OBJS)
	@echo "\033[032mbin:\033[0m	\033[44m$@\033[0m"
	@$(CC) -o $@ $^ $(LDFLAGS)

install_bin:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@install $(OUT_PATH)/$(BIN_NAME) $(ENV_INS_ROOT)/usr/bin
endif

define add-liba-build
LIB_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(patsubst %.c,$$(OUT_PATH)/%.o,$(2))
	@echo "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(AR) r $$@ $$^ -c
endef

define add-libso-build
LIB_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(patsubst %.c,$$(OUT_PATH)/%.o,$(2))
	@echo "\033[032mlib:\033[0m	\033[44m$$@\033[0m"
	@$$(CC) -shared -fPIC -o $$@ $$^
endef

define add-bin-build
BIN_TARGETS += $$(OUT_PATH)/$(1)
$$(OUT_PATH)/$(1): $$(patsubst %.c,$$(OUT_PATH)/%.o,$(2))
	@echo "\033[032mbin:\033[0m	\033[44m$$@\033[0m"
	@$$(CC) -o $$@ $$^ $$(LDFLAGS)
endef

