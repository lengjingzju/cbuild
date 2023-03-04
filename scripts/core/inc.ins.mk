############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

ifeq ($(KERNELRELEASE), )

# Defines the GNU standard installation directories
# Note: base_*dir and hdrdir are not defined in the GNUInstallDirs
# GNUInstallDirs/Autotools: https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
# CMake: https://cmake.org/cmake/help/latest/module/GNUInstallDirs.html
# Meson: https://mesonbuild.com/Builtin-options.html#directories
# Yocto: https://git.yoctoproject.org/poky/tree/meta/conf/bitbake.conf

base_bindir     = /bin
base_sbindir    = /sbin
base_libdir     = /lib
bindir          = /usr/bin
sbindir         = /usr/sbin
libdir          = /usr/lib
libexecdir      = /usr/libexec
hdrdir          = /usr/include/$(INSTALL_HDR)
includedir      = /usr/include
datarootdir     = /usr/share
datadir         = $(datarootdir)
infodir         = $(datadir)/info
localedir       = $(datadir)/locale
mandir          = $(datadir)/man
docdir          = $(datadir)/doc
sysconfdir      = /etc
servicedir      = /srv
sharedstatedir  = /com
localstatedir   = /var
runstatedir     = /run

# Defines the compatible variables with previous inc.ins.mk

INSTALL_BASE_BINARIES  ?= $(INSTALL_BINARIES)
INSTALL_BASE_BINS      ?= $(INSTALL_BASE_BINARIES)
INSTALL_BINS           ?= $(INSTALL_BINARIES)
INSTALL_BASE_LIBRARIES ?= $(INSTALL_LIBRARIES)
INSTALL_BASE_LIBS      ?= $(INSTALL_BASE_LIBRARIES)
INSTALL_LIBS           ?= $(INSTALL_LIBRARIES)
INSTALL_HDRS           ?= $(INSTALL_HEADERS)

# Defines the installation functions and targets

define install_obj
.PHONY: install_$(1)s
install_$(1)s:
	@install -d $$(INS_PREFIX)$$($(1)dir)
	@$$(call safe_copy,$(2),$$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')) $$(INS_PREFIX)$$($(1)dir))
endef

define install_ext
install_$(1)s_%:
	@ivar="$$($(shell echo install_$(1)s | tr 'a-z' 'A-Z')$$(patsubst install_$(1)s%,%,$$@))"; \
	isrc="$$$$(echo $$$${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$$$//g')"; \
	idst="$$(INS_PREFIX)$$($(1)dir)$$$$(echo $$$${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$$$/\1/g')"; \
	install -d $$$${idst} && $$(call safe_copy,$(2),$$$${isrc} $$$${idst})
endef

$(eval $(call install_obj,base_bin,-drf))
$(eval $(call install_obj,base_sbin,-drf))
$(eval $(call install_obj,base_lib,-drf))
$(eval $(call install_obj,bin,-drf))
$(eval $(call install_obj,sbin,-drf))
$(eval $(call install_obj,lib,-drf))
$(eval $(call install_obj,libexec,-drf))
$(eval $(call install_obj,hdr,-drfp))
$(eval $(call install_obj,include,-drfp))
$(eval $(call install_obj,data,-drf))
$(eval $(call install_obj,info,-drf))
$(eval $(call install_obj,locale,-drf))
$(eval $(call install_obj,man,-drf))
$(eval $(call install_obj,doc,-drf))
$(eval $(call install_obj,sysconf,-drf))
$(eval $(call install_obj,service,-drf))
$(eval $(call install_obj,sharedstate,-drf))
$(eval $(call install_obj,localstate,-drf))
$(eval $(call install_obj,runstate,-drf))

$(eval $(call install_ext,include,-drfp))
$(eval $(call install_ext,data,-drf))
$(eval $(call install_ext,sysconf,-drf))

install_todir_%:
	@ivar="$($(shell echo install_todir | tr 'a-z' 'A-Z')$(patsubst install_todir%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	iopt="-drf"; \
	if [ $$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g' | grep -c '/include') -eq 1 ]; then \
		iopt="-drfp"; \
	fi; \
	install -d $${idst} && $(call safe_copy,$${iopt},$${isrc} $${idst})

install_tofile_%:
	@ivar="$($(shell echo install_tofile | tr 'a-z' 'A-Z')$(patsubst install_tofile%,%,$@))"; \
	isrc="$$(echo $${ivar} | sed -E 's/\s+[a-zA-Z0-9/@_\.\-]+$$//g')"; \
	idst="$(INS_PREFIX)$$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g')"; \
	iopt="-drf"; \
	if [ $$(echo $${ivar} | sed -E 's/.*\s+([a-zA-Z0-9/@_\.\-]+)$$/\1/g' | grep -c '/include') -eq 1 ]; then \
		iopt="-drfp"; \
	fi; \
	install -d $$(dirname $${idst}) && $(call safe_copy,$${iopt},$${isrc} $${idst})

.PHONY: install_sysroot
install_sysroot:
	@install -d $(INS_PREFIX); \
	for v1 in $$(ls $(INSTALL_SYSROOT)); do \
		if [ "$${v1}" = "usr" ]; then \
			install -d $(INS_PREFIX)/$${v1}; \
			for v2 in $$(ls $(INSTALL_SYSROOT)/$${v1}); do \
				if [ "$${v2}" = "local" ]; then \
					install -d $(INS_PREFIX)/$${v1}/$${v2}; \
					for v3 in $$(ls $(INSTALL_SYSROOT)/$${v1}/$${v2}); do \
						if [ "$${v2}" = "include" ]; then \
							$(call safe_copy,-drfp,$(INSTALL_SYSROOT)/$${v1}/$${v2}/$${v3} $(INS_PREFIX)/$${v1}/$${v2}); \
						else \
							$(call safe_copy,-drf,$(INSTALL_SYSROOT)/$${v1}/$${v2}/$${v3} $(INS_PREFIX)/$${v1}/$${v2}); \
						fi; \
					done; \
				elif [ "$${v2}" = "include" ]; then \
					$(call safe_copy,-drfp,$(INSTALL_SYSROOT)/$${v1}/$${v2} $(INS_PREFIX)/$${v1}); \
				else \
					$(call safe_copy,-drf,$(INSTALL_SYSROOT)/$${v1}/$${v2} $(INS_PREFIX)/$${v1}); \
				fi; \
			done; \
		elif [ "$${v1}" = "include" ]; then \
			$(call safe_copy,-drfp,$(INSTALL_SYSROOT)/$${v1} $(INS_PREFIX)); \
		else \
			$(call safe_copy,-drf,$(INSTALL_SYSROOT)/$${v1} $(INS_PREFIX)); \
		fi; \
	done

endif
