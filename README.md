# CBuild 编译系统

## 特点

* Linux 下纯粹的 Makefile 编译
* 支持交叉编译，支持自动分析 C 头文件作为编译依赖
* 一个 Makefile 同时支持 Yocto 编译方式、源码和编译输出分离模式和不分离模式
* 提供编译静态库、共享库和可执行文件的模板 `inc.app.mk`
* 提供安装编译输出的模板 `inc.ins.mk`
* 提供 kconfig 配置参数的模板 `inc.conf.mk`
* 提供编译外部内核模块的模板 `inc.mod.mk`
* 提供根据目标依赖关系自动生成整个系统的配置和编译的脚本 `analyse_deps.py`

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
ENV_INS_ROOT     : /home/lengjing/cbuild/output/fakeroot
ENV_DEP_ROOT     : /home/lengjing/cbuild/output/fakeroot
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
ENV_INS_ROOT     : /home/lengjing/cbuild/output/fakeroot
ENV_DEP_ROOT     : /home/lengjing/cbuild/output/fakeroot
ENV_BUILD_MODE   : external
============================================================

```

`scripts/build.env` 中，导出的自定义环境变量

```sh
ENV_TOP_DIR=$(pwd | sed 's:/cbuild.*::')/cbuild
ENV_TOP_OUT=${ENV_TOP_DIR}/output
ENV_OUT_ROOT=${ENV_TOP_OUT}/objects
ENV_INS_ROOT=${ENV_TOP_OUT}/fakeroot
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

* yocto 时，由于 BitBake 任务无法直接使用当前 shell 的环境变量，所以自定义环境变量应由配方文件导出，不需要 source 这个环境脚本

## 测试编译应用

测试用例1位于 `test-app`
测试用例2位于 `test-app2` (`test-app2` 依赖 `test-app`)，如下测试

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
lib:	/home/lengjing/cbuild/output/objects/examples/test-app/libtest.so
bin:	/home/lengjing/cbuild/output/objects/examples/test-app/test
Build test-app Done.
lengjing@lengjing:~/cbuild/examples/test-app$ make install  # 安装文件
lengjing@lengjing:~/cbuild/examples/test-app$ cd ../test-app2
lengjing@lengjing:~/cbuild/examples/test-app2$ make 
gcc	main.c
bin:	/home/lengjing/cbuild/output/objects/examples/test-app2/test2
Build test-app2  Done.
lengjing@lengjing:~/cbuild/examples/test-app2$ make install
```

`scripts/core/inc.app.mk` 支持的目标

* LIB_NAME_A: 编译静态库时需要设置静态库名
* LIB_NAME_SO: 编译动态库时需要设置动态库名
* BIN_NAME: 编译可执行文件时需要设置可执行文件名
* install_liba: 安装静态库
* install_libso: 安装动态库
* install_bin: 安装可执行文件

`scripts/core/inc.ins.mk` 支持的目标
* install_hdrs: 安装头文件集
    * 用户需要设置被安装的头文件集变量 INSTALL_HEADERS 或/与 INSTALL_PRIVATE_HEADERS
    * INSTALL_HEADERS 指定的头文件的默认安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)`
    * INSTALL_PRIVATE_HEADERS 指定的头文件的默认安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private`
* install_libs: 安装库文件集
    * 用户需要设置被安装的库文件集变量 INSTALL_LIBRARIES
    * 默认安装目录是 `$(ENV_INS_ROOT)/usr/lib`
* install_bins: 安装可执行文件集
    * 用户需要设置被安装的可执行文件集变量 INSTALL_BINARIES
    * 默认安装目录是 `$(ENV_INS_ROOT)/usr/bin`
* install_bins: 安装可执行文件集
    * 用户需要设置被安装的可执行文件集变量 INSTALL_DATAS
    * 默认安装目录是 `$(ENV_INS_ROOT)/usr/share/$(PACKAGE_NAME)`

`scripts/core/inc.app.mk` 可设置的变量

* PACKAGE_NAME: 包的名称
* PACKAGE_DEPS: 包的依赖
    * 默认将包依赖对应的路径加到当前包的头文件和库文件的搜索路径
* OUT_PATH: 编译输出目录，保持默认即可
* SRC_PATH: 包中源码所在的目录，默认是包的根目录，也有的包将源码放在 src 下
* SRCS: 所有的 C 源码文件，默认是 SRC_PATH 下的所有的 `*.c` 文件
    * 如果用户指定了 SRCS，不需要再指定 SRC_PATH
* CFLAGS: 用户需要设置包自己的一些编译标记
* LDFLAGS: 用户需要设置包自己的一些链接标记

## 测试kconfig

测试用例位于 `test-conf`，如下测试

```sh
lengjing@lengjing:~/cbuild/examples/test-app2$ cd ../test-conf/
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

