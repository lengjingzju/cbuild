ifeq ($(ENV_BUILD_MODE), external)
OUT_PATH       ?= $(shell pwd | sed 's:$(ENV_TOP_DIR):$(ENV_TOP_OUT):')
else
OUT_PATH       ?= .
endif

AUTOGEN_BISON   = $(OUT_PATH)/autogen/parser.tab.c $(OUT_PATH)/autogen/parser.tab.h
AUTOGEN_FLEX    = $(OUT_PATH)/autogen/lexer.lex.c
AUTOGEN_OBJS    = $(OUT_PATH)/autogen/parser.tab.o $(OUT_PATH)/autogen/lexer.lex.o
PARSER_OBJS     = $(patsubst %.c,$(OUT_PATH)/%.o,$(wildcard parser/*.c))
LXDIALOG_OBJS   = $(patsubst %.c,$(OUT_PATH)/%.o,$(wildcard lxdialog/*.c))
CONF_OBJS       = $(patsubst %.c,$(OUT_PATH)/%.o,conf.c)
MCONF_OBJS      = $(patsubst %.c,$(OUT_PATH)/%.o,mconf.c)
DEPEND_OBJS     = $(patsubst %.o,%.d,$(AUTOGEN_OBJS) $(PARSER_OBJS) $(LXDIALOG_OBJS) $(CONF_OBJS) $(MCONF_OBJS))

HOSTCC         ?= gcc
HOSTCFLAGS      = -I. -I./parser -I./lxdialog

ifneq ($(ENV_BUILD_MODE), yocto)
HOSTCFLAGS     += $(shell sh mconf-cfg.sh | grep "cflags=" | sed 's/cflags="\(.*\)"/\1/')
HOSTLDFLAGS     = $(shell sh mconf-cfg.sh | grep "libs=" | sed 's/libs="\(.*\)"/\1/')
else
HOSTCFLAGS     += -D_GNU_SOURCE -D_DEFAULT_SOURCE
HOSTLDFLAGS     = -lncurses -ltinfo
endif

.PHONY: all clean
all: $(OUT_PATH)/conf $(OUT_PATH)/mconf

clean:
	@-rm -rf $(OUT_PATH)/conf $(OUT_PATH)/mconf $(DEPEND_OBJS) \
		$(AUTOGEN_BISON) $(AUTOGEN_FLEX) $(AUTOGEN_OBJS) \
		$(PARSER_OBJS) $(LXDIALOG_OBJS) $(CONF_OBJS) $(MCONF_OBJS)

-include $(DEPEND_OBJS)

$(AUTOGEN_BISON): autogen/parser.y
	@-mkdir -p $(dir $@)
	@echo "\033[32mbison\033[0m	$@"
	@bison -o $(basename $@).c --defines=$(basename $@).h -t -l $<

$(AUTOGEN_FLEX): autogen/lexer.l
	@-mkdir -p $(dir $@)
	@echo "\033[32mflex\033[0m	$@"
	@flex -o $@ -L $<

$(AUTOGEN_OBJS) : %.o:%.c
	@-mkdir -p $(dir $@)
	@$(HOSTCC) $(HOSTCFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[32m$(HOSTCC)\033[0m	$<"
	@$(HOSTCC) $(HOSTCFLAGS) -c -o $@ $<

$(PARSER_OBJS) $(LXDIALOG_OBJS) $(CONF_OBJS) $(MCONF_OBJS): $(OUT_PATH)/%.o:%.c
	@-mkdir -p $(dir $@)
	@$(HOSTCC) $(HOSTCFLAGS) -MM -MT $@ -MF $(patsubst %.o,%.d,$@) $<
	@echo "\033[32m$(HOSTCC)\033[0m	$<"
	@$(HOSTCC) $(HOSTCFLAGS) -c -o $@ $<

$(OUT_PATH)/conf: $(AUTOGEN_OBJS) $(PARSER_OBJS) $(CONF_OBJS)
	@echo "\033[32m$(HOSTCC)\033[0m	\033[44m$@\033[0m"
	@$(HOSTCC) -o $@ $^ $(HOSTLDFLAGS)

$(OUT_PATH)/mconf: $(AUTOGEN_OBJS) $(PARSER_OBJS) $(LXDIALOG_OBJS) $(MCONF_OBJS)
	@echo "\033[32m$(HOSTCC)\033[0m	\033[44m$@\033[0m"
	@$(HOSTCC) -o $@ $^ $(HOSTLDFLAGS)

