# CBuild 编译系统

## 特点

* Linux 下纯粹的 Makefile 编译
* 支持交叉编译，支持自动分析 C 头文件作为编译依赖
* 一个 Makefile 同时支持 Yocto 编译方式、源码和编译输出分离模式和不分离模式
* 提供编译静态库、共享库和可执行文件的模板 `inc.app.mk`
* 提供kconfig配置参数的模板 `inc.conf.mk`
* 提供编译外部内核模块的模板 `inc.mod.mk`
* 提供根据目标依赖关系自动生成整个系统的配置和编译的脚本 `analyse_deps.py`

## 初始化编译环境

初始化编译环境运行如下命令

```sh
lengjing@lengjing:~/cbuild$ source scripts/build.env 
====================================
ARCH=
CROSS_COMPILE=
ENV_TOP_DIR=/home/lengjing/cbuild
ENV_TOP_OUT=/home/lengjing/cbuild/output
USING_EXT_BUILD=y
USING_DEPS_BUILD=n
USING_YOCTO_BUILD=n
====================================
```

还可以指定 ARCH 和交叉编译器

```sh
lengjing@lengjing:~/cbuild$ source scripts/build.env arm64 arm-linux-gnueabihf- 
====================================
ARCH=arm64
CROSS_COMPILE=arm-linux-gnueabihf-
ENV_TOP_DIR=/home/lengjing/cbuild
ENV_TOP_OUT=/home/lengjing/cbuild/output
USING_EXT_BUILD=y
USING_DEPS_BUILD=n
USING_YOCTO_BUILD=n
====================================
```

`scripts/build.env` 中，导出的自定义环境变量

```sh
ENV_TOP_DIR=$(pwd | sed 's:/cbuild.*::')/cbuild
ENV_TOP_OUT=${ENV_TOP_DIR}/output
USING_EXT_BUILD=y
USING_DEPS_BUILD=n
```

* ENV_TOP_DIR: 工程的根目录
* ENV_TOP_OUT: 源码和编译输出分离时的编译输出根目录
* USING_EXT_BUILD: 是否使用源码和编译输出分离，y 表示是
* USING_DEPS_BUILD: 在 analyse_deps.py 自动生成的Makefile中使用，是否使能编译依赖，y 表示是
* USING_YOCTO_BUILD: 是否使用 Yocto 编译，y 表示是 (使用 Yocto 编译时 USING_EXT_BUILD 必须为 y)

注: 源码和编译输出分离时，某个包的编译输出目录是把包的源码目录的 ENV_TOP_DIR 部分换成了 ENV_TOP_OUT (非 Yocto 编译)
注: Yocto BitBake 任务无法直接使用 shell 自定义的环境变量，所以不需要 source 这个环境脚本

## 测试编译应用

测试用例位于 `test-app`，如下测试

```sh
lengjing@lengjing:~/cbuild$ cd test-app 
lengjing@lengjing:~/cbuild/test-app$ make 
cc	add.c
cc	sub.c
cc	main.c
lib:	/home/lengjing/cbuild/output/test-app/libtest.a
ar: creating /home/lengjing/cbuild/output/test-app/libtest.a
lib:	/home/lengjing/cbuild/output/test-app/libtest.so
bin:	/home/lengjing/cbuild/output/test-app/test
---- build ok ----
lengjing@lengjing:~/cbuild/test-app$ vi include/sub.h  # 在此文件加上一个空行保存
lengjing@lengjing:~/cbuild/test-app$ make # 此时依赖此头文件的 C 源码会重新编译
cc	sub.c
cc	main.c
lib:	/home/lengjing/cbuild/output/test-app/libtest.a
lib:	/home/lengjing/cbuild/output/test-app/libtest.so
bin:	/home/lengjing/cbuild/output/test-app/test
---- build ok ----
```

`scripts/inc.app.mk` 支持的目标

* LIB_NAME_A: 编译静态库时需要设置静态库名
* LIB_NAME_SO: 编译动态库时需要设置动态库名
* BIN_NAME: 编译可执行文件时需要设置可执行文件名

`scripts/inc.app.mk` 可设置的变量

