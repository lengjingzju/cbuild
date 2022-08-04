# CBuild 编译系统

## 特点

* Linux 下纯粹的 Makefile 编译
* 支持 C / C++ / 汇编混合编译
* 支持交叉编译，支持自动分析头文件和编译脚本文件作为编译依赖，支持分别指定源文件的 CFLAGS
* 一个 Makefile 同时支持 Yocto 编译方式、源码和编译输出分离模式和不分离模式
* 一个 Makefile 支持生成多个库、可执行文件或模块
* 提供编译静态库、共享库和可执行文件的模板 `inc.app.mk`
* 提供安装编译输出的模板 `inc.ins.mk`
* 提供 kconfig 配置参数的模板 `inc.conf.mk`
* 提供编译外部内核模块的模板 `inc.mod.mk`
* 提供根据目标依赖关系自动生成编译开关配置和编译顺序的脚本 `analyse_deps.py`
* 提供自动收集配置生成总配置的脚本 `analyse_kconf.py`

## 开源贡献

本工程目前已向 Linux 内核社区贡献了2次提交，已合并到 Linux 内核主线

* [kconfig: fix failing to generate auto.conf](https://git.kernel.org/pub/scm/linux/kernel/git/masahiroy/linux-kbuild.git/commit/?h=fixes&id=1b9e740a81f91ae338b29ed70455719804957b80)

```sh
commit 1b9e740a81f91ae338b29ed70455719804957b80
Author: Jing Leng <jleng@ambarella.com>
Date:   Fri Feb 11 17:27:36 2022 +0800

    kconfig: fix failing to generate auto.conf

    When the KCONFIG_AUTOCONFIG is specified (e.g. export \
    KCONFIG_AUTOCONFIG=output/config/auto.conf), the directory of
    include/config/ will not be created, so kconfig can't create deps
    files in it and auto.conf can't be generated.
```

* [kbuild: Fix include path in scripts/Makefile.modpost](https://git.kernel.org/pub/scm/linux/kernel/git/masahiroy/linux-kbuild.git/commit/?h=fixes&id=23a0cb8e3225122496bfa79172005c587c2d64bf)

```sh
commit 23a0cb8e3225122496bfa79172005c587c2d64bf
Author: Jing Leng <jleng@ambarella.com>
Date:   Tue May 17 18:51:28 2022 +0800

    kbuild: Fix include path in scripts/Makefile.modpost

    When building an external module, if users don't need to separate the
    compilation output and source code, they run the following command:
    "make -C $(LINUX_SRC_DIR) M=$(PWD)". At this point, "$(KBUILD_EXTMOD)"
    and "$(src)" are the same.

    If they need to separate them, they run "make -C $(KERNEL_SRC_DIR)
    O=$(KERNEL_OUT_DIR) M=$(OUT_DIR) src=$(PWD)". Before running the
    command, they need to copy "Kbuild" or "Makefile" to "$(OUT_DIR)" to
    prevent compilation failure.

    So the kernel should change the included path to avoid the copy operation.
```

## 初始化编译环境

初始化编译环境运行如下命令

```sh
lengjing@lengjing:~/cbuild$ source scripts/build.env
============================================================
ARCH             :
CROSS_COMPILE    :
ENV_TOP_DIR      : /home/lengjing/cbuild
ENV_TOP_OUT      : /home/lengjing/cbuild/output
ENV_OUT_ROOT     : /home/lengjing/cbuild/output/objects
ENV_INS_ROOT     : /home/lengjing/cbuild/output/sysroot
ENV_DEP_ROOT     : /home/lengjing/cbuild/output/sysroot
ENV_BUILD_MODE   : external
============================================================
```

还可以指定 ARCH 和交叉编译器

```sh
lengjing@lengjing:~/cbuild$ source scripts/build.env arm64 arm-linux-gnueabihf-
============================================================
ARCH             : arm64
CROSS_COMPILE    : arm-linux-gnueabihf-
ENV_TOP_DIR      : /home/lengjing/cbuild
ENV_TOP_OUT      : /home/lengjing/cbuild/output
ENV_OUT_ROOT     : /home/lengjing/cbuild/output/objects
ENV_INS_ROOT     : /home/lengjing/cbuild/output/sysroot
ENV_DEP_ROOT     : /home/lengjing/cbuild/output/sysroot
ENV_BUILD_MODE   : external
============================================================

```

`scripts/build.env` 中，导出的自定义环境变量

```sh
ENV_TOP_DIR=$(pwd | sed 's:/cbuild.*::')/cbuild
ENV_TOP_OUT=${ENV_TOP_DIR}/output
ENV_OUT_ROOT=${ENV_TOP_OUT}/objects
ENV_INS_ROOT=${ENV_TOP_OUT}/sysroot
ENV_DEP_ROOT=${ENV_INS_ROOT}
ENV_BUILD_MODE=external  # external internal yocto
```

* ENV_TOP_DIR: 工程的根目录
* ENV_TOP_OUT: 工程的输出根目录，编译输出、安装文件、生成镜像等都在此目录下定义
* ENV_OUT_ROOT: 源码和编译输出分离时的编译输出根目录
* ENV_INS_ROOT: 工程安装文件的根目录
* ENV_DEP_ROOT: 工程搜索库和头文件的根目录
* ENV_BUILD_MODE: 设置编译模式: external, 源码和编译输出分离; internal, 编译输出到源码; yocto, Yocto 编译方式
    * external 时，编译输出目录是把包的源码目录的 ENV_TOP_DIR 部分换成了 ENV_OUT_ROOT

注: yocto 编译时，由于 BitBake 任务无法直接使用当前 shell 的环境变量，所以自定义环境变量应由配方文件导出，不需要 source 这个环境脚本

## 测试编译应用

测试用例1位于 `test-app`
测试用例2位于 `test-app2` (`test-app2` 依赖 `test-app`)，
测试用例3位于 `test-app3` (`test-app3` 一个 Makefile 生成多个库)，如下测试

```sh
lengjing@lengjing:~/cbuild$ cd examples/test-app
lengjing@lengjing:~/cbuild/examples/test-app$ make
gcc	add.c
gcc	sub.c
gcc	main.c
lib:	/home/lengjing/cbuild/output/objects/examples/test-app/libtest.a
lib:	/home/lengjing/cbuild/output/objects/examples/test-app/libtest.so
bin:	/home/lengjing/cbuild/output/objects/examples/test-app/test
Build test-app Done.
lengjing@lengjing:~/cbuild/examples/test-app$ vi include/sub.h  # 在此文件加上一个空行保存
lengjing@lengjing:~/cbuild/examples/test-app$ make  # 此时依赖此头文件的 C 源码会重新编译
gcc	sub.c
gcc	main.c
lib:	/home/lengjing/cbuild/output/objects/examples/test-app/libtest.a
lib:	/home/lengjing/cbuild/output/objects/examples/test-app/libtest.so.1.2.3
bin:	/home/lengjing/cbuild/output/objects/examples/test-app/test
Build test-app Done.
lengjing@lengjing:~/cbuild/examples/test-app$ make install  # 安装文件
lengjing@lengjing:~/cbuild/examples/test-app$ cd ../test-app2
lengjing@lengjing:~/cbuild/examples/test-app2$ make
gcc	main.c
bin:	/home/lengjing/cbuild/output/objects/examples/test-app2/test2
Build test-app2  Done.
lengjing@lengjing:~/cbuild/examples/test-app2$ make install
lengjing@lengjing:~/cbuild/examples/test-app2$ cd ../test-app3/
lengjing@lengjing:~/cbuild/examples/test-app3$ make
gcc	add.c
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libadd.a
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libadd.so.1.2.3
gcc	sub.c
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libsub.a
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libsub.so.1.2
gcc	mul.c
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libmul.a
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libmul.so.1
gcc	div.c
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libdiv.a
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libdiv.so
lib:	/home/lengjing/cbuild/output/objects/examples/test-app3/libadd2.so.1.2.3
Build test-app3 Done.
lengjing@lengjing:~/cbuild/examples/test-app3$ make install
```

`scripts/core/inc.app.mk` 支持的目标

* LIBA_NAME: 编译静态库时需要设置静态库名
* LIBSO_NAME: 编译动态库时需要设置动态库名
    * LIBSO_NAME 可以设置为 `库名 主版本号 次版本号 补丁版本号` 格式，例如
        * `LIBSO_NAME = libtest.so 1 2 3` 编译生成动态库 libtest.so.1.2.3，并创建符号链接 libtest.so 和 libtest.so.1
        * `LIBSO_NAME = libtest.so 1 2`   编译生成动态库 libtest.so.1.2  ，并创建符号链接 libtest.so 和 libtest.so.1
        * `LIBSO_NAME = libtest.so 1`     编译生成动态库 libtest.so.1    ，并创建符号链接 libtest.so
        * `LIBSO_NAME = libtest.so`       编译生成动态库 libtest.so
    * 如果 LIBSO_NAME 带版本号，默认指定的 soname 是 `libxxxx.so.x`，可以通过 LDFLAGS 覆盖默认值
        * 例如 `LDFLAGS += -Wl,-soname=libxxxx.so`
* BIN_NAME: 编译可执行文件时需要设置可执行文件名
* install_liba: 安装静态库
* install_libso: 安装动态库
* install_bin: 安装可执行文件
* install_hdr: 安装头文件集
    * 用户需要设置被安装的头文件集变量 INSTALL_HEADER 或/与 INSTALL_PRIVATE_HEADER
    * INSTALL_HEADER 指定的头文件的安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)`
    * INSTALL_PRIVATE_HEADER 指定的头文件的安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private`

`scripts/core/inc.app.mk` 提供的函数

* `$(eval $(call add-liba-build,静态库名,源文件列表))`: 创建编译静态库规则
* `$(eval $(call add-libso-build,动态库名,源文件列表))`: 创建编译动态库规则
    * 动态库名可以设置为 `库名 主版本号 次版本号 补丁版本号` 格式，参考 LIBSO_NAME 的说明
* `$(eval $(call add-libso-build,动态库名,源文件列表,链接参数))`: 创建编译动态库规则
    * 注意函数中有逗号要用变量覆盖: `$(eval $(call add-libso-build,动态库名,源文件列表,-Wl$(comma)-soname=libxxxx.so))`
* `$(eval $(call add-bin-build,可执行文件名,源文件列表))`: 创建编译可执行文件规则
* `$(eval $(call add-bin-build,可执行文件名,源文件列表,链接参数))`: 创建编译可执行文件规则

注: 提供上述函数的原因是可以在一个 Makefile 中编译出多个库或可执行文件

`scripts/core/inc.ins.mk` 支持的目标
* install_hdrs: 安装头文件集
    * 用户需要设置被安装的头文件集变量 INSTALL_HEADERS 或/与 INSTALL_PRIVATE_HEADERS
    * INSTALL_HEADERS 指定的头文件的安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)`
    * INSTALL_PRIVATE_HEADERS 指定的头文件的安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private`
