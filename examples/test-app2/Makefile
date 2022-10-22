PACKAGE_NAME ?= test-app2
PACKAGE_DEPS ?= test-app

BIN_NAME = test2

LDFLAGS += -ltest

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_TOP_DIR)/scripts/core/inc.env.mk
include $(ENV_TOP_DIR)/scripts/core/inc.app.mk
include $(ENV_TOP_DIR)/scripts/core/inc.ins.mk

all: $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_bins