`scripts/core/inc.conf.mk` 可设置的变量

* OUT_PATH: 编译输出目录，保持默认即可
* CONF_SRC: kconfig 工具的源码目录，目前是在 `scripts/kconfig`，和实际一致即可
* CONF_PATH: kconfig 工具的编译输出目录，和实际一致即可
* CONF_PREFIX: 设置 conf 运行的变量，主要是 `srctree=$(path_name)`
    * Kconfig 文件中 source 其它配置参数文件的相对的目录是 srctree 指定的目录
* KCONFIG: 配置参数文件，默认是包下的 Kconfig 文件
* CONF_SAVE_PATH: 配置文件的获取和保存目录，默认是包下的 config 目录

注: 目录下的 Kconfig 文件也说明了如何写配置参数

`scripts/kconfig` 工程说明

* 源码完全来自 linux-5.18 内核的 `scripts/kconfig`
* 在原始代码的基础上增加了命令传入参数 `CONFIG_PATH` `AUTOCONFIG_PATH` `AUTOHEADER_PATH`，原先这些参数要作为环境变量传入
* Makefile 是完全重新编写的

## 测试编译内核模块

测试用例1位于 `test-mod` (其中 test_hello 依赖于 test_hello_add 和 test_hello_sub)，
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
    * INSTALL_HEADERS 指定的头文件的默认安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)`
    * INSTALL_PRIVATE_HEADERS 指定的头文件的默认安装目录是 `$(ENV_INS_ROOT)/usr/include/$(PACKAGE_NAME)/private`

`scripts/core/inc.mod.mk` 可设置的变量(KERNELRELEASE 为空时)

* PACKAGE_NAME: 包的名称
* PACKAGE_DEPS: 包的依赖
    * 默认将包依赖对应的路径加到当前包的头文件的搜索路径
* MOD_MAKES: 用户指定一些模块自己的信息，例如 XXXX=xxx
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

注: 使用源码和编译输出分离时， 需要先将 Makefile 或 Kbuild 复制到 OUT_PATH 目录下，如果不想复制，需要修改内核源码的 `scripts/Makefile.modpost`

```makefile
-include $(if $(wildcard $(KBUILD_EXTMOD)/Kbuild), \
-             $(KBUILD_EXTMOD)/Kbuild, $(KBUILD_EXTMOD)/Makefile)
+include $(if $(wildcard $(src)/Kbuild), \
+             $(src)/Kbuild, $(src)/Makefile)
```

模块编译过程说明

1. 在当前目录运行 Makefile，此时 KERNELRELEASE 为空，执行这个分支下的第一个目标 modules
2. 运行`make -C $(KERNEL_SRC) xxx` 时进入内核源码目录，在内核源码目录运行 src 的 Makefile，此时 KERNELRELEASE 有值，编译源文件
3. 继续在内核源码目录运行 M 目录的 Makefile，生成模块和它的符号表

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
lengjing@lengjing:~/cbuild/examples/test-deps$ make clean
ext.mk
target=clean path=/home/lengjing/cbuild/examples/test-deps/pc/pc
target=clean path=/home/lengjing/cbuild/examples/test-deps/pe/pe
target=clean path=/home/lengjing/cbuild/examples/test-deps/pd/pd
target=clean path=/home/lengjing/cbuild/examples/test-deps/pb/pb
target=clean path=/home/lengjing/cbuild/examples/test-deps/pa/pa
rm -f auto.mk Kconfig
```

`scripts/analyse_deps.py` 参数

* `-m <Makefile Name>`: 自动生成的 Makefile 文件名
* `-k <Kconfig Name>`: 自动生成的 Kconfig 文件名
* `-f <Depend Name>`: 含有依赖信息的文件名
* `-d <Search Directories>`: 搜索的目录名，多个目录使用冒号隔开
* `-i <Ignore Directories>`: 忽略的目录名，不会搜索指定目录名下的依赖文件，多个目录使用冒号隔开

注: 如果在当前目录下搜索到 `<Depend Name>`，不会再继续搜索当前目录的子目录

