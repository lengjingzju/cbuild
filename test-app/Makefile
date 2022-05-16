
BIN_NAME = test
LIB_NAME_A = libtest.a
LIB_NAME_SO = libtest.so

.PHONY: all clean
all clean:

include $(ENV_TOP_DIR)/scripts/inc.app.mk

all: $(OUT_PATH)/$(LIB_NAME_A) $(OUT_PATH)/$(LIB_NAME_SO) $(OUT_PATH)/$(BIN_NAME)
	@echo "\033[32m---- build ok ----\033[0m"

clean: cleanobjs
	@rm -f $(OUT_PATH)/$(LIB_NAME_A) $(OUT_PATH)/$(LIB_NAME_SO) $(OUT_PATH)/$(BIN_NAME)
	@echo "\033[32m---- clean ok ----\033[0m"