* install_libs: 安装库文件集
    * 用户需要设置被安装的库文件集变量 INSTALL_LIBRARIES
    * 安装目录是 `$(ENV_INS_ROOT)/usr/lib`
    * 编译生成的库文件会加入到 `LIB_TARGETS` 变量，可以将它赋值给 INSTALL_LIBRARIES
* install_bins: 安装可执行文件集
    * 用户需要设置被安装的可执行文件集变量 INSTALL_BINARIES
    * 安装目录是 `$(ENV_INS_ROOT)/usr/bin`
    * 编译生成的可执行文件会加入到 `BIN_TARGETS` 变量，可以将它赋值给 INSTALL_BINARIES
* install_datas: 安装数据文件集
    * 用户需要设置被安装的数据文件集变量 INSTALL_DATAS
    * 安装目录是 `$(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)`
* install_datas_xxx: 安装数据文件集到特定文件夹xxx
    * 用户需要设置被安装的数据文件集变量 INSTALL_DATAS_xxx
    * 安装目录是 `$(ENV_INS_ROOT)/usr/share/xxx`

`scripts/core/inc.app.mk` 可设置的变量

* PACKAGE_NAME: 包的名称
* PACKAGE_DEPS: 包的依赖(多个依赖空格隔开)
    * 默认将包依赖对应的路径加到当前包的头文件和库文件的搜索路径
* OUT_PATH: 编译输出目录，保持默认即可
* SRC_PATH: 包中源码所在的目录，默认是包的根目录，也有的包将源码放在 src 下
* SRCS: 所有的 C 源码文件，默认是 SRC_PATH 下的所有的 `*.c *.cpp *.S` 文件
    * 如果用户指定了 SRCS，不需要再指定 SRC_PATH
* CFLAGS: 用户可以设置包自己的一些全局编译标记
* LDFLAGS: 用户可以设置包自己的一些全局链接标记
* CFLAGS_xxx.o: 用户可以单独为指定源码 xxx.c 设置编译标记

## 测试kconfig

测试用例位于 `test-conf`，如下测试

```sh
lengjing@lengjing:~/cbuild/examples/test-app3$ cd ../test-conf/
lengjing@lengjing:~/cbuild/examples/test-conf$ ls config/
def_config
lengjing@lengjing:~/cbuild/examples/test-conf$ make def_config  # 加载配置
bison	/home/lengjing/cbuild/output/objects/scripts/kconfig/autogen/parser.tab.c
gcc	/home/lengjing/cbuild/output/objects/scripts/kconfig/autogen/parser.tab.c
flex	/home/lengjing/cbuild/output/objects/scripts/kconfig/autogen/lexer.lex.c
gcc	/home/lengjing/cbuild/output/objects/scripts/kconfig/autogen/lexer.lex.c
gcc	parser/confdata.c
gcc	parser/menu.c
gcc	parser/util.c
gcc	parser/preprocess.c
gcc	parser/expr.c
gcc	parser/symbol.c
gcc	conf.c
gcc	/home/lengjing/cbuild/output/objects/scripts/kconfig/conf
gcc	lxdialog/checklist.c
gcc	lxdialog/inputbox.c
gcc	lxdialog/util.c
gcc	lxdialog/textbox.c
gcc	lxdialog/yesno.c
gcc	lxdialog/menubox.c
gcc	mconf.c
gcc	/home/lengjing/cbuild/output/objects/scripts/kconfig/mconf
#
# No change to /home/lengjing/cbuild/output/objects/examples/test-conf/.config
#
lengjing@lengjing:~/cbuild/examples/test-conf$ ls -a ${ENV_OUT_ROOT}/examples/test-conf
.  ..  .config  autoconfig  config.h
lengjing@lengjing:~/cbuild/examples/test-conf$ make menuconfig # 图形化界面修改配置
configuration written to /home/lengjing/cbuild/output/objects/examples/test-conf/.config

*** End of the configuration.
*** Execute 'make' to start the build or try 'make help'.

lengjing@lengjing:~/cbuild/examples/test-conf$ make def2_saveconfig  # 保存新配置
Save .config to config/def2_config
lengjing@lengjing:~/cbuild/examples/test-conf$ ls config/
def2_config  def_config
```

`scripts/core/inc.conf.mk` 支持的目标

* loadconfig: 加载默认配置
    * 如果 .config 不存在，加载 DEF_CONFIG 指定的配置
* menuconfig: 图形化配置工具
* cleanconfig: 清理配置文件
* xxx_config: 将 CONF_SAVE_PATH 下的 xxx_config 作为当前配置
* xxx_saveconfig: 将当前配置保存到 CONF_SAVE_PATH 下的 xxx_config
* xxx_defonfig: 将 CONF_SAVE_PATH 下的 xxx_defconfig 作为当前配置
* xxx_savedefconfig: 将当前配置保存到 CONF_SAVE_PATH 下的 xxx_defconfig