* OUT_PATH: 编译输出目录，保持默认即可
* SRC_PATH: 包中源码所在的目录，默认是包的根目录，也有的包将源码放在 src 下
* SRCS: 所有的 C 源码文件，默认是 SRC_PATH 下的所有的 `*.c` 文件，如果用户指定了 SRCS，不需要再指定 SRC_PATH
* CFLAGS: 用户需要设置包自己的一些编译标记
* LDFLAGS: 用户需要设置包自己的一些链接标记

## 测试kconfig

测试用例位于 `test-conf`，如下测试

```sh
lengjing@lengjing:~/cbuild/test-app$ cd ../test-conf
lengjing@lengjing:~/cbuild/test-conf$ ls config
def_config
lengjing@lengjing:~/cbuild/test-conf$ make def_config
make[1]: Entering directory '/home/lengjing/cbuild/scripts/kconfig'
bison	/home/lengjing/cbuild/output/scripts/kconfig/autogen/parser.tab.c
gcc	/home/lengjing/cbuild/output/scripts/kconfig/autogen/parser.tab.c
flex	/home/lengjing/cbuild/output/scripts/kconfig/autogen/lexer.lex.c
gcc	/home/lengjing/cbuild/output/scripts/kconfig/autogen/lexer.lex.c
gcc	parser/confdata.c
gcc	parser/menu.c
gcc	parser/util.c
gcc	parser/preprocess.c
gcc	parser/expr.c
gcc	parser/symbol.c
gcc	conf.c
gcc	/home/lengjing/cbuild/output/scripts/kconfig/conf
gcc	lxdialog/checklist.c
gcc	lxdialog/inputbox.c
gcc	lxdialog/util.c
gcc	lxdialog/textbox.c
gcc	lxdialog/yesno.c
gcc	lxdialog/menubox.c
gcc	mconf.c
gcc	/home/lengjing/cbuild/output/scripts/kconfig/mconf
make[1]: Leaving directory '/home/lengjing/cbuild/scripts/kconfig'
#
# No change to /home/lengjing/cbuild/output/test-conf/.config
#
lengjing@lengjing:~/cbuild/test-conf$ make menuconfig 
make[1]: Entering directory '/home/lengjing/cbuild/scripts/kconfig'
make[1]: Nothing to be done for 'all'.
make[1]: Leaving directory '/home/lengjing/cbuild/scripts/kconfig'
configuration written to /home/lengjing/cbuild/output/test-conf/.config

*** End of the configuration.
*** Execute 'make' to start the build or try 'make help'.

lengjing@lengjing:~/cbuild/test-conf$ ls -a ../output/test-conf
.  ..  .config  .config.old  autoconfig  config.h
lengjing@lengjing:~/cbuild/test-conf$ make def2_saveconfig
make[1]: Entering directory '/home/lengjing/cbuild/scripts/kconfig'
make[1]: Nothing to be done for 'all'.
make[1]: Leaving directory '/home/lengjing/cbuild/scripts/kconfig'
Save .config to config/def2_config
lengjing@lengjing:~/cbuild/test-conf$ ls config
def2_config  def_config
```

`scripts/inc.conf.mk` 支持的目标

* menuconfig: 图形化配置工具
* cleanconfig: 清理配置文件
* xxx_config: 将 CONF_SAVE_PATH 下的 xxx_config 作为当前配置
* xxx_saveconfig: 将当前配置保存到 CONF_SAVE_PATH 下的 xxx_config

`scripts/inc.conf.mk` 可设置的变量

* OUT_PATH: 编译输出目录，保持默认即可
* CONF_PATH: kconfig 工具的编译输出目录，和实际一致即可
* CONF_SRC: kconfig 工具的源码目录，目前是在 `scripts/kconfig`，和实际一致即可
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
lengjing@lengjing:~/cbuild/test-conf$ cd ../test-mod
lengjing@lengjing:~/cbuild/test-mod$ make deps
Analyse depends OK.
lengjing@lengjing:~/cbuild/test-mod$ make menuconfig 
make[1]: Entering directory '/home/lengjing/cbuild/scripts/kconfig'
make[1]: Nothing to be done for 'all'.
make[1]: Leaving directory '/home/lengjing/cbuild/scripts/kconfig'
configuration written to /home/lengjing/cbuild/output/test-mod/.config

