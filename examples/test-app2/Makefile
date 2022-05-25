PACKAGE_NAME ?= test-app2 
PACKAGE_DEPS ?= test-app 

BIN_NAME = test2

LDFLAGS += -ltest

.PHONY: all clean install

all clean install:

include $(ENV_TOP_DIR)/scripts/inc.app.mk

all: $(OUT_PATH)/$(BIN_NAME)
	@echo "\033[32m---- build ok ----\033[0m"

clean: clean_objs
	@rm -f $(OUT_PATH)/$(BIN_NAME)
	@echo "\033[32m---- clean ok ----\033[0m"

ifneq ($(ENV_BUILD_MODE), yocto)
all: install
endif
install: install_bin