`scripts/core/inc.conf.mk` 可设置的变量

* OUT_PATH: 编译输出目录，保持默认即可
* CONF_SRC: kconfig 工具的源码目录，目前是在 `scripts/kconfig`，和实际一致即可
* CONF_PATH: kconfig 工具的编译输出目录，和实际一致即可
* CONF_PREFIX: 设置 conf 运行的变量，主要是 `srctree=$(path_name)`
    * Kconfig 文件中 source 其它配置参数文件的相对的目录是 srctree 指定的目录
* KCONFIG: 配置参数文件，默认是包下的 Kconfig 文件
* CONF_SAVE_PATH: 配置文件的获取和保存目录，默认是包下的 config 目录

注: 目录下的 [Kconfig](./examples/test-conf/Kconfig) 文件也说明了如何写配置参数

`scripts/kconfig` 工程说明

* 源码完全来自 linux-5.18 内核的 `scripts/kconfig`
* 在原始代码的基础上增加了命令传入参数 `CONFIG_PATH` `AUTOCONFIG_PATH` `AUTOHEADER_PATH`，原先这些参数要作为环境变量传入
* Makefile 是完全重新编写的

## 测试编译内核模块

测试用例1位于 `test-mod` (其中 test_hello 依赖于 test_hello_add 和 test_hello_sub)，其中 test_hello_sub 采用 Makefile 和 Kbuild 分离的模式
测试用例2位于 `test-mod2` (一个 Makefile 同时编译出两个模块 hello_op 和 hello)，如下测试

```sh
lengjing@lengjing:~/cbuild/examples/test-conf$ cd ../test-mod
lengjing@lengjing:~/cbuild/examples/test-mod$ make deps
Analyse depends OK.
lengjing@lengjing:~/cbuild/examples/test-mod$ make menuconfig
configuration written to /home/lengjing/cbuild/output/objects/examples/test-mod/.config

*** End of the configuration.
*** Execute 'make' to start the build or try 'make help'.

lengjing@lengjing:~/cbuild/examples/test-mod$ make all
KERNELRELEASE= pwd=/home/lengjing/cbuild/examples/test-mod/test-hello-add PWD=/home/lengjing/cbuild/examples/test-mod
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod
Skipping BTF generation for /home/lengjing/cbuild/output/objects/examples/test-mod/test-hello-add/hello_add.ko due to unavailability of vmlinux
Build test-hello-add Done.
KERNELRELEASE= pwd=/home/lengjing/cbuild/examples/test-mod/test-hello-add PWD=/home/lengjing/cbuild/examples/test-mod
arch/x86/Makefile:148: CONFIG_X86_X32 enabled but no binutils support
At main.c:160:
- SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:69
- SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:76
sign-file: certs/signing_key.pem: No such file or directory
Warning: modules_install: missing 'System.map' file. Skipping depmod.
KERNELRELEASE= pwd=/home/lengjing/cbuild/examples/test-mod/test-hello-sub PWD=/home/lengjing/cbuild/examples/test-mod
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod
Skipping BTF generation for /home/lengjing/cbuild/output/objects/examples/test-mod/test-hello-sub/hello_sub.ko due to unavailability of vmlinux
Build test-hello-sub Done.
KERNELRELEASE= pwd=/home/lengjing/cbuild/examples/test-mod/test-hello-sub PWD=/home/lengjing/cbuild/examples/test-mod
arch/x86/Makefile:148: CONFIG_X86_X32 enabled but no binutils support
At main.c:160:
- SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:69
- SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:76
sign-file: certs/signing_key.pem: No such file or directory
Warning: modules_install: missing 'System.map' file. Skipping depmod.
KERNELRELEASE= pwd=/home/lengjing/cbuild/examples/test-mod/test-hello PWD=/home/lengjing/cbuild/examples/test-mod
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod/test-hello
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod/test-hello
Skipping BTF generation for /home/lengjing/cbuild/output/objects/examples/test-mod/test-hello/hello_dep.ko due to unavailability of vmlinux
Build test-hello Done.
KERNELRELEASE= pwd=/home/lengjing/cbuild/examples/test-mod/test-hello PWD=/home/lengjing/cbuild/examples/test-mod
arch/x86/Makefile:148: CONFIG_X86_X32 enabled but no binutils support
At main.c:160:
- SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:69
- SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:76
sign-file: certs/signing_key.pem: No such file or directory
Warning: modules_install: missing 'System.map' file. Skipping depmod.
lengjing@lengjing:~/cbuild/examples/test-mod$
lengjing@lengjing:~/cbuild/examples/test-mod$
lengjing@lengjing:~/cbuild/examples/test-mod$ cd ../test-mod2
lengjing@lengjing:~/cbuild/examples/test-mod2$ make
KERNELRELEASE= pwd=/home/lengjing/cbuild/examples/test-mod2 PWD=/home/lengjing/cbuild/examples/test-mod2
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod2
KERNELRELEASE=5.13.0-44-generic pwd=/usr/src/linux-headers-5.13.0-44-generic PWD=/home/lengjing/cbuild/examples/test-mod2
Skipping BTF generation for /home/lengjing/cbuild/output/objects/examples/test-mod2/hello_op.ko due to unavailability of vmlinux
Skipping BTF generation for /home/lengjing/cbuild/output/objects/examples/test-mod2/hello_sec.ko due to unavailability of vmlinux
Build test-mod2 Done.
```

`scripts/core/inc.mod.mk` 支持的目标(KERNELRELEASE 为空时)

* modules: 编译外部内核模块
* modules_clean: 清理内核模块的编译输出
* modules_install: 安装内核模块到指定位置
    * 外部内核模块默认的安装路径为 `$(ENV_INS_ROOT)/lib/modules/<kernel_release>/extra/`
* modules_install_hdrs: 安装头文件集
    * 用户需要设置被安装的头文件集变量 INSTALL_HEADERS 或/与 INSTALL_PRIVATE_HEADERS
    * INSTALL_HEADERS 指定的头文件的安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)`
    * INSTALL_PRIVATE_HEADERS 指定的头文件的安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private`

`scripts/core/inc.mod.mk` 可设置的变量(KERNELRELEASE 为空时)

* PACKAGE_NAME: 包的名称
* PACKAGE_DEPS: 包的依赖(多个依赖空格隔开)
    * 默认将包依赖对应的路径加到当前包的头文件的搜索路径