*** End of the configuration.
*** Execute 'make' to start the build or try 'make help'.

lengjing@lengjing:~/cbuild/test-mod$ make all
make[1]: Entering directory '/home/lengjing/cbuild/test-mod/test_hello_add'
KERNELRELEASE= pwd=/home/lengjing/cbuild/test-mod/test_hello_add PWD=/home/lengjing/cbuild/test-mod
make[2]: Entering directory '/usr/src/linux-headers-5.13.0-41-generic'
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello_add/hello_add.o
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod
  MODPOST /home/lengjing/cbuild/output/test-mod/test_hello_add/Module.symvers
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello_add/hello_add.mod.o
  LD [M]  /home/lengjing/cbuild/output/test-mod/test_hello_add/hello_add.ko
  BTF [M] /home/lengjing/cbuild/output/test-mod/test_hello_add/hello_add.ko
Skipping BTF generation for /home/lengjing/cbuild/output/test-mod/test_hello_add/hello_add.ko due to unavailability of vmlinux
make[2]: Leaving directory '/usr/src/linux-headers-5.13.0-41-generic'
make[1]: Leaving directory '/home/lengjing/cbuild/test-mod/test_hello_add'
make[1]: Entering directory '/home/lengjing/cbuild/test-mod/test_hello_sub'
KERNELRELEASE= pwd=/home/lengjing/cbuild/test-mod/test_hello_sub PWD=/home/lengjing/cbuild/test-mod
make[2]: Entering directory '/usr/src/linux-headers-5.13.0-41-generic'
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello_sub/hello_sub.o
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod
  MODPOST /home/lengjing/cbuild/output/test-mod/test_hello_sub/Module.symvers
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello_sub/hello_sub.mod.o
  LD [M]  /home/lengjing/cbuild/output/test-mod/test_hello_sub/hello_sub.ko
  BTF [M] /home/lengjing/cbuild/output/test-mod/test_hello_sub/hello_sub.ko
Skipping BTF generation for /home/lengjing/cbuild/output/test-mod/test_hello_sub/hello_sub.ko due to unavailability of vmlinux
make[2]: Leaving directory '/usr/src/linux-headers-5.13.0-41-generic'
make[1]: Leaving directory '/home/lengjing/cbuild/test-mod/test_hello_sub'
make[1]: Entering directory '/home/lengjing/cbuild/test-mod/test_hello'
KERNELRELEASE= pwd=/home/lengjing/cbuild/test-mod/test_hello PWD=/home/lengjing/cbuild/test-mod
MOD_DEPS=/home/lengjing/cbuild/output/test-mod/test_hello_add /home/lengjing/cbuild/output/test-mod/test_hello_sub
make[2]: Entering directory '/usr/src/linux-headers-5.13.0-41-generic'
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod/test_hello
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello/hello_div.o
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello/hello_mul.o
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello/hello_main.o
  LD [M]  /home/lengjing/cbuild/output/test-mod/test_hello/hello.o
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod/test_hello
  MODPOST /home/lengjing/cbuild/output/test-mod/test_hello/Module.symvers
  CC [M]  /home/lengjing/cbuild/output/test-mod/test_hello/hello.mod.o
  LD [M]  /home/lengjing/cbuild/output/test-mod/test_hello/hello.ko
  BTF [M] /home/lengjing/cbuild/output/test-mod/test_hello/hello.ko
Skipping BTF generation for /home/lengjing/cbuild/output/test-mod/test_hello/hello.ko due to unavailability of vmlinux
make[2]: Leaving directory '/usr/src/linux-headers-5.13.0-41-generic'
make[1]: Leaving directory '/home/lengjing/cbuild/test-mod/test_hello'


