PACKAGE_NAME     = lua

include $(ENV_MAKE_DIR)/inc.env.mk

VERSION          = 5.4.4
SRC_DIR          = $(PACKAGE_NAME)-$(VERSION)
SRC_NAME         = $(SRC_DIR).tar.gz
SRC_URL          = http://www.lua.org/ftp/$(SRC_NAME)
SRC_MD5          = bd8ce7069ff99a400efd14cf339a727b

PATCH_FOLDER     = $(shell pwd)/patch
CACHE_CHECKSUM  += $(PATCH_FOLDER)
CACHE_DEPENDS    = none
MAKES_FLAGS      = INSTALL_TOP=$(INS_PATH)$(INS_SUBDIR) INSTALL_MAN=$(INS_PATH)$(INS_SUBDIR)/share/man/man1 INSTALL_DATA="cp -rfp" -C $(SRC_PATH)
MAKES_FLAGS     += $(if $(CROSS_COMPILE),CC=$(CC) AR="$(AR) rcs" RANLIB="$(RANLIB) -D")

include $(ENV_MAKE_DIR)/inc.cache.mk