* MOD_MAKES: 用户指定一些模块自己的信息，例如 XXXX=xxxx
* OUT_PATH: 编译输出目录，保持默认即可 (只在源码和编译输出分离时有效)
* KERNEL_SRC: Linux 内核源码目录 (必须）
* KERNEL_OUT: Linux 内核编译输出目录 （`make -O $(KERNEL_OUT)` 编译内核的情况下必须）

`scripts/core/inc.mod.mk` 支持的目标(KERNELRELEASE 有值时)

* MOD_NAME: 模块名称，可以是多个模块名称使用空格隔开

`scripts/core/inc.mod.mk` 可设置的变量(KERNELRELEASE 有值时)

* SRCS: 所有的 C 源码文件，默认是当前目录下的所有的 `*.c` 文件
* `ccflags-y` `asflags-y` `ldflags-y`: 分别对应内核模块编译、汇编、链接时的参数

注：如果 MOD_NAME 含有多个模块名称，需要用户自己填写各个模块下的对象，例如

```makefile
MOD_NAME = mod1 mod2
mod1-y = a1.o b1.o c1.o
mod2-y = a2.o b2.o c2.o
```

不同的模块编译方式

* 源码和编译输出同目录时编译命令: `make -C $(KERNEL_SRC) M=$(shell pwd) modules`
* 源码和编译输出分离时编译命令: `make -C $(KERNEL_SRC) O=(KERNEL_OUT) M=$(OUT_PATH) src=$(shell pwd) modules`

注: 使用源码和编译输出分离时， 需要先将 Kbuild 或 Makefile 复制到 OUT_PATH 目录下，如果不想复制，需要修改内核源码的 `scripts/Makefile.modpost`，最新 linux-5.19 已合并此补丁

```makefile
-include $(if $(wildcard $(KBUILD_EXTMOD)/Kbuild), \
-             $(KBUILD_EXTMOD)/Kbuild, $(KBUILD_EXTMOD)/Makefile)
+include $(if $(wildcard $(src)/Kbuild), $(src)/Kbuild, $(src)/Makefile)
```

模块编译过程说明

1. 在当前目录运行 Makefile，此时 KERNELRELEASE 为空，执行这个分支下的第一个目标 modules
2. 运行`make -C $(KERNEL_SRC) xxx` 时进入内核源码目录，在内核源码目录运行 src 的 Kbuild 或 Makefile，此时 KERNELRELEASE 有值，编译源文件
3. 继续在内核源码目录运行 M 目录的 Kbuild 或 Makefile，生成模块和它的符号表

## 测试自动生成总编译

测试用例位于 `test-deps`，如下测试

```sh
lengjing@lengjing:~/cbuild/examples/test-mod2$ cd ../test-deps
lengjing@lengjing:~/cbuild/examples/test-deps$ make deps
Analyse depends OK.
lengjing@lengjing:~/cbuild/examples/test-deps$ make menuconfig
configuration written to /home/lengjing/cbuild/output/objects/examples/test-deps/.config

*** End of the configuration.
*** Execute 'make' to start the build or try 'make help'.

lengjing@lengjing:~/cbuild/examples/test-deps$ make all
ext.mk
target=all path=/home/lengjing/cbuild/examples/test-deps/pc/pc
ext.mk
target=install path=/home/lengjing/cbuild/examples/test-deps/pc/pc
target=all path=/home/lengjing/cbuild/examples/test-deps/pe/pe
target=install path=/home/lengjing/cbuild/examples/test-deps/pe/pe
target=all path=/home/lengjing/cbuild/examples/test-deps/pd/pd
target=install path=/home/lengjing/cbuild/examples/test-deps/pd/pd
target=all path=/home/lengjing/cbuild/examples/test-deps/pb/pb
target=install path=/home/lengjing/cbuild/examples/test-deps/pb/pb
target=all path=/home/lengjing/cbuild/examples/test-deps/pa/pa
target=install path=/home/lengjing/cbuild/examples/test-deps/pa/pa
lengjing@lengjing:~/cbuild/examples/test-deps$ make config # 打开自动生成的总参数配置界面
lengjing@lengjing:~/cbuild/examples/test-deps$ make clean
ext.mk
target=clean path=/home/lengjing/cbuild/examples/test-deps/pc/pc
target=clean path=/home/lengjing/cbuild/examples/test-deps/pe/pe
target=clean path=/home/lengjing/cbuild/examples/test-deps/pd/pd
target=clean path=/home/lengjing/cbuild/examples/test-deps/pb/pb
target=clean path=/home/lengjing/cbuild/examples/test-deps/pa/pa
rm -f auto.mk Kconfig
```

`scripts/bin/analyse_deps.py` 参数

* `-m <Makefile Name>`: 自动生成的 Makefile 文件名
* `-k <Kconfig Name>`: 自动生成的 Kconfig 文件名
    * 还会在 Kconfig 同目录生成 Target 文件，列出所有包的文件路径、包名和依赖
* `-f <Search Depend Name>`: 要搜索的依赖文件名(含有依赖信息)
* `-d <Search Directories>`: 搜索的目录名，多个目录使用冒号隔开
* `-i <Ignore Directories>`: 忽略的目录名，不会搜索指定目录名下的依赖文件，多个目录使用冒号隔开
* `-t <Max Tier Depth>`: 设置 menuconfig 菜单的最大层数，0 表示菜单平铺，1表示2层菜单，...
* `-w <Keyword Directories>`: 用于 menuconfig 菜单，如果路径中的目录匹配设置值，则这个路径的层数减1，设置的多个目录使用冒号隔开

`scripts/bin/analyse_kconf.py` 参数

* `-k <Kconfig Name>`: 自动生成的 Kconfig 文件名
* `-m <Search Kconfig Name>`: 要搜索的配置文件名(含有配置信息)
* `-f <Search Depend Name>`: 同 analyse_deps.py
* `-d <Search Directories>`: 同 analyse_deps.py
* `-i <Ignore Directories>`: 同 analyse_deps.py
* `-t <Max Tier Depth>`: 同 analyse_deps.py
* `-w <Keyword Directories>`: 同 analyse_deps.py

注: 如果在当前目录下搜索到 `<Search Depend Name>`，不会再继续搜索当前目录的子目录; `<Search Depend Name>` 中可以包含多条依赖信息

依赖信息格式 `#DEPS(Makefile_Name) Target_Name(Other_Target_Names): Depend_Names`

* Makefile_Name: make 运行的 Makefile 的名称 (可以为空)，不为空时 make 会运行指定的 Makefile (`-f Makefile_Name`)
    * Makefile 中必须包含 all clean install 三个目标，默认会加入 all install 和 clean 目标的规则
* Target_Name: 当前包的名称ID
* Other_Target_Names: 当前包的其它目标，多个目标使用空格隔开 (可以为空)
    * 忽略 Other_Target_Names 中的 all install clean 目标
    * `jobserver` 关键字是特殊的虚拟目标，表示 make 后加上 `$(BUILD_JOBS)`，用户需要 `export BUILD_JOBS=-j8` 才会启动多线程编译
        * 某些包的 Makefile 包含 make 指令时不要加上 jobserver 目标，例如编译外部内核模块
    * `prepare` 关键字是特殊的虚拟目标，表示 make 前运行 make prepare，一般用于当 .config 不存在时加载默认配置到 .config
* Depend_Names: 当前包依赖的其它包的名称ID，多个依赖使用空格隔开 (可以为空)
    * `finally` 关键字是特殊的虚拟依赖，表示此包编译顺序在所有其它包之后，一般用于最后生成文件系统和系统镜像
    * 如果有循环依赖或未定义依赖，解析将会失败，会打印出未解析成功的条目
        * 出现循环依赖，打印 "ERROR: circular deps!"
        * 出现未定义依赖，打印 "ERROR: deps (%s) are not found!"

注: 有效的名称是由字母、数字、下划线、点号组成，Other_Target_Names 还可以使用 `%` 作为通配符

## 测试 Yocto 编译

### Yocto 快速开始

* 安装编译环境

```sh
lengjing@lengjing:~/cbuild$ sudo apt install gawk wget git diffstat unzip \
    texinfo gcc build-essential chrpath socat cpio \
    python3 python3-pip python3-pexpect xz-utils \
    debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint3 xterm \
    python3-subunit mesa-common-dev zstd liblz4-tool qemu
```

* 拉取 Poky 工程

```sh
lengjing@lengjing:~/cbuild$ git clone git://git.yoctoproject.org/poky
lengjing@lengjing:~/cbuild$ cd poky
lengjing@lengjing:~/cbuild/poky$ git branch -a
lengjing@lengjing:~/cbuild/poky$ git checkout -t origin/kirkstone -b my-kirkstone
lengjing@lengjing:~/cbuild/poky$ cd ..
```

注：通过 [Yocto Releases Wiki](https://wiki.yoctoproject.org/wiki/Releases) 界面获取版本代号，上述命令拉取了4.0版本。

* 构建镜像

```shell
lengjing@lengjing:~/cbuild$ source poky/oe-init-build-env               # 初始化环境
lengjing@lengjing:~/cbuild/build$ bitbake core-image-minimal            # 构建最小镜像
lengjing@lengjing:~/cbuild/build$ ls -al tmp/deploy/images/qemux86-64/  # 输出目录
lengjing@lengjing:~/cbuild/build$ runqemu qemux86-64                    # 运行仿真器
```

注: `source oe-init-build-env <dirname>`功能: 初始化环境，并将工具目录(`bitbake/bin/` 和 `scripts/`)加入到环境变量; 在当前目录自动创建并切换到工作目录(不指定时默认为 build)。

### Yocto 配方模板

* 编写类文件 (xxx.bbclass)
    * 可以在类文件中 `meta-xxx/classes/xxx.bbclass` 定义环境变量，在配方文件中继承 `inherit xxx`
    * 例如 testenv.bbclass
        ```sh
        export CONF_PATH = "${STAGING_BINDIR_NATIVE}"
        export OUT_PATH = "${WORKDIR}/build"
        export ENV_INS_ROOT = "${WORKDIR}/image"
        export ENV_DEP_ROOT = "${WORKDIR}/recipe-sysroot"
        export ENV_BUILD_MODE
        ```
    * 例如 kconfig.bbclass
        ```py
        inherit terminal
        KCONFIG_CONFIG_COMMAND ??= "menuconfig"
        KCONFIG_CONFIG_PATH ??= "${B}/.config"

        python do_setrecompile () {
            if hasattr(bb.build, 'write_taint'):
                bb.build.write_taint('do_compile', d)
        }

        do_setrecompile[nostamp] = "1"
        addtask setrecompile

        python do_menuconfig() {
            config = d.getVar('KCONFIG_CONFIG_PATH')

            try:
                mtime = os.path.getmtime(config)
            except OSError:
                mtime = 0

            oe_terminal("sh -c \"make %s; if [ \\$? -ne 0 ]; then echo 'Command failed.'; printf 'Press any key to continue... '; read r; fi\"" % d.getVar('KCONFIG_CONFIG_COMMAND'),
                d.getVar('PN') + ' Configuration', d)

            if hasattr(bb.build, 'write_taint'):
                try:
                    newmtime = os.path.getmtime(config)
                except OSError:
                    newmtime = 0

                if newmtime != mtime:
                    bb.build.write_taint('do_compile', d)
        }

        do_menuconfig[depends] += "kconfig-native:do_populate_sysroot"
        do_menuconfig[nostamp] = "1"
        do_menuconfig[dirs] = "${B}"
        addtask menuconfig after do_configure
        ```

* 编写配方文件 (xxx.bb)
    * `recipetool create -o <xxx.bb> <package_src_dir>` 创建一个基本配方，例子中手动增加的条目说明如下
    * 包依赖
        * 包依赖其他包时需要使用 `DEPENDS += "package1 package2"` 说明
        * 链接其它包时 (`LDFLAGS += -lname1 -lname2`) 需要增加 `RDEPENDS:${PN} += "package1 package2"` 说明
    * 编译继承类
        * 使用 menuconfig 需要继承 `inherit kconfig`
            * 如果是 `make -f wrapper.mk menuconfig`，需要设置 `KCONFIG_CONFIG_COMMAND = "-f wrapper.mk menuconfig"`
            * 如果 .congfig 输出目录是编译输出目录，需要设置 `KCONFIG_CONFIG_PATH = "${OUT_PATH}/.config"`
        * 使用 Makefile 编译应用继承 `inherit sanity`，使用 cmake 编译应用继承 `inherit cmake`
        * 编译外部内核模块继承 `inherit module`
        * 编译主机本地工具继承 `inherit native`
    * 安装和打包
        * 继承 `inherit sanity` 或 `inherit cmake` 时需要按实际情况指定打包的目录，否则 do_package 任务出错
            * includedir 指 xxx/usr/include
            * base_libdir 指 xxx/lib;  libdir指 xxx/usr/lib;  bindir指 xxx/usr/bin; datadir 指 xxx/usr/share
            * 更多目录信息参考poky工程的 `meta/conf/bitbake.conf` 文件
            ```
            FILES:${PN}-dev = "${includedir}"
            FILES:${PN} = "${base_libdir} ${libdir} ${bindir} ${datadir}"
            ```
        * 忽略某些警告和错误
            * `ALLOW_EMPTY:${PN} = "1"` 忽略包安装的文件只有头文件或为空，生成镜像时 do_rootfs 错误
            * `INSANE_SKIP:${PN} += "dev-so"` 忽略安装的文件是符号链接的错误
                * 更多信息参考 [insane.bbclass](https://docs.yoctoproject.org/ref-manual/classes.html?highlight=sanity#insane-bbclass)

```
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

# No information for SRC_URI yet (only an external source tree was specified)
SRC_URI = ""

#DEPENDS += "package1 package2"
#RDEPENDS:${PN} += "package1 package2"

inherit testenv
#KCONFIG_CONFIG_COMMAND = "-f wrapper.mk menuconfig"
#KCONFIG_CONFIG_PATH = "${OUT_PATH}/.config"
#inherit kconfig
inherit sanity
#inherit cmake
#inherit module
#inherit native


# NOTE: this is a Makefile-only piece of software, so we cannot generate much of the
# recipe automatically - you will need to examine the Makefile yourself and ensure
# that the appropriate arguments are passed in.

do_configure () {
 # Specify any needed configure commands here
 :
}

do_compile () {
 # You will almost certainly need to add additional arguments here
 oe_runmake
}

do_install () {
 # NOTE: unable to determine what to put here - there is a Makefile but no
 # target named "install", so you will need to define this yourself
 oe_runmake install
}

ALLOW_EMPTY:${PN} = "1"
INSANE_SKIP:${PN} += "dev-so"
FILES:${PN}-dev = "${includedir}"
FILES:${PN} = "${base_libdir} ${libdir} ${bindir} ${datadir}"

```

* 编写配方附加文件 (xxx.bbappend)
    * 配方附加文件指示了包的源码路径和 Makefile 路径

```
inherit externalsrc
EXTERNALSRC = "${ENV_TOP_DIR}/<package_src>"
EXTERNALSRC_BUILD = "${ENV_TOP_DIR}/<package_src>"
```

注: [从3.4版本开始，对变量的覆盖样式语法由下滑线 `_` 变成了冒号 `:`](https://docs.yoctoproject.org/migration-guides/migration-3.4.html#override-syntax-changes)

### 测试 Yocto 编译

* `build/conf/local.conf` 配置文件中增加如下变量定义

```
ENV_TOP_DIR = "/home/lengjing/cbuild"
ENV_BUILD_MODE = "yocto"
```

* 增加测试的层

```sh
lengjing@lengjing:~/cbuild/build$ bitbake-layers add-layer ../examples/meta-cbuild
```

* bitbake 编译

```sh
lengjing@lengjing:~/cbuild/build$ bitbake test-app2  # 编译应用
lengjing@lengjing:~/cbuild/build$ bitbake test-app3  # 编译应用
lengjing@lengjing:~/cbuild/build$ bitbake test-hello # 编译内核模块
lengjing@lengjing:~/cbuild/build$ bitbake test-mod2  # 编译内核模块
lengjing@lengjing:~/cbuild/build$ bitbake test-conf  # 编译 kconfig 测试程序
lengjing@lengjing:~/cbuild/build$ bitbake test-conf -c menuconfig # 修改配置
```

## Yocto 常见问题

### 怎么学习 Yocto 官方文档

答：如下列表：三颗星需要详细了解，两颗星只要大概了解，一颗星需要时去查阅，其它文档需要深入学习 Yocto 时再了解

* 入门知识
    * [快速构建★★★](https://docs.yoctoproject.org/brief-yoctoprojectqs/index.html)
    * [使用建议★★☆](https://docs.yoctoproject.org/what-i-wish-id-known.html)
    * [项目介绍★★☆](https://docs.yoctoproject.org/overview-manual/yp-intro.html)
    * [项目概念★★★](https://docs.yoctoproject.org/overview-manual/concepts.html)
* [参考手册](https://docs.yoctoproject.org/ref-manual/index.html)
    * [目录结构★★★](https://docs.yoctoproject.org/ref-manual/structure.html)
    * [配方类★☆☆](https://docs.yoctoproject.org/ref-manual/classes.html)
        * [QA检查★★☆](https://docs.yoctoproject.org/ref-manual/classes.html#insane-bbclass)
    * [任务简介★★★](https://docs.yoctoproject.org/ref-manual/tasks.html)
    * [devtool命令★☆☆](https://docs.yoctoproject.org/ref-manual/devtool-reference.html)
    * [QA问题★★☆](https://docs.yoctoproject.org/ref-manual/qa-checks.html)
    * [变量词汇表★☆☆](https://docs.yoctoproject.org/ref-manual/variables.html)
* 开发手册
    * [BSP开发★★☆](https://docs.yoctoproject.org/bsp-guide/bsp.html)
    * [内核开发★★☆](https://docs.yoctoproject.org/kernel-dev/index.html)
    * [常见任务★★☆](https://docs.yoctoproject.org/dev-manual/common-tasks.html)
        * [编写meta★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#understanding-and-creating-layers)
        * [编写image★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#customizing-images)
        * [编写recipe★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#writing-a-new-recipe)
        * [编写machine★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#adding-a-new-machine)
        * [了解package★★★](https://docs.yoctoproject.org/dev-manual/common-tasks.html#working-with-pre-built-libraries)
* [语法手册](https://docs.yoctoproject.org/bitbake/2.0/index.html)
    * [基本概念★★☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-intro.html)
    * [执行简介★☆☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-execution.html)
    * [语法运算★★★](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-metadata.html)
    * [文件获取★☆☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-fetching.html)
    * [变量词汇表★☆☆](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-ref-variables.html)

### Yocto 编译和普通编译最大不同是什么

答：普通编译使用的是主机的编译环境；
Yocto 编译则每个包都有自已的输出目录 [WORKDIR](https://docs.yoctoproject.org/ref-manual/variables.html#term-WORKDIR) ，在 WORKDIR 自己复制需要的主机工具和依赖文件到自己的工作目录，然后创建一个干净的shell环境执行任务。

* `${WORKDIR}/build`：仅适用于源代码与编译输出分开的编译输出目录
* `${WORKDIR}/recipe-sysroot`：依赖的根文件目录
* `${WORKDIR}/recipe-sysroot-native`：主机工具的根文件目录
* `${WORKDIR}/image`：安装的根文件目录
* `${WORKDIR}/temp`：自动生成的日志和脚本的文件目录

### Yocto 怎么导出环境变量

答：Yocto 是无法使用在shell中导出的环境变量的，Yocto 中的环境变量可以在输出目录的 `conf/local.conf` 中定义，在recipe文件中通过 `export <varname>` 一条一条导出。
编译时可以从 `${WORKDIR}/temp/run.do_compile` 文件知道导出了哪些变量。
详情参考 [将变量导出到环境](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=nostamp#exporting-variables-to-the-environment)

### Yocto 常用命令有哪些

答：主要命令如下所示

* [bitbake 命令](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-intro.html#the-bitbake-command)
    * `bitbake packagename` 编译 packagename
    * `bitbake -c taskname packagename` 执行 packagename 的 taskname 任务
    * `bitbake -e packagename` 显示生成的执行脚本，从中可以看到变量和函数的定义
* [recipetool 命令](https://docs.yoctoproject.org/dev-manual/common-tasks.html#locate-or-automatically-create-a-base-recipe)
    * `recipetool create -o xxx.bb src_path` 根据源码生成一个模板
* [bitbake-layers 命令](https://docs.yoctoproject.org/bsp-guide/bsp.html?highlight=bitbake+layers#creating-a-new-bsp-layer-using-the-bitbake-layers-script)
    * `bitbake-layers create-layer xxx && mv xxx meta-xxx` 新建一个层
    * `bitbake-layers add-layer meta-xxx` 添加一个层到当前配置

### Yocto 需要注意哪些配置文件

答：主要配置文件如下所示

* [TOPDIR 目录](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-ref-variables.html#term-TOPDIR) : 输出顶层目录
* [poky/meta/conf/bitbake.conf](https://docs.yoctoproject.org/ref-manual/structure.html?highlight=bitbake+conf#meta-conf) : 默认配置，大多数变量词汇在此定义
* [${TOPDIR}/conf/local.conf](https://docs.yoctoproject.org/ref-manual/structure.html?highlight=local+conf#build-conf-local-conf) : 本地配置，可以覆盖默认配置和定义自定义的环境变量
* [${TOPDIR}/conf/bblayers.conf](https://docs.yoctoproject.org/ref-manual/structure.html?highlight=local+conf#build-conf-bblayers-conf) : 配置使用的层
* [meta-xxx/conf/layer.conf 配置](https://docs.yoctoproject.org/dev-manual/common-tasks.html?highlight=layer+conf#creating-your-own-layer) : 层配置，可以看到层下的配方文件如何找到
* [meta-xxx/conf/machine/xxx.conf 配置](https://docs.yoctoproject.org/bsp-guide/bsp.html?highlight=machine+conf#hardware-configuration-options) : 机器配置，有机器配置的层是BSP层， `${TOPDIR}/conf/local.conf` 里面的 `MACHINE` 设置的值的机器配置文件 `值.conf` 必须存在

### Yocto 怎么使用变量

答：详细信息参考 [基本语法](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#basic-syntax) 和 [条件语法](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#conditional-syntax-overrides) ，如下总结：

* 获取变量的值必须使用大括号 `${var}`
* 赋给变量的值可以用单引号也可以用双引号，单引号和双引号作用一样，不会抑制变量扩展(和shell不一样)
* 定义或修改变量的操作符有:
    * 赋值 `=` `:=` `?=` `??=`
        * 值中有变量时， `=` `?=` `??=` 值中的变量是最后扩展(变量的最终值)，`:=` 值中的变量是立即扩展(当前位置的变量值)
        * `?=` 设置默认值(在解析到当前语句时，当前变量未定义时才保留该值)
        * `??=` 设置弱默认值(在解析过程结束后再解析该语句，此时变量未定义时才保留该值，多个 `??=` 存在时保留最后一个值)
    * 追加 `+=` `=+` `.=` `=.` `:append` `:prepend`  删除 `:remove`
        * `+=`  `.=`  `:append` 是后置追加(新值放在原值的后面)； `=+` `=.` `:prepend` 是前置追加(新值放在原值的前面)
        * `+=` `=+` 会在新值和原值之间自动加上空格；`.=` `=.` `:append` `:prepend` 新值和原值之间不会加上空格，需要手动增加
        * `+=` `=+` `.=` `=.` 是立即解析(在解析到当前语句时立即追加)，`:append` `:prepend` 是最后解析(在解析过程结束后再解析该语句时追加)
        * `:remove` 是删除所有已有值(空格隔开多个值)中和设定值相同的值
    * 条件 `OVERRIDES`
        * 条件声明使用 `OVERRIDES` 关键字，条件名只能使用小写字符、数字和短划线，多个条件使用冒号隔开
            * `OVERRIDES = "cond1:cond2"`
            * `OVERRIDES:append = ":cond3"`
        * 当条件定义时才定义或修改对应的变量  `var:cond1:append = " xxx"`
* 使用 `unset` 取消设置变量
* 可以使用中括号 `var[flag_name]` 定义变量的标志
    * 理解为创建一个新变量，类似把变量当作字典的概念
    * task变量有一些 [公有的flag](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#variable-flags)
    * 定义或修改变量的操作符和取消设置 `unset` 都可以用在变量的标志中

### Yocto 怎么包含共享功能的文件

答：包含共享功能总共有 [4种方法](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html#sharing-functionality) ：

* 继承类 : `inherit <class_name>` 和 `INHERIT += <class_name>`
    * 继承的文件只能是类 `*.bbclass`
    * inherit指令只能用在配方和类文件中 `*.bb` / `*.bbappend` / `*.bbclass` ，INHERIT指令只能用在配置文件中 `*.conf`
    * `<class_name>.bbclass` 在输出目录的 `conf/bblayers.conf` 的 [BBLAYERS](https://docs.yoctoproject.org/ref-manual/variables.html?highlight=bblayers#term-BBLAYERS) 变量上定义的所有 meta-xxx 目录的 classes 子目录找到，而不仅仅是当前的层目录
* 包含文件:  `include <file_path>` 和 `require <file_path>`
    * 包含的文件可以是任意类型的文件，但是我们一般命名为 `*.inc`
    * include指令和require指令可以用在任意类型的文件中
    * **include指令包含的文件不存在时不会报错，而require指令会报错**
    * `<file_path>` 如果是相对路径，它的基准是输出目录的 `conf/bblayers.conf` 的 BBLAYERS 变量上定义的所有 meta-xxx 目录，从中找到第一个匹配的文件
    * 配方文件 `*.bb` 可以使用 [THISDIR](https://docs.yoctoproject.org/ref-manual/variables.html?highlight=thisdir#term-THISDIR) 表示配方文件的所在目录，例如包含usertask.inc: `include ${THISDIR}/usertask.inc`

### Yocto 如何在NFS下编译

答：Yocto 默认是不支持在NFS下编译的，因为编译速度较慢且可能存在权限问题，请参考 [官方issue](https://bugzilla.yoctoproject.org/show_bug.cgi?id=5442#c8) ,
我们可以使用如下方法禁用poky官方工程的NFS检查使得编译成功，但无法保证不出现其它问题：

```
diff --git a/meta/classes/sanity.bbclass b/meta/classes/sanity.bbclass
index b1fac107d5..afbafe2382 100644
--- a/meta/classes/sanity.bbclass
+++ b/meta/classes/sanity.bbclass
@@ -722,7 +722,7 @@ def check_sanity_version_change(status, d):
     status.addresult(check_path_length(tmpdir, "TMPDIR", 410))

     # Check that TMPDIR isn't located on nfs
-    status.addresult(check_not_nfs(tmpdir, "TMPDIR"))
+    #status.addresult(check_not_nfs(tmpdir, "TMPDIR"))

     # Check for case-insensitive file systems (such as Linux in Docker on
     # macOS with default HFS+ file system)
```

### Yocto 的目录结构在哪里定义

答：查看官方文档 [源目录结构](https://docs.yoctoproject.org/ref-manual/structure.html) 了解目录的作用；
查看 poky 的 `meta/conf/bitbake.conf` 源码了解目录变量的详细定义

### downloads 和 sstate-cache 存储了什么

答：downloads 存储了源码， sstate-cache 存储了编译生成的文件，他们可以分别使用 [DL_DIR](https://docs.yoctoproject.org/ref-manual/variables.html?highlight=dl_dir#term-DL_DIR) 和 [SSTATE_DIR](https://docs.yoctoproject.org/ref-manual/variables.html#term-SSTATE_DIR) 指定保存目录，
如下所示，把 downloads 和 sstate-cache 保存在某个公共位置下，多个编译可以共享一份资源

```sh
DL_DIR = "${TOPDIR}/../downloads"
SSTATE_DIR = "${TOPDIR}/../sstate-cache"
```

### 如何在本地搭建镜像服务器加速构建

答：将第一次构建生成的 downloads 和 sstate-cache 复制到一个特定的目录，例如 mirror，
在 mirror 目录运行 http 服务器，例如 `python -m http.server 8080`，
然后在输出目录的 `conf/local.conf` 加上设置，例如

```sh
SSTATE_MIRRORS = "file://.* http://127.0.0.1:8080/sstate-cache/PATH;downloadfilename=PATH"
SOURCE_MIRROR_URL = "http://127.0.0.1:8080/downloads"
INHERIT += "own-mirrors"
```

### Yocto 获取源码和不重新编译的规则

答：
Yocto不重新编译的判断规则是(参考 [共享状态缓存](https://docs.yoctoproject.org/overview-manual/concepts.html#shared-state-cache) )：
1. 本地的 SSTATE_DIR 是否存在编译好的包且时间戳相同，如果是，[不用重新编译](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-execution.html#setscene)；否则下一条
2. 网络的 SSTATE_MIRRORS 是否存在编译好的包且时间戳相同，如果是，不用重新编译，直接将网络上的编译好的包复制到本地的 SSTATE_DIR；否则下一条
3. 获取源码编译并将编译好的包复制到本地的 SSTATE_DIR

Yocto获取源码的规则是(参考 [文件下载](https://docs.yoctoproject.org/bitbake/2.0/bitbake-user-manual/bitbake-user-manual-fetching.html) )：
1. 本地的 DL_DIR 是否存在下载好的源码且hash值相同，如果是，直接从本地解压；否则下一条
2. 网络的 SOURCE_MIRROR_URL 是否存在下载好的源码且hash值相同，如果是，下载到本地 DL_DIR 再解压；否则下一条
3. 从配方文件指定的 SRC_URI 链接下载源码，如果下载失败下一条
4. 从Yocto官方镜像下载源码

### 出现官方自带开源包编译错误如何处理

答：开源包的编译是Yocto官方配方，个人猜测是缓存导致了此错误，运行清理一般可以解决此问题，例如出现如下错误：

```sh
ERROR: Task (.../poky/meta/recipes-connectivity/openssl/openssl_3.0.4.bb:do_package_write_rpm) failed with exit code '1'
ERROR: Task (.../poky/meta/recipes-devtools/gcc/gcc_11.3.bb:do_compile) failed with exit code '1'
```

解决方法

```sh
bitbake -c clean openssl && bitbake openssl	# 取自 openssl_3.0.4.bb 的 openssl
bitbake -c clean gcc && bitbake gcc	# 取自 gcc_11.3.bb 的 gcc
```

### 为什么外部linux模块的配方文件名以 `kernel-module-` 开头

答：查看 poky 的 `meta/classes/module.bbclass` 源码：

```py
python __anonymous () {
depends = d.getVar('DEPENDS')
extra_symbols = []
for dep in depends.split():
	if dep.startswith("kernel-module-"):
		extra_symbols.append("${STAGING_INCDIR}/" + dep + "/Module.symvers")
d.setVar('KBUILD_EXTRA_SYMBOLS', " ".join(extra_symbols))
}
```

module类自动将依赖模块的符号导出文件 Module.symvers 加入到了 [KBUILD_EXTRA_SYMBOLS](https://www.kernel.org/doc/html/latest/kbuild/kbuild.html?highlight=kbuild_extra_symbols) 变量。
Module.symvers 含有 EXPORT_SYMBOL(func) 导出的符号列表等，如果没有指定依赖包的这个文件，编译会失败。
也可以设置变量 [PROVIDES](https://docs.yoctoproject.org/ref-manual/variables.html#term-PROVIDES) 为配方设置别名，此时配方文件名不命名为 `kernel-module-` 开头也行
inc.mod.mk 模板也会自动加上 Module.symvers ，所以配方文件名不命名为 `kernel-module-` 开头也行。

### 配方中如何支持menuconfig

答：直接加上一个自定义任务运行 `oe_runmake menuconfig` 是没有效果的。

查看poky工程的 `meta/classes/cml1.bbclass` 的源码有个 do_menuconfig 的任务，核心语句如下：

```py
KCONFIG_CONFIG_COMMAND ??= "menuconfig"
KCONFIG_CONFIG_ROOTDIR ??= "${B}"
python do_menuconfig() {
    ...
    oe_terminal("sh -c \"make %s; if [ \\$? -ne 0 ]; then echo 'Command failed.'; printf 'Press any key to continue... '; read r; fi\"" % d.getVar('KCONFIG_CONFIG_COMMAND'),
    ...
}
```

所以我们需要继承cml1类 `inherit cml1` 来加上 menuconfig 任务，如果我们的 Makefile 不是默认名称，我们还需要修改 `KCONFIG_CONFIG_COMMAND` 变量，例如 `KCONFIG_CONFIG_COMMAND = "-f wrapper.mk menuconfig"`。

但是cml1类不支持.config文件放在和运行编译的工作目录的不同的目录，如果.config文件和运行编译的工作目录不同，包不会使用新的参数重新编译，此种情况我们可以继承自定义的类 `inherit kconfig`

### 如何禁止编译在源码创建 oe-workdir 和 oe-logs 符号链接

答：查看Poky工程的 meta/classes/externalsrc.bbclass 的源码有个 `EXTERNALSRC_SYMLINKS ?= "oe-workdir:${WORKDIR} oe-logs:${T}"` 的变量，在输出目录的 `conf/local.conf` 将此变量置空 `EXTERNALSRC_SYMLINKS ?= ""` 即可禁止创建。
* oe-workdir: 指向包输出的根目录 `${WORKDIR}`
* oe-logs: 指向包输出的日志和脚本目录 `${WORKDIR}/temp`

### `QA Issue [ldflags]` 怎么解决

答：该错误的打印是 `File '<file>' in package '<package>' doesn't have GNU_HASH (didn't pass LDFLAGS?) [ldflags]`，
错误原因是LDFLAGS默认传了链接参数 `-Wl,--hash-style=gnu`，而编译的库没有使用这个链接参数，解决方法有3个：
* a. 编译动态库时加上链接参数链接参数 `-Wl,--hash-style=gnu`
* b. 修改默认链接参数为sysv，在输出目录的 `conf/local.conf` 加上 `LINKER_HASH_STYLE = "sysv"`
* c. 忽略错误，在recipe文件加上 `INSANE_SKIP:${PN} += "ldflags"`

关于 gnu 和 sysv 的区别请参考 [ld-hash-style](https://answerywj.com/2020/05/14/ld-hash-style/)

### `QA Issue [dev-so]` 怎么解决

答：该错误的打印是 `non -dev/-dbg/nativesdk- package contains symlink .so: <packagename> path '<path>' [dev-so]`，
错误原因是发布包打包了符号链接，具体参考 [打包规则](https://docs.yoctoproject.org/dev-manual/common-tasks.html#working-with-pre-built-libraries) ，解决方法有两个：
* a. 忽略错误，在recipe文件加上 `INSANE_SKIP:${PN} += "dev-so"`  (目前使用方法)
* b. 更细致的打包，如下所示：

```sh
FILES:${PN}-dev = "${includedir} ${libdir}/lib*.so"
FILES:${PN} = "${libdir}/lib*.so.*.*.*"
```

### `QA Issue [file-rdeps]` 怎么解决

答：该错误的打印是 `<packagename> requires <files>, but no providers in its RDEPENDS [file-rdeps]`，
如果编译时LDFLAGS指定了 `-lsonamea`，必须在配方文件加上 `RDEPENDS:${PN} += "packagename1 packagename2"`;
如果还是报此错误，并且依赖的动态库是带版本的，那么编译依赖的动态库时需要加上链接参数 `-Wl,-soname=libxxx.so`

关于链接参数的说明，请查看 [linux下动态库中的soname](https://www.cnblogs.com/wangshaowei/p/11285332.html)


### `QA Issue [already-stripped]` 怎么解决

答：该错误的打印是 `File '<file>' from <recipename> was already stripped, this will prevent future debugging! [already-stripped]`，
错误原因是安装的可执行文件或动态库使用了 strip 命令删除了调试信息，所以我们安装的文件不应该先运行 `$(STRIP) 文件`，
如果我们无法重新构建库，也可以通过忽略错误解决此问题，在recipe文件加上 `INSANE_SKIP:${PN} += "already-stripped"`

### `Error: Unable to find a match: <packagename>` 怎么解决

答：该错误的打印出现在do_rootfs时，错误原因是某个包没有任何输出，或输出只有头文件 或/和 静态库文件，
解决方法有两个
* a. 忽略错误，在recipe文件加上 `ALLOW_EMPTY:${PN} = "1"` (目前使用方法)
* b. 不要将此包加入到do_rootfs变量 `IMAGE_INSTALL:append` ，修改 `build/bin/yocto/inc-yocto-build.mk` 的 IGNORES_RECIPES 变量

### `Error: Transaction test error:` 怎么解决

答：该错误的打印出现在do_rootfs时，打印信息 `"xxx do_rootfs: Could not invoke dnf. Command..."`， 然后一连串的包列表，然后 `"Error: Transaction test error: file xxx conflicts between attempted installs of xxx and xxx"`。
错误原因是某个包安装的文件和其它包安装的文件路径名相同，此时只能改变其中一个包安装的文件。

有时候我们使用自己的配方编译开源包，Yocto 也有对应的默认配方，此时do_rootfs的时候也可能报错。
例如如果我们使用了自己的配方编译zlib开源库，do_rootfs就报了下面错误
```
Error: 
 Problem: package libkmod2-29-r0.cortexa53 requires libz1 >= 1.2.11, but none of the providers can be installed
  - package systemd-1:250.5-r0.cortexa53 requires libkmod.so.2()(64bit), but none of the providers can be installed
  - package systemd-1:250.5-r0.cortexa53 requires libkmod.so.2(LIBKMOD_5)(64bit), but none of the providers can be installed
  - package systemd-1:250.5-r0.cortexa53 requires libkmod2 >= 29, but none of the providers can be installed
  - cannot install both libz1-1.2.11-r0.cortexa53 and libz1-1.0-r0.cortexa53
  - package packagegroup-core-boot-1.0-r17.v5 requires systemd, but none of the providers can be installed
  - conflicting requests
(try to add '--allowerasing' to command line to replace conflicting packages or '--skip-broken' to skip uninstallable packages)
```
此时我们只能删除自定义的配方转而使用官方的配方。

### 怎么设置使包每次编译都重新编译

答：如果某个包每次编译都要重新编译，例如 amboot，用户可以使用 `bitbake -f packagename` 强制编译，但是会有警告 `WARNING: xxx.bb:do_build is tainted from a forced run`, 如果不强制编译又要求每次编译都要重新编译，用户需要在配方文件中 [设置任务属性](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=nostamp#variable-flags) ：
 `do_compile[nostamp] = "1"`

### 如何自定义任务

答：自定义任务至少需要3个内容：任务函数、执行目录和任务声明。如果任务依赖其它包，还需要设置依赖。

* dirs 、depends 和 postfuncs 属性参考  [设置任务属性](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=nostamp#variable-flags) ，其中dirs列出的最后一个目录用作任务的 [当前工作目录](https://docs.yoctoproject.org/ref-manual/variables.html#term-B)
* [addtask](https://docs.yoctoproject.org/bitbake/bitbake-user-manual/bitbake-user-manual-metadata.html?highlight=addtask#promoting-a-function-to-a-task) 还可以增加 `before` （执行其它任务时先执行此任务） 和 `after` （执行此任务时先执行其它任务） 说明

```sh
do_${task_name} () {
	oe_runmake ${task_name}
}
do_${task_name}[dirs] = "${B}"
do_${task_name}[depends] += "depend_package_name1:task_name depend_package_name2:task_name"
addtask ${task_name}
```

例如增加自定义任务：加载特定Kconfig配置 user_defined_config 到当前配置的任务

```sh
do_user_defined_config () {
	oe_runmake user_config
}
do_user_defined_config[dirs] = "${B}"
do_user_defined_config[nostamp] = "1"
do_user_defined_config[depends] += "kconfig-native:do_populate_sysroot"
do_user_defined_config[postfuncs] += "do_setrecompile"
addtask user_defined_config
```