lengjing@lengjing:~/cbuild/test-mod$ cd ../test-mod2
lengjing@lengjing:~/cbuild/test-mod2$ make 
KERNELRELEASE= pwd=/home/lengjing/cbuild/test-mod2 PWD=/home/lengjing/cbuild/test-mod2
make[1]: Entering directory '/usr/src/linux-headers-5.13.0-41-generic'
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod2
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello_main.o
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello_add.o
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello_sub.o
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello_mul.o
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello_div.o
  LD [M]  /home/lengjing/cbuild/output/test-mod2/hello_op.o
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello.o
KERNELRELEASE=5.13.0-41-generic pwd=/usr/src/linux-headers-5.13.0-41-generic PWD=/home/lengjing/cbuild/test-mod2
  MODPOST /home/lengjing/cbuild/output/test-mod2/Module.symvers
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello.mod.o
  LD [M]  /home/lengjing/cbuild/output/test-mod2/hello.ko
  BTF [M] /home/lengjing/cbuild/output/test-mod2/hello.ko
Skipping BTF generation for /home/lengjing/cbuild/output/test-mod2/hello.ko due to unavailability of vmlinux
  CC [M]  /home/lengjing/cbuild/output/test-mod2/hello_op.mod.o
  LD [M]  /home/lengjing/cbuild/output/test-mod2/hello_op.ko
  BTF [M] /home/lengjing/cbuild/output/test-mod2/hello_op.ko
Skipping BTF generation for /home/lengjing/cbuild/output/test-mod2/hello_op.ko due to unavailability of vmlinux
make[1]: Leaving directory '/usr/src/linux-headers-5.13.0-41-generic'
```

`scripts/inc.mod.mk` 支持的目标(KERNELRELEASE 为空时)

* modules: 编译外部内核模块
* modules_clean: 清理内核模块的编译输出
* modules_install: 安装内核模块到指定位置

`scripts/inc.mod.mk` 可设置的变量(KERNELRELEASE 为空时)

* MOD_MAKES: 用户指定一些模块自己的信息，例如 XXXX=xxx
* OUT_PATH: 编译输出目录，保持默认即可 (只在源码和编译输出分离时有效)
* KERNEL_SRC: Linux 内核源码目录 (必须）
* KERNEL_OUT: Linux 内核编译输出目录 （`make -O $(KERNEL_OUT)` 编译内核的情况下必须）
* MOD_DEPS: 当前内核模块依赖的其它内核模块的编译输出目录，多个目录使用空格隔开
* MOD_PATH: 指定模块的安装路径前缀，则外部内核模块的安装路径为 `$(MOD_PATH)/lib/modules/<kernel_release>/extra/`


`scripts/inc.mod.mk` 支持的目标(KERNELRELEASE 有值时)

* MOD_NAME: 模块名称，可以是多个模块名称使用空格隔开

`scripts/inc.mod.mk` 可设置的变量(KERNELRELEASE 有值时)

* SRCS: 所有的 C 源码文件，默认是当前目录下的所有的 `*.c` 文件

注：如果 MOD_NAME 含有多个模块名称，需要用户自己填写各个模块下的对象，例如

```makefile
MOD_NAME = mod1 mod2
mod1-objs = a1.o b1.o c1.o
mod2-objs = a2.o b2.o c2.o
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
3. 继续在内核源码目录运行 M 目录的 Makefile，生成模块和他的符号表

## 测试自动生成总编译

测试用例位于 `test-deps`，如下测试

