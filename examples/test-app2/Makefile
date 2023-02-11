PACKAGE_NAME ?= test-app2
SEARCH_HDRS ?= test-app

BIN_NAME = test2

LDFLAGS += -ltest

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_MAKE_DIR)/inc.env.mk
include $(ENV_MAKE_DIR)/inc.app.mk
include $(ENV_MAKE_DIR)/inc.ins.mk

all: $(BIN_TARGETS)

clean: clean_objs
	@rm -f $(BIN_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_bins