依赖信息格式 `#DEPS(Makefile_Name) Target_Name(Other_Target_Names): Depend_Names`

* Makefile_Name: make 运行的 Makefile 的名称 (可以为空)，不为空时 make 会运行指定的 Makefile (`-f Makefile_Name`)
    * Makefile 中必须包含 all clean install 三个目标，默认会加入 all install 和 clean 目标的规则
* Target_Name: 当前包的名称ID
* Other_Target_Names: 当前包的其它目标，多个目标使用空格隔开 (可以为空)
    * 忽略 Other_Target_Names 中的 all install clean 目标
    * jobserver 目标表示 make 后加上 `$(BUILD_JOBS)`，用户需要 `export BUILD_JOBS=-j8` 才会启动多线程编译
        * 某些包的 Makefile 包含 make 指令时不要加上 jobserver 目标，例如编译外部内核模块
* Depend_Names: 当前包依赖的其它包的名称ID，多个依赖使用空格隔开 (可以为空)，如果有循环依赖或未定义依赖，解析将会失败，会打印出未解析成功的条目

注: 有效的名称是由字母、数字、下划线、点号组成

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
    * 可以在类文件中 `meta-xxx/classes/xxx.bbclass` 文件中定义环境变量，在配方文件中继承 `inherit xxx`
    * 例如 testenv.bbclass
        ```sh
        export CONF_PATH = "${STAGING_BINDIR_NATIVE}"
        export OUT_PATH = "${WORKDIR}/build"
        export ENV_INS_ROOT = "${WORKDIR}/image"
        export ENV_DEP_ROOT = "${WORKDIR}/recipe-sysroot"
        export ENV_BUILD_MODE
        ```

* 编写配方文件 (xxx.bb)
    * `recipetool create -o <xxx.bb> <package_src_dir>` 创建一个基本配方，例子中手动增加的条目说明如下
    * 包依赖
        * 包依赖其他包时需要使用 `DEPENDS += "package1 package2"` 说明
        * 链接其它包时 (`LDFLAGS += -lname1 -lname2`) 需要增加 `RDEPENDS_${PN} += "package1 package2"` 说明
    * 编译继承类
        * 使用 menuconfig 需要继承 `inherit cml1`
        * 使用 Makefile 编译应用继承 `inherit sanity`，使用 cmake 编译应用继承 `inherit cmake`
        * 编译外部内核模块继承 `inherit module`
        * 编译主机本地工具继承 `inherit native`
    * 安装和打包
        * 继承 `inherit sanity` 或 `inherit cmake` 时需要按实际情况指定打包的目录，否则 do_package 任务出错
            * includedir 指 xxx/usr/include 
            * base_libdir 指 xxx/lib;  libdir指 xxx/usr/lib;  bindir指 xxx/usr/bin; datadir 指 xxx/usr/share
            ```
            FILES_${PN}-dev = "${includedir}"
            FILES_${PN} = "${base_libdir} ${libdir} ${bindir} ${datadir}"
            ```

```
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

# No information for SRC_URI yet (only an external source tree was specified)
SRC_URI = ""


#DEPENDS += "package1 package2"
#RDEPENDS_${PN} += "package1 package2"

export OUT_PATH = "${WORKDIR}/build"
export ENV_INS_ROOT = "${WORKDIR}/image"
export ENV_DEP_ROOT = "${WORKDIR}/recipe-sysroot"
export ENV_TOP_DIR
export ENV_BUILD_MODE

inherit testenv
#inherit cml1
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


FILES_${PN}-dev = "${includedir}"
FILES_${PN} = "${base_libdir} ${libdir} ${bindir} ${datadir}"

```

* 编写配方附加文件 (xxx.bbappend)
    * 配方附加文件指示了包的源码路径和 Makefile 路径

```
inherit externalsrc
EXTERNALSRC = "${ENV_TOP_DIR}/<package_src>"
EXTERNALSRC_BUILD = "${ENV_TOP_DIR}/<package_src>"
```

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
lengjing@lengjing:~/cbuild/build$ bitbake test-hello # 编译内核模块
lengjing@lengjing:~/cbuild/build$ bitbake test-mod2  # 编译内核模块
lengjing@lengjing:~/cbuild/build$ bitbake test-conf  # 编译 kconfig 测试程序
lengjing@lengjing:~/cbuild/build$ bitbake test-conf -c menuconfig # 修改配置
```