```sh
lengjing@lengjing:~/cbuild/test-mod2$ cd ../test-deps
lengjing@lengjing:~/cbuild/test-deps$ make deps
Analyse depends OK.
lengjing@lengjing:~/cbuild/test-deps$ make menuconfig 
make[1]: Entering directory '/home/lengjing/cbuild/scripts/kconfig'
make[1]: Nothing to be done for 'all'.
make[1]: Leaving directory '/home/lengjing/cbuild/scripts/kconfig'
configuration written to /home/lengjing/cbuild/output/test-deps/.config

*** End of the configuration.
*** Execute 'make' to start the build or try 'make help'.

lengjing@lengjing:~/cbuild/test-deps$ make all
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pc/pc'
ext.mk
make[2]: Entering directory '/home/lengjing/cbuild/test-deps/pc/pc'
target=all path=/home/lengjing/cbuild/test-deps/pc/pc
make[2]: Leaving directory '/home/lengjing/cbuild/test-deps/pc/pc'
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pc/pc'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pe/pe'
target=all path=/home/lengjing/cbuild/test-deps/pe/pe
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pe/pe'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pd/pd'
target=all path=/home/lengjing/cbuild/test-deps/pd/pd
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pd/pd'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pb/pb'
target=all path=/home/lengjing/cbuild/test-deps/pb/pb
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pb/pb'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pa/pa'
target=all path=/home/lengjing/cbuild/test-deps/pa/pa
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pa/pa'
lengjing@lengjing:~/cbuild/test-deps$ make clean
make[1]: Entering directory '/home/lengjing/cbuild/scripts/kconfig'
make[1]: Leaving directory '/home/lengjing/cbuild/scripts/kconfig'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pc/pc'
ext.mk
make[2]: Entering directory '/home/lengjing/cbuild/test-deps/pc/pc'
target=clean path=/home/lengjing/cbuild/test-deps/pc/pc
make[2]: Leaving directory '/home/lengjing/cbuild/test-deps/pc/pc'
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pc/pc'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pe/pe'
target=clean path=/home/lengjing/cbuild/test-deps/pe/pe
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pe/pe'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pd/pd'
target=clean path=/home/lengjing/cbuild/test-deps/pd/pd
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pd/pd'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pb/pb'
target=clean path=/home/lengjing/cbuild/test-deps/pb/pb
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pb/pb'
make[1]: Entering directory '/home/lengjing/cbuild/test-deps/pa/pa'
target=clean path=/home/lengjing/cbuild/test-deps/pa/pa
make[1]: Leaving directory '/home/lengjing/cbuild/test-deps/pa/pa'
rm -f auto.mk Kconfig
lengjing@lengjing:~/cbuild/test-deps$ 
```

`scripts/analyse_deps.py` 参数

* `-m <Makefile Name>`: 自动生成的 Makefile 文件名
* `-k <Kconfig Name>`: 自动生成的 Kconfig 文件名
* `-f <Depend Name>`: 含有依赖信息的文件名
* `-d <Search Directories>`: 搜索的目录名，多个目录使用冒号隔开
* `-i <Ignore Directories>`: 忽略的目录名，不会搜索指定目录名下的依赖文件，多个目录使用冒号隔开

注: 如果在当前目录下搜索到 `<Depend Name>`，不会再继续搜索当前目录的子目录

依赖信息格式 `#DEPS(Makefile_Name) Target_Name(Other_Target_Names): Depend_Names`

* Makefile_Name: make 运行的 Makefile 的名称 (可以为空)，不为空时 make 会运行 指定的 Makefile (`-f Makefile_Name`)
* Target_Name: 当前包的名称ID
* Other_Target_Names: 当前包的其它目标，多个目标使用空格隔开 (可以为空)，默认会加入 默认目标 和 clean目标的规则
* Depend_Names: 当前包依赖的其它包的名称ID，多个依赖使用空格隔开 (可以为空)，如果有循环依赖或未定义依赖，解析将会失败，会打印出未解析成功的条目

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

* 编写配方文件 (xxx.bb)
    * `recipetool create -o <xxx.bb> <package_src_dir>` 创建一个基本配方，井号线包含的部分是用户手动增加的
    * 继承类时，编译应用使用 `inherit sanity`，编译模块使用 `inherit module`
    * 包依赖其他包时使用 `DEPENDS += " package1 package2"` 说明

```
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

# No information for SRC_URI yet (only an external source tree was specified)
SRC_URI = ""

########################################
#DEPENDS += " package1 package2"
export OUT_PATH="${WORKDIR}"
export ENV_TOP_DIR
export USING_EXT_BUILD
export USING_YOCTO_BUILD
inherit sanity
#inherit module
########################################

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
 :
}
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
USING_EXT_BUILD = "y"
USING_YOCTO_BUILD = "y"
```

* 增加测试的层

```sh
lengjing@lengjing:~/cbuild/build$ bitbake-layers add-layer ../poky/meta-selftest 
```

* 将测试的配方放在层中

```sh
lengjing@lengjing:~/cbuild/build$ cp -rf ../recipes-cbuild ../poky/meta-selftest/ 
```

* bitbake 编译

```sh
lengjing@lengjing:~/cbuild/build$ bitbake test-app   # 编译应用
lengjing@lengjing:~/cbuild/build$ bitbake test-hello # 编译内核模块
lengjing@lengjing:~/cbuild/build$ bitbake test-mod2  # 编译内核模块
```

