ifeq ($(USING_EXT_BUILD), y)
OUT_PATH       ?= $(shell pwd | sed "s:$(ENV_TOP_DIR):$(ENV_TOP_OUT):")
else
OUT_PATH       ?= .
endif

SRC_PATH       ?= .
SRCS           ?= $(shell find $(SRC_PATH) -name "*.c" | grep -v "scripts/" | sed "s/\(\.\/\)\(.*\)/\2/g" | xargs)
OBJS            = $(patsubst %.c,$(OUT_PATH)/%.o,$(SRCS))
DEPS            = $(patsubst %.c,$(OUT_PATH)/%.d,$(SRCS))

CFLAGS         += -I$(SRC_PATH)/ -I$(SRC_PATH)/include/
CFLAGS         += -ffunction-sections -fdata-sections -O2
#CFLAGS        += -O0 -g -ggdb
LDFLAGS        += -Wl,--gc-sections
#LDFLAGS       += -static

.PHONY: cleanobjs

cleanobjs:
	@-rm -rf $(OBJS) $(DEPS)

-include $(DEPS)

$(OBJS): $(OUT_PATH)/%.o: %.c
	@-mkdir -p $(dir $@)
	@$(CC) -c $(CFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[032m$(CC)\033[0m	$<"
	@$(CC) -c $(CFLAGS) -o $@ $<

$(OUT_PATH)/$(LIB_NAME_A): $(OBJS)
	@echo "\033[032mlib:\033[0m	\033[44m$@\033[0m"
	@$(AR) r $@ $^

$(OUT_PATH)/$(LIB_NAME_SO): $(OBJS)
	@echo "\033[032mlib:\033[0m	\033[44m$@\033[0m"
	@$(CC) -shared -fPIC -o $@ $^

$(OUT_PATH)/$(BIN_NAME): $(OBJS)
	@echo "\033[032mbin:\033[0m	\033[44m$@\033[0m"
	@$(CC) -o $@ $^ $(LDFLAGS)

