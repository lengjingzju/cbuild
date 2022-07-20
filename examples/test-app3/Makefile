PACKAGE_NAME ?= test-app3

add-srcs = add.c
SRCS += $(add-srcs)
sub-srcs = sub.c
SRCS += $(sub-srcs)
mul-srcs = mul.c
SRCS += $(mul-srcs)
div-srcs = div.c
SRCS += $(div-srcs)

.PHONY: all clean install

all:
	@echo "Build $(PACKAGE_NAME) Done."

include $(ENV_TOP_DIR)/scripts/core/inc.app.mk

$(eval $(call add-liba-build,libadd.a,$(add-srcs)))
$(eval $(call add-libso-build,libadd.so 1 2 3,$(add-srcs)))
$(eval $(call add-liba-build,libsub.a,$(sub-srcs)))
$(eval $(call add-libso-build,libsub.so 1 2,$(sub-srcs)))
$(eval $(call add-liba-build,libmul.a,$(mul-srcs)))
$(eval $(call add-libso-build,libmul.so 1,$(mul-srcs)))
$(eval $(call add-liba-build,libdiv.a,$(div-srcs)))
$(eval $(call add-libso-build,libdiv.so,$(div-srcs)))

INSTALL_HEADERS = include/add.h include/sub.h include/mul.h include/div.h
INSTALL_LIBRARIES = $(LIB_TARGETS)
include $(ENV_TOP_DIR)/scripts/core/inc.ins.mk

all: $(LIB_TARGETS)

clean: clean_objs
	@rm -f $(LIB_TARGETS)
	@echo "Clean $(PACKAGE_NAME) Done."

install: install_libs install_hdrs
