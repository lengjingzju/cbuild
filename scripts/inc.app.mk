ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_TOP_OUT):")
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

$(OBJS): $(OUT_PATH)/%.o: %.c
	@-mkdir -p $(dir $@)
	@$(CC) -c $(CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[032m$(CC)\033[0m	$<"
	@$(CC) -c $(CFLAGS) -o $@ $<

.PHONY: install_liba install_libso install_bin install_hdrs install_libs install_bins clean_objs

ifneq ($(LIB_NAME_A), )
$(OUT_PATH)/$(LIB_NAME_A): $(OBJS)
	@echo "\033[032mlib:\033[0m	\033[44m$@\033[0m"
	@$(AR) r $@ $^

install_liba:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@install $(OUT_PATH)/$(LIB_NAME_A) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(LIB_NAME_SO), )
$(OUT_PATH)/$(LIB_NAME_SO): $(OBJS)
	@echo "\033[032mlib:\033[0m	\033[44m$@\033[0m"
	@$(CC) -shared -fPIC -o $@ $^

install_libso:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@install $(OUT_PATH)/$(LIB_NAME_SO) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(BIN_NAME), )
$(OUT_PATH)/$(BIN_NAME): $(OBJS)
	@echo "\033[032mbin:\033[0m	\033[44m$@\033[0m"
	@$(CC) -o $@ $^ $(LDFLAGS)

install_bin:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@install $(OUT_PATH)/$(BIN_NAME) $(ENV_INS_ROOT)/usr/bin
endif

ifneq ($(INSTALL_HEADERS), )
install_hdrs:
	@install -d $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
	@cp -fp $(INSTALL_HEADERS) $(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)
endif

ifneq ($(INSTALL_LIBRARIES), )
install_libs:
	@install -d $(ENV_INS_ROOT)/usr/lib
	@install $(INSTALL_LIBRARIES) $(ENV_INS_ROOT)/usr/lib
endif

ifneq ($(INSTALL_BINARIES), )
install_bins:
	@install -d $(ENV_INS_ROOT)/usr/bin
	@install $(INSTALL_BINARIES) $(ENV_INS_ROOT)/usr/bin
endif

clean_objs:
	@-rm -rf $(OBJS) $(DEPS)
