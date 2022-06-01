PACKAGE_NAME ?= test-app2 
PACKAGE_DEPS ?= test-app 

BIN_NAME = test2

LDFLAGS += -ltest

.PHONY: all clean install

all clean install:

include $(ENV_TOP_DIR)/scripts/core/inc.app.mk

all: $(OUT_PATH)/$(BIN_NAME)
	@echo "Build $(PACKAGE_NAME) Done."

clean: clean_objs
	@rm -f $(OUT_PATH)/$(BIN_NAME)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_bin
