.PHONY: params_kconfig all clean

OUT_PATH = $(shell pwd | sed 's:$(ENV_TOP_DIR):$(ENV_OUT_ROOT):')/params
KCONFIG  = Kconfig.params

all:

include $(ENV_TOP_DIR)/scripts/core/inc.conf.mk

all: menuconfig

buildkconfig: params_kconfig
params_kconfig:
	@python3 $(ENV_TOP_DIR)/scripts/bin/analyse_kconf.py -m mk.kconf -k $(KCONFIG) -f mk.deps -d pa:pb:pc:pd:pe

clean: cleanconfig
	-rm -f $(KCONFIG) 
