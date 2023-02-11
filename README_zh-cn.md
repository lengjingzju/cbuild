# CBuild 编译系统

[English Edition](./README.md)

## 概述

CBuild 编译系统是一个比 Buildroot 更强大灵活，比 Yocto 更快速简洁的编译系统。他没有陡峭的学习曲线，也没有定义新的语言，比 Buildroot 和 Yocto 更易于理解和使用。
<br>

CBuild 编译系统主要由三部分组成: 任务分析处理工具、Makefile 编译模板、网络和缓存处理工具。
<br>

* 任务分析处理工具: 分析所有任务并自动生成总配置 Kconfig 和执行脚本 Makefile
    * 所有任务由 Python 脚本 `gen_build_chain.py` 分析组装
        * 自动收集所有任务的规则和参数，通过 `make menuconfig` 选择是否执行任务和配置任务参数
    * 每个任务规则由一条依赖语句声明，支持非常多的依赖规则
        * 支持自动生成执行任务的实包和管理任务的虚包的规则
        * 支持普通结构(config)、层次结构(menuconfig)、选择结构(choice) 等自动生成
        * 支持强依赖(depends on)、弱依赖(if...endif)、强选择(select)、弱选择(imply)、或规则(||) 等自动生成
    * 任务是 Makefile 脚本，由 make 执行，Makefile 支持封装原始的 `Makefile` `CMake` `Autotools` `Meson` 脚本以实现对它们的支持
    * 支持生成任务依赖关系的图片，并有颜色等属性查看任务是否被选中等 `gen_depends_image.sh`
<br>

* Makefile 编译模板: 编译驱动、库、应用的模板，只需填写少数几个变量就可以完成一个超大项目的 Makefile
    * 支持编译生成最新的交叉编译工具链 `process_machine.sh` `toolchain/Makefile`
    * 一个 Makefile 同时支持本地编译和交叉编译  `inc.env.mk`  `inc.env.mk`
    * 一个 Makefile 同时支持生成多个库、可执行文件或驱动
    * 一个 Makefile 同时支持 Normal Build 模式(源码和编译输出分离模式和不分离模式)和 Yocto Build 方式
    * 支持自动分析头文件作为编译依赖，支持分别指定源文件的 CFLAGS 等
    * 提供编译静态库、共享库和可执行文件的模板 `inc.app.mk`，支持 C(`*.c`) C++(`*.cc *.cp *.cxx *.cpp *.CPP *.c++ *.C`) 和 汇编(`*.S *.s *.asm`) 混合编译
    * 提供编译驱动的模板 `inc.mod.mk`，支持 C(`*.c`) 和 汇编(`*.S`) 混合编译
    * 提供安装的模板 `inc.ins.mk`
    * 提供 Kconfig 配置参数的模板 `inc.conf.mk`
<br>

* 网络和缓存处理工具: 处理网络包的下载、打补丁、编译、安装，支持源码镜像和缓存镜像
    * 提供方便可靠的补丁机制 `exec_patch.sh`
    * 提供自动拉取网络包工具，支持从 http(支持 md5)、git(支持 branch tag revision)或 svn(支持 revision) 下载包，支持镜像下载 `fetch_package.sh`
    * 提供编译缓存工具，再次编译不需要从代码编译，直接从本地缓存或网络缓存拉取 `process_cache.sh`
    * 提供方便的缓存编译模板 `inc.cache.mk`
    * 提供丰富的开源包 OSS 层，开源包不断增加中
<br>

* 测试用例可以查看 [examples_zh-cn.md](./examples/examples_zh-cn.md)


## 笔记

* 如果对 Shell 语法不了解，可以查看 [Shell 笔记](./notes/shell.md)
* 如果对 Makefile 语法不了解，可以查看 [Makefile 笔记](./notes/makefile.md)
* 如果对 Kconfig 语法不了解，可以查看 [Kconfig 笔记](./notes/kconfig.md)


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

## 任务分析处理

### 编译架构

* Normal Build 组成:
    * 应用和驱动的编译脚本都是由 Makefile + DEPS-statement 组成
    * 编译链通过 DEPS-statement 定义的依赖关系组装(包级别的依赖)
    * DEPS-statement 基本只需要定义依赖，遵循 CBuild 定义的组装规则
    * 脚本分析所有包的 DEPS-statement 自动生成所有包的编译链，所有包都是一个一个单独编译，可以单独进入包下敲 make 编译
    * 支持 Kconfig 自己管理或托管，托管的 Kconfig 必需放置和 DEPS-statement 语句文件的同目录，无需手动指定父子包含关系，而是由脚本自动分析组装
* Yocto Build 组成:
    * 应用和驱动的编译脚本都是由 Makefile + Recipe 组成
    * 编译链通过在 Recipe 中定义的 DEPENDS / RDEPENDS 依赖关系组装(包级别的依赖)
    * 自定义包的 Recipe 基本只需要定义依赖，遵循 Yocto 定义的组装规则
    * 扩展 Yocto 编译，脚本分析所有包的 Recipe 的文件名和自定义包的 Recipe 的 DEPENDS 变量自动生成所有包的编译链
    * 扩展 Yocto 编译，支持弱依赖，可通过 `make menuconfig` 修改 rootfs (增加包、删除包、修改配置等)

### gen_build_chain.py 命令参数

* 命令说明
    * 带中括号表示是可选项，否则是必选项
    * Normal Build 只需一步自动生成 Kconfig 和 Makefile
    * Yocto Build 需要两步分别自动生成 Kconfig 和 Image 配方，会自动分析 `conf/local.conf` `conf/bblayers.conf` 和层下的配方文件和配方附加文件

    ```sh
    # Normal Build
    gen_build_chain.py -m MAKEFILE_OUT -k KCONFIG_OUT [-t TARGET_OUT] [-a DEPENDS_OUT] -d DEP_NAME [-v VIR_NAME] [-c CONF_NAME] -s SEARCH_DIRS [-i IGNORE_DIRS] [-g GO_ON_DIRS] [-l MAX_LAYER_DEPTH] [-w KEYWORDS] [-p PREPEND_FLAG]

    # Yocto Build Step1
    gen_build_chain.py -k KCONFIG_OUT -t TARGET_OUT [-v VIR_NAME] [-c CONF_NAME] [-i IGNORE_DIRS] [-l MAX_LAYER_DEPTH] [-w KEYWORDS] [-p PREPEND_FLAG] [-u USER_METAS]

    # Yocto Build Step2
    gen_build_chain.py -t TARGET_PATH -c DOT_CONFIG_NAME -o RECIPE_IMAGE_NAME [-p $PATCH_PKG_PATH] [-i IGNORE_RECIPES]
    ```

* Normal Build 命令选项
    * `-m <Makefile Path>`: 指定自动生成的 Makefile 文件路径名
        * 可以使用一个顶层 Makefile 包含自动生成的 Makefile，all 目标调用 `make $(ENV_BUILD_JOBS) $(ENV_MAKE_FLAGS) MAKEFLAGS= all_targets` 多线程编译所有包
        * 如果某个包的内部需要启用多线程编译，需要在此包的其它目标中指定 `jobserver`，见下面章节说明
        * 可以统计各个包的编译时间，Makefile 示例如下:
            ```makefile
            TIME_FORMAT    := /usr/bin/time -a -o $(OUT_PATH)/time_statistics -f \"%e\\t\\t%U\\t\\t%S\\t\\t\$$@\"

            total_time: loadconfig
            	@$(PRECMD)make -s all_targets
            	@echo "Build done!"

            time_statistics:
            	@mkdir -p $(OUT_PATH)
            	@$(if $(findstring dash,$(shell readlink /bin/sh)),echo,echo -e) "real\t\tuser\t\tsys\t\tpackage" > $(OUT_PATH)/$@
            	@make -s PRECMD="$(TIME_FORMAT) " total_time
            ```
    * `-k <Kconfig Path>`: 指定自动生成的 Kconfig 文件路径名
    * `-t <Target Path>`: 指定自动生成的存储包名和源码路径列表的文件路径名
    * `-a <Depends Path>`: 指定自动生成的存储包名和依赖列表的文件路径名
    * `-d <Search Depend Name>`: 指定要搜索的依赖文件名(含有依赖规则语句)，依赖文件中可以包含多条依赖信息
    * `-c <Search Kconfig Name>`: 指定要搜索的 Kconfig 配置文件名(含有配置信息)
        * 查找和依赖文件同目录的配置文件，优先查找和配置文件名相同后缀的文件名为包名的配置文件，找不到才查找指定配置文件
    * `-v <Search Virtual Depend Name>`: 指定要搜索的虚拟依赖文件名(含有虚拟依赖规则语句)
    * `-s <Search Directories>`: 指定搜索的目录文件路径名，多个目录使用冒号隔开
    * `-i <Ignore Directories>`: 指定忽略的目录名，不会搜索指定目录名下的依赖文件，多个目录使用冒号隔开
    * `-g <Go On Directories>`: 指定继续搜索的的目录文件路径名，多个目录使用冒号隔开
        * 如果在当前目录下搜索到 `<Search Depend Name>`，`<Go On Directories>` 没有指定或当前目录不在它里面，不会再继续搜索当前目录的子目录
    * `-l <Max Layer Depth>`: 设置 menuconfig 菜单的最大层数，0 表示菜单平铺，1表示2层菜单，...
    * `-w <Keyword Directories>`: 设置 menuconfig 菜单的忽略层级名，如果路径中的目录匹配设置值，则这个路径的层数减1，设置的多个目录使用冒号隔开
    * `-p <prepend Flag>`: 设置生成的 Kconfig 中配置项的前缀，如果用户运行 conf / mconf 时设置了无前缀 `CONFIG_=""`，则运行此脚本需要设置此 flag 为 1
<br>

* Yocto Build Step1 命令选项
    * `-k <Kconfig Path>`: 指定自动生成的 Kconfig 文件路径名
    * `-t <Target Path>`: 指定自动生成的存储包名和源码路径列表的文件路径名
    * `-c <Search Kconfig Name>`: 指定要搜索的 Kconfig 配置文件名(含有配置信息)
        * 优先查找当前目录下的 `配方名.bbconfig` 文件，找不到才在 bbappend 文件中 EXTERNALSRC 变量指定的路径下查找配置文件，优先查找和配置文件名相同后缀的文件名为包名的配置文件，找不到才查找指定配置文件
    * `-v <Search Virtual Depend Name>`: 指定要搜索的虚拟依赖文件名(含有虚拟依赖规则语句)
    * `-i <Ignore Directories>`: 指定忽略的目录名，不会搜索指定目录名下的依赖文件，多个目录使用冒号隔开
    * `-l <Max Layer Depth>`: 设置 menuconfig 菜单的最大层数，0 表示菜单平铺，1表示2层菜单，...
    * `-w <Keyword Directories>`: 设置 menuconfig 菜单的忽略层级名，如果路径中的目录匹配设置值，则这个路径的层数减1，设置的多个目录使用冒号隔开
    * `-p <prepend Flag>`: 设置生成的 Kconfig 中配置项的前缀，如果用户运行 conf / mconf 时设置了无前缀 `CONFIG_=""`，则运行此脚本需要设置此 flag 为 1
    * `-u <User Metas>`: 指定用户层，多个层使用冒号隔开。只有用户层的包才会: 分析依赖关系，默认选中，托管 Kconfig，支持 `EXTRADEPS` 特殊依赖和虚拟依赖
<br>

* Yocto Build Step2 命令选项
    * `-t <Target Path>`: 指定自动生成的存储包名和源码路径列表的文件路径名
    * `-c <Search Kconfig Path>`: 指定配置文件 .config 的路径名
    * `-o <Output Recipe Path>`: 指定存储 rootfs 安装包列表的文件路径名
    * `-p <Output patch/unpatch Path>`: 指定存储使能的打/去补丁包列表的文件路径名，`prepare-patch` 包 include 此文件
    * `-i <Ignore Recipes>`: 指定的是忽略的配方名，多个配方名使用冒号隔开


### Normal Build 实依赖规则

* 实依赖格式: `#DEPS(Makefile_Name) Target_Name(Other_Target_Names): Depend_Names`

    ![实依赖正则表达式](./scripts/bin/regex_deps.svg)

* 包含子路径格式: `#INCDEPS: Subdir_Names`

    ![包含子路径正则表达式](./scripts/bin/regex_incdeps.svg)

* 格式说明
    * Makefile_Name: make 运行的 Makefile 的名称 (可以为空)，不为空时 make 会运行指定的 Makefile (`make -f Makefile_Name`)
        * Makefile 中必须包含 all clean install 三个目标，默认会加入 all install 和 clean 目标的规则
        * Makefile 名称可以包含路径(即斜杠 `/`)，支持直接查找子文件夹下的子包
            * 例如 `test1/` or `test2/wrapper.mk`
        * 也可以使用 INCDEPS-statement 继续查找子文件夹下的依赖文件，支持递归
            * 例如 `#INCDEPS: test1 test2/test22`，通过子文件夹下的依赖文件找到子包
            * Subdir_Names 支持环境变量替换，例如 `${ENV_BUILD_SOC}` 会替换为环境变量 ENV_BUILD_SOC 的值
    * Target_Name: 当前包的名称ID
        * `ignore` 关键字是特殊的ID，表示此包不是一个包，用来屏蔽当前目录的搜索，一般写成 `#DEPS() ignore():`
    * Other_Target_Names: 当前包的其它目标，多个目标使用空格隔开 (可以为空)
        * 忽略 Other_Target_Names 中的 all install clean 目标
        * `prepare` 关键字是特殊的实目标，表示 make 前运行 make prepare，一般用于当 .config 不存在时加载默认配置到 .config
        * `psysroot` 关键字是特殊的实目标，表示使用 OUT_PATH 的 sysroot 而不是 ENV_TOP_OUT 下的 sysroot / sysroot-native
        * `release` 关键字是特殊的实目标，表示安装进 fakeroot rootfs 时运行 make release，此目标不需要安装头文件和静态库文件等
            * release 目标不存在时，安装到 fakeroot rootfs 时运行 make install
        * `union` 关键字是特殊的虚拟目标，用于多个包共享一个 Makefile
            * 此时 `prepare all install clean release` 目标的名字变为 `Target_Name-prepare Target_Name-all Target_Name-install Target_Name-clean Target_Name-release`
        * `cache` 关键字是特殊的虚拟目标，表明该包支持缓存机制
        * `jobserver` 关键字是特殊的虚拟目标，表示 make 后加上 `$(ENV_BUILD_JOBS)`，用户需要 `export ENV_BUILD_JOBS=-jn` 才会启动多线程编译
            * 某些包的 Makefile 包含 make 指令时不要加上 jobserver 目标，例如编译驱动
        * `subtarget1:subtarget2:...::dep1:dep2:...` 是特殊语法格式，用来显式指定子目标的依赖
            * 双冒号分开子目标列表和依赖列表，子目标之间和依赖之间使用单冒号分隔，依赖列表可以为空
    * Depend_Names: 当前包依赖的其它包的名称ID，多个依赖使用空格隔开 (可以为空)
        * 如果有循环依赖或未定义依赖，解析将会失败，会打印出未解析成功的条目
            * 出现循环依赖，打印 "ERROR: circular deps!"

注:  包的名称ID (Target_Name Depend_Names) 由 **小写字母、数字、短划线** 组成；Other_Target_Names 无此要求，还可以使用 `%` 作为通配符

* Normal Build 命令说明
    * 可以 `make 包名` 先编译某个包的依赖包(有依赖时)再编译这个包
    * 可以 `make 包名_single` 有依赖时才有这类目标，仅仅编译这个包
    * 可以 `make 包名_目标名` 先编译某个包的依赖包(有依赖时)再编译这个包的特定目标(特定目标需要在 Other_Target_Names 中定义)
    * 可以 `make 包名_目标名_single` 有依赖时才有这类目标，仅仅编译这个包的特定目标(特定目标需要在 Other_Target_Names 中定义)


### Yocto Build 实依赖规则

* Yocto Build 的依赖定义在 Recipe 中  (DEPENDS / RDEPENDS / PACKAGECONFIG / ...)
* `DEPENDS`: 编译时依赖的包名
    * 注: Yocto 使用一些主机命令，还可能需要指定依赖主机包 `包名-native`，例如 `bash-native`
* `RDEPENDS:${PN}`: 运行时依赖的包名
    * 注: 有动态库的依赖包需要加到此变量，否则编译报错或依赖的包未安装到 rootfs
* `PACKAGECONFIG`: 动态设置是否依赖安装了 `xxx/usr/lib/pkgconfig/xxx.pc` 的依赖包


### Normal/Yocto Build 虚依赖规则

* 虚依赖格式 `#VDEPS(Virtual_Type) Target_Name(Other_Infos): Depend_Names`

    ![虚依赖正则表达式](./scripts/bin/regex_vdeps.svg)

* Virtual_Type      : 必选，表示虚拟包的类型，目前有 4 种类型
    * `menuconfig`  : 表示生成 `menuconfig` 虚拟包，当前目录(含子目录)下的所有的包强依赖此包，且处于该包的菜单目录下
    * `config`      : 表示生成 `config` 虚拟包
    * `menuchoice`  : 表示生成 `choice` 虚拟包，当前目录(含子目录)下的所有的包会成为 choice 下的子选项
    * `choice`      : 表示生成 `choice` 虚拟包，Other_Infos 下的包列表会成为 choice 下的子选项
* Virtual_Name      : 必选，虚拟包的名称
* Other_Infos       : choice 类型必选，其它类型可选
    * 对所有类型来说，可以出现一个以 `/` 开头的路径名项(可选)，表示作用于指定的子目录而不是当前目录
        * 对 config choice 类型来说，路径名项可以指定一个虚拟路径，例如 `/virtual` (virtual 可以是任意单词)，此时虚拟项目在当前目录(而不是上层目录)下显示
    * 对 choice 类型来说，空格分开的包列表会成为 choice 下的子选项，其中第一个包为默认选择的包
    * 对 menuchoice 类型来说，可以指定默认选择的包
* Depend_Names      : 可选，依赖项列表，和 `#DEPS` 语句用法基本相同，例如可以设置 `unselect`，choice 和 menuchoice 类型不支持 select 和 imply

注: 虚依赖是指该包不是实际的包，不会参与编译，只是用来组织管理实际包，Normal Build 和 Yocto Build 编译虚拟包的写法和使用规则相同


### 特殊依赖说明

* 特殊依赖(虚拟包)
    * `*depname`    : 表示此依赖包是虚拟包 depname，去掉 `*` 后 depname 还可以有特殊符，会继续解析，例如 `*&&depname`
<br>

* 特殊依赖(关键字)
    * `finally`     : 表示此包编译顺序在所有其它包之后，一般用于最后生成文件系统和系统镜像，只用在Normal Build 的强依赖中
    * `unselect`    : 表示此包默认不编译，即 `default n`，否则此包默认编译，即 `default y`
    * `nokconfig`   : 表示此包不含 Kconfig 配置。同一目录有多个包时，此包无需设置 `nokconfig`，而其它包也有配置可以将配置的文件名设为 **包名.配置的后缀** ，否则需要设置 nokconfig
<br>

* 特殊依赖(特殊符)
    * `!depname`                    : 表示此包和 depname 包冲突，无法同时开启，即 `depends on !depname`
    * `&depname` or `&&depname`     : 表示此包弱/强选中 depname 包，即 `imply depname` / `select depname`
        * 单与号表示此包选中后，imply 的 depname 也被自动选中，此时 depname 也可以手动取消选中
        * 双与号表示此包选中后，select 的 depname 也被自动选中，此时 depname 不可以取消选中
    * `?depname` or `??depname`     : 表示此包弱依赖 depname 包，即 `if .. endif`
        * 弱依赖是指即使 depname 包未选中或不存在，依赖它的包也可以选中和编译成功
        * 单问号表示编译时依赖(依赖包没有安装动态库等)
        * 双问号表示编译时和运行时依赖(依赖包安装了动态库等)
    * `depa|depb` or `depa||depb`   : 表示此包弱依赖 depa depb ...
        * 弱依赖列表中的包至少需要一个 depx 包选中，依赖它的包才可以选中和编译成功
        * 单竖线表示编译时依赖
        * 双竖线表示编译时和运行时依赖
        * 省略 `|` `||` 前面的单词会被隐式推导使用预编译包或源码包中选一，例如 `||libtest` 被隐式推导为 `prebuild-libtest||libtest`
    * `& ?`                         : `&` 可以和 `?` 组合使用，不要求组合顺序，表示选中并弱依赖
        * 例如： `&&??depname` 或 `??&&depname` 等表示强选中弱依赖，`??&depname` 或 `&??depname` 等表示弱依赖弱选中
    * `& |`                         : `&` 可以和 `|` 组合使用，表示选中其中一个包并弱依赖所有实包
        * 适合强选中并弱依赖预编译包和源码包选择其一
        * 省略最后一个 `|` `||` 前面的字符直到 `&`被隐式推导为 `*build-包名 prebuild-包名 包名` 三元组
        * 例如： `&&||libtest` 被隐式推导为 `&&*build-libtest||prebuild-libtest||libtest`
        * 例如： `&&*build-libtest||prebuild-libtest||libtest` 表示强选中这三个包中第一个存在的包，并弱依赖后面两个实包
    * 其它说明:
        * 对Normal Build 来说，`?` `??` 没有区别，`|` `||` 没有区别
        * 对 Yocto Build 来说，`?` `|` 中的弱依赖只会设置 `DEPENDS`，`??` `||` 中的弱依赖会同时设置 `DEPENDS` 和 `RDEPENDS:${PN}`
<br>

* 特殊依赖(环境变量)
    * ENVNAME=val1,val2 : 表示此包依赖环境变量 ENVNAME 的值等于 val1 或等于 val2
    * ENVNAME!=val1,val2: 表示此包依赖环境变量 ENVNAME 的值不等于 val1 且不等于 val2

* 注: 特殊依赖 Normal Build 时设置的是 `#DEPS` 语句的 `Depend_Names` 元素，Yocto Build 时赋值给配方文件的 `EXTRADEPS` 变量，且如果 EXTRADEPS 中含有弱依赖，需要继承类 `inherit weakdep`
    * `weakdep` 类会解析输出根目录的 `config/.config` 文件，根据是否选中此项来设置 `DEPENDS` 和 `RDEPENDS:${PN}`
    * 可以设置 `conf/bblayers.conf` 中的 `BBFILES` 变量，指定查找自动生成的 image 配方的路径，例如 `BBFILES ?= "${TOPDIR}/config/*.bb"`


### 生成依赖关系图 gen_depends_image.sh

* `scripts/bin/gen_depends_image.sh` 命令参数
    * 参数1: 包名
    * 参数2: 存储图片的文件夹路径
    * 参数3: 包名列表等
        * Normal Build 是存储包名和依赖列表的文件路径(gen_build_chain.py 的 `-a` 指定的路径)
        * Yocto Build 是存储包名和源码路径的文件路径(gen_build_chain.py 的 `-t` 指定的路径)
    * 参数4: 配置文件 .config 的路径
<br>

* 生成图片说明
    * 使用方法 `make 包名-deps`
    * Normal Build
        * 实线：强依赖
        * 虚线：弱依赖
        * 双线：prebuild 和 srcbuild 选其一，或 patch 和 unpatch 选其一
        * 绿线：配置文件 .config 中该包已经被选中
        * 红线：配置文件 .config 中该包没有被选中
        * 顶层包框颜色
            * 绿框：配置文件 .config 中该包已经被选中
            * 红框：配置文件 .config 中该包没有被选中
    * Yocto Build
        * 绿框：用户包，配置文件 .config 中该包已经被选中
        * 红框：用户包，配置文件 .config 中该包没有被选中
        * 篮框：Yocto 等社区的包 (没有在 gen_build_chain.py 的 `-u` 指定的层中)


## 环境设置

### 初始化编译环境

* 初始化编译环境运行如下命令

    ```sh
    lengjing@lengjing:~/data/cbuild$ source scripts/build.env
    ============================================================
    ENV_BUILD_MODE   : external
    ENV_BUILD_JOBS   : -j8
    ENV_MAKE_FLAGS   : -s
    ENV_TOP_DIR      : /home/lengjing/data/cbuild
    ENV_MAKE_DIR     : /home/lengjing/data/cbuild/scripts/core
    ENV_TOOL_DIR     : /home/lengjing/data/cbuild/scripts/bin
    ENV_DOWN_DIR     : /home/lengjing/data/cbuild/output/mirror-cache/downloads
    ENV_CACHE_DIR    : /home/lengjing/data/cbuild/output/mirror-cache/build-cache
    ENV_MIRROR_URL   : http://127.0.0.1:8888
    ENV_TOP_OUT      : /home/lengjing/data/cbuild/output/noarch
    ENV_CFG_ROOT     : /home/lengjing/data/cbuild/output/noarch/config
    ENV_OUT_ROOT     : /home/lengjing/data/cbuild/output/noarch/objects
    ENV_INS_ROOT     : /home/lengjing/data/cbuild/output/noarch/sysroot
    ENV_DEP_ROOT     : /home/lengjing/data/cbuild/output/noarch/sysroot
    ENV_OUT_HOST     : /home/lengjing/data/cbuild/output/noarch/objects-native
    ENV_INS_HOST     : /home/lengjing/data/cbuild/output/noarch/sysroot-native
    ENV_DEP_HOST     : /home/lengjing/data/cbuild/output/noarch/sysroot-native
    ============================================================
    ```

* 还可以通过 soc 名字导出交叉编译环境

    ```sh
    lengjing@lengjing:~/data/cbuild$ source scripts/build.env cortex-a53
    ============================================================
    ENV_BUILD_MODE   : external
    ENV_BUILD_SOC    : cortex-a53
    ENV_BUILD_ARCH   : arm64
    ENV_BUILD_TOOL   : /output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/bin/aarch64-linux-gnu-
    ENV_BUILD_JOBS   : -j8
    ENV_MAKE_FLAGS   : -s
    KERNEL_VER       : 5.15.88
    KERNEL_SRC       : /home/lengjing/data/cbuild/output/kernel/linux-5.15.88
    KERNEL_OUT       : /home/lengjing/data/cbuild/output/cortex-a53/objects/linux-5.15.88
    ENV_TOP_DIR      : /home/lengjing/data/cbuild
    ENV_MAKE_DIR     : /home/lengjing/data/cbuild/scripts/core
    ENV_TOOL_DIR     : /home/lengjing/data/cbuild/scripts/bin
    ENV_DOWN_DIR     : /home/lengjing/data/cbuild/output/mirror-cache/downloads
    ENV_CACHE_DIR    : /home/lengjing/data/cbuild/output/mirror-cache/build-cache
    ENV_MIRROR_URL   : http://127.0.0.1:8888
    ENV_TOP_OUT      : /home/lengjing/data/cbuild/output/cortex-a53
    ENV_CFG_ROOT     : /home/lengjing/data/cbuild/output/cortex-a53/config
    ENV_OUT_ROOT     : /home/lengjing/data/cbuild/output/cortex-a53/objects
    ENV_INS_ROOT     : /home/lengjing/data/cbuild/output/cortex-a53/sysroot
    ENV_DEP_ROOT     : /home/lengjing/data/cbuild/output/cortex-a53/sysroot
    ENV_OUT_HOST     : /home/lengjing/data/cbuild/output/cortex-a53/objects-native
    ENV_INS_HOST     : /home/lengjing/data/cbuild/output/cortex-a53/sysroot-native
    ENV_DEP_HOST     : /home/lengjing/data/cbuild/output/cortex-a53/sysroot-native
    ============================================================
    ```

* 生成交叉编译工具链

    ```sh
    lengjing@lengjing:~/data/cbuild$ source scripts/build.env cortex-a53
    lengjing@lengjing:~/data/cbuild$ make -C scripts/toolchain
    ```

注: 用户需要自己在 process_machine.sh 中填写 soc 相关的参数，目前该文件中只举例了 cortex-a53 和 cortex-a9


### 环境变量说明

* ENV_BUILD_MODE: 设置编译模式: external, 源码和编译输出分离; internal, 编译输出到源码; yocto, Yocto Build 方式
    * external 时，编译输出目录是把包的源码目录的 ENV_TOP_DIR 部分换成了 ENV_OUT_ROOT / ENV_OUT_HOST
* ENV_BUILD_SOC: 指定交叉编译的 SOC，根据 SOC 和 process_machine.sh 脚本得到和 SOC 相关的一系列参数
* ENV_BUILD_ARCH: 指定交叉编译 linux 模块的 ARCH
* ENV_BUILD_TOOL: 指定交叉编译器前缀
* ENV_BUILD_JOBS: 指定编译线程数
* ENV_MAKE_FLAGS: 设置 make 命令的全局参数标记，默认设置了 `-s`
    * `export ENV_MAKE_FLAGS=`: 设为空时将输出详细的编译信息
<br>

* KERNEL_VER: Linux 内核版本
* KERNEL_SRC: Linux 内核解压后的目录路径名
* KERNEL_OUT: Linux 内核编译输出的目录路径名
<br>

* ENV_TOP_DIR: 工程的根目录
* ENV_MAKE_DIR: 工程的编译模板目录
* ENV_TOOL_DIR: 工程的脚本工具目录
* ENV_DOWN_DIR: 下载包的保存路径
* ENV_CACHE_DIR: 包的编译缓存保存路径
* ENV_MIRROR_URL: 下载包的 http 镜像，可用命令 `python -m http.server 端口号` 快速创建 http 服务器
<br>

* ENV_TOP_OUT: 工程的输出根目录，编译输出、安装文件、生成镜像等都在此目录下定义
* ENV_CFG_ROOT: 工程自动生成文件的保存路径，例如全局 Kconfig 和 Makefile，各种统计文件等
* ENV_OUT_ROOT: 源码和编译输出分离时的编译输出根目录
* ENV_INS_ROOT: 工程安装文件的根目录
* ENV_DEP_ROOT: 工程搜索库和头文件的根目录
* ENV_OUT_HOST: 本地编译源码和编译输出分离时的编译输出根目录
* ENV_INS_HOST: 本地编译工程安装文件的根目录
* ENV_DEP_HOST: 本地编译工程搜索库和头文件的根目录

注: Yocto Build 时，由于 BitBake 任务无法直接使用当前 shell 的环境变量，所以自定义环境变量应由配方文件导出，不需要 source 这个环境脚本


## 编译模板

### 环境模板 inc.env.mk

* 环境模板被应用编译和内核模块编译共用
* Normal Build 时此模板作用是设置编译输出目录 `OUT_PATH`，设置并导出交叉编译环境或本地编译环境
* Yocto Build 时编译输出目录和交叉编译环境由 `bitbake` 设置并导出

#### 环境模板的函数说明

* `$(call safe_copy,cp选项,源和目标)`: 非 Yocto Build 时使用加文件锁的 cp，防止多个目标多进程同时安装目录时报错
* `$(call link_hdrs)`: 根据 SEARCH_HDRS 变量的值自动生成查找头文件的 CFLAGS
* `$(call link_libs)`: 自动生成查找库文件的 LDFLAGS
* `$(call prepare_sysroot)`: Normal Build 时在 OUT_PATH 目录准备 sysroot


#### 环境模板的变量说明

* PACKAGE_NAME: 包的名称 (要和 DEPS语句的包名一致，本地编译的 PACKAGE_NAME 不需要加后缀 `-native`)
* PACKAGE_ID: 只读，包的实际名称，交叉编译时等于 PACKAGE_NAME 的值，本地编译时会加上后缀 `-native`
* INSTALL_HDR: 头文件安装的子文件夹，默认值等于 PACKAGE_NAME 的值
* PACKAGE_DEPS: 包的依赖列表，未来可能会删除
* SEARCH_HDRS: 查找头文件子目录列表，默认值等于 PACKAGE_DEPS 的值
<br>

* OUT_PREFIX : 顶层编译输出目录，本地编译取值 ENV_OUT_HOST，交叉编译取值 ENV_OUT_ROOT
* INS_PREFIX : 顶层编译安装目录，本地编译取值 ENV_INS_HOST，交叉编译取值 ENV_INS_ROOT
* DEP_PREFIX : 顶层依赖查找目录，本地编译取值 ENV_DEP_HOST，交叉编译取值 ENV_DEP_ROOT
* PATH_PREFIX: 顶层本地工具查找目录
* OUT_PATH   : 输出目录
<br>

* EXPORT_HOST_ENV: 交叉编译包依赖自己编译的本地包时需要设置为 y
* EXPORT_PC_ENV: 设置为 y 时导出 pkg-config 的搜索路径
* BUILD_FOR_HOST: 设置为 y 时表示本地编译(native-compilation)
* PREPARE_SYSROOT: 设置为 y 时Normal Build 使用 OUT_PATH 下的 sysroot 而不是 ENV_TOP_OUT 下的 sysroot / sysroot-native
* LOGOUTPUT: 默认值为 1>/dev/null，置为空时编译 应用(include inc.app.mk) 和 oss 源码时 (include inc.cache.mk) 时输出更多信息


### 安装模板 inc.ins.mk

* 安装模板被应用编译和内核模块编译共用

#### 安装模板的目标和变量说明

* install_libs: 安装库文件集
    * 用户需要设置被安装的库文件集变量 INSTALL_LIBRARIES
    * 编译应用时 `inc.app.mk`，编译生成的库文件会加入到 `LIB_TARGETS` 变量，INSTALL_LIBRARIES 已默认赋值为 `$(LIB_TARGETS)`
    * 安装目录是 `$(INS_PREFIX)/usr/lib`
* install_base_libs: 安装库文件集
    * 用户需要设置被安装的库文件集变量 INSTALL_BASE_LIBRARIES，该变量默认取 INSTALL_LIBRARIES 的值
    * 安装目录是 `$(INS_PREFIX)/lib`
* install_bins: 安装可执行文件集
    * 用户需要设置被安装的可执行文件集变量 INSTALL_BINARIES
    * 编译应用时 `inc.app.mk`，编译生成的可执行文件会加入到 `BIN_TARGETS` 变量，INSTALL_BINARIES 已默认赋值为 `$(BIN_TARGETS)`
    * 安装目录是 `$(INS_PREFIX)/usr/bin`
* install_base_bins: 安装可执行文件集
    * 用户需要设置被安装的可执行文件集变量 INSTALL_BASE_BINARIES，该变量默认取 INSTALL_BINARIES 的值
    * 安装目录是 `$(INS_PREFIX)/bin`
* install_hdrs: 安装头文件集
    * 用户需要设置被安装的头文件集变量 INSTALL_HEADERS
    * 安装目录是 `$(INS_PREFIX)/usr/include/$(INSTALL_HDR)`
* install_datas: 安装数据文件集
    * 用户需要设置被安装的数据文件集变量 INSTALL_DATAS
    * 安装目录是 `$(INS_PREFIX)/usr/share`
* install_datas_xxx / install_todir_xxx / install_tofile_xxx: 安装文件集到特定文件夹
    * 要安装的文件集分别由 INSTALL_DATAS_xxx / INSTALL_TODIR_xxx / INSTALL_TOFILE_xxx 定义
    * 定义的值前面部分是要安装的文件集，最后一项是以斜杆 `/` 开头的安装目标路径
    * install_datas_xxx 安装到目录 `$(INS_PREFIX)/usr/share$(INSTALL_DATAS_xxx最后一项)`
    * install_todir_xxx 安装到目录`$(INS_PREFIX)$(INSTALL_TODIR_xxx最后一项)`
    * install_tofile_xxx 安装到文件`$(INS_PREFIX)$(INSTALL_TOFILE_xxx最后一项)` ，INSTALL_TOFILE_xxx 的值有且只有两项
    * 例子:
        * 创建2个空白文件 testa 和 testb，Makefile 内容如下:

            ```makefile
            INSTALL_DATAS_test = testa testb /testa/testb
            INSTALL_TODIR_test = testa testb /usr/local/bin
            INSTALL_TOFILE_testa = testa /etc/a.conf
            INSTALL_TOFILE_testb = testa /etc/b.conf

            all: install_datas_test install_todir_test install_tofile_testa install_tofile_testb
            include $(ENV_MAKE_DIR)/inc.ins.mk
            ```

        * 运行 make 安装后的文件树

            ```
            sysroot
            ├── etc
            │   ├── a.conf
            │   └── b.conf
            └── usr
                ├── local
                │   └── bin
                │       ├── testa
                │       └── testb
                └── share
                    └── testa
                        └── testb
                            ├── testa
                            └── testb
            ```


### 应用模板 inc.app.mk

* 应用模板用于编译动态库、静态库和可执行文件

#### 应用模板的目标说明

* LIBA_NAME: 编译单个静态库时需要设置静态库名
    * 编译生成的静态库文件路径会加入到 `LIB_TARGETS` 变量
* LIBSO_NAME: 编译单个动态库时需要设置动态库名
    * LIBSO_NAME 可以设置为 `库名 主版本号 次版本号 补丁版本号` 格式，例如
        * `LIBSO_NAME = libtest.so 1 2 3` 编译生成动态库 libtest.so.1.2.3，并创建符号链接 libtest.so 和 libtest.so.1
        * `LIBSO_NAME = libtest.so 1 2`   编译生成动态库 libtest.so.1.2  ，并创建符号链接 libtest.so 和 libtest.so.1
        * `LIBSO_NAME = libtest.so 1`     编译生成动态库 libtest.so.1    ，并创建符号链接 libtest.so
        * `LIBSO_NAME = libtest.so`       编译生成动态库 libtest.so
    * 如果 LIBSO_NAME 带版本号，默认指定的 soname 是 `libxxxx.so.x`，可以通过 LDFLAGS 覆盖默认值
        * 例如 `LDFLAGS += -Wl,-soname=libxxxx.so`
    * 编译生成的动态库文件路径和符号链接路径会加入到 `LIB_TARGETS` 变量
* BIN_NAME: 编译单个可执行文件时需要设置可执行文件名
    * 编译生成的可执行文件会加入到 `BIN_TARGETS` 变量


#### 应用模板的函数说明

* `$(eval $(call add-liba-build,静态库名,源文件列表))`: 创建编译静态库规则
* `$(eval $(call add-libso-build,动态库名,源文件列表))`: 创建编译动态库规则
    * 动态库名可以设置为 `库名 主版本号 次版本号 补丁版本号` 格式，参考 LIBSO_NAME 的说明
* `$(eval $(call add-libso-build,动态库名,源文件列表,链接参数))`: 创建编译动态库规则
    * 注意函数中有逗号要用变量覆盖，例如 `$(eval $(call add-libso-build,动态库名,源文件列表,-Wl$(comma)-soname=libxxxx.so))`
* `$(eval $(call add-bin-build,可执行文件名,源文件列表))`: 创建编译可执行文件规则
* `$(eval $(call add-bin-build,可执行文件名,源文件列表,链接参数))`: 创建编译可执行文件规则
* `$(call set_flags,标记名称,源文件列表,标记值)`: 单独为指定源码集合设置编译标记
    * 例如 `$(call set_flags,CFLAGS,main.c src/read.c src/write.c,-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE)`

注: 提供上述函数的原因是可以在一个 Makefile 中编译出多个库或可执行文件


#### 应用模板的可设置变量说明

* SRC_PATH: 包中源码所在的目录，默认是包的根目录，也有的包将源码放在 src 下
    * 也可以指定包下多个(不交叉)目录的源码，例如 `SRC_PATH = src1 src2 src3`
* IGNORE_PATH: 查找源码文件时，忽略搜索的目录名集合，默认已忽略 `.git scripts output` 文件夹
* REG_SUFFIX: 支持查找的源码文件的后缀名，默认查找以 `c cpp S` 为后缀的源码文件
    * 可以修改为其它类型的文件，从 c 和 CPP_SUFFIX / ASM_SUFFIX 定义的类型中选择
        * CPP_SUFFIX: C++类型的文件后缀名，默认定义为 `cc cp cxx cpp CPP c++ C`
        * ASM_SUFFIX: 汇编类型的文件后缀名，默认定义为 `S s asm`
    * 如果支持非 CPP_SUFFIX / ASM_SUFFIX 默认定义类型的文件，只需要修改 REG_SUFFIX 和 CPP_SUFFIX / ASM_SUFFIX ，并定义函数
    * 例如增加 cxx 类型的支持(CPP_SUFFIX 已有定义 cxx)：
        ```makefile
        REG_SUFFIX = c cpp S cxx
        include $(ENV_MAKE_DIR)/inc.app.mk
        ```
    * 例如增加 CXX 类型的支持(CPP_SUFFIX 还未定义 CXX)：
        ```makefile
        REG_SUFFIX = c cpp S CXX
        CPP_SUFFIX = cc cp cxx cpp CPP c++ C CXX
        include $(ENV_MAKE_DIR)/inc.app.mk
        $(eval $(call compile_obj,CXX,$$(CXX)))
        ```
* USING_CXX_BUILD_C: 设置为 y 时 `*.c` 文件也用 CXX 编译
* SRCS: 所有的源码文件，默认是 SRC_PATH 下的所有的 `*.c *.cpp *.S` 文件
    * 如果用户指定了 SRCS，也可以设置 SRC_PATH 将 SRC_PATH 和 SRC_PATH 下的 include 加入到头文件搜索的目录
    * 如果用户指定了 SRCS，忽略 IGNORE_PATH 的值
* CFLAGS: 用户可以设置包自己的一些全局编译标记(用于 `gcc g++` 命令)
* AFLAGS: 用户可以设置包自己的一些全局汇编标记(用于 `as` 命令)
* LDFLAGS: 用户可以设置包自己的一些全局链接标记
* CFLAGS_xxx.o: 用户可以单独为指定源码 `xxx.c / xxx.cpp / ... / xxx.S` 设置编译标记
* AFLAGS_xxx.o: 用户可以单独为指定源码 `xxx.s / xxx.asm` 设置编译标记
* DEBUG: 设置为 y 时使用 `-O0 -g -ggdb` 编译


### 配置模板 inc.conf.mk

* 配置模板提供 Kongfig　配置参数

#### 配置模板的目标说明

* loadconfig: 如果 .config 不存在，加载 DEF_CONFIG 指定的默认配置
* defconfig: 还原当前配置为 DEF_CONFIG 指定的默认配置
* menuconfig: 图形化配置工具
* syncconfig: 手动更改 .config 后更新 config.h
* cleanconfig: 清理配置文件
* xxx_config: 将 CONF_SAVE_PATH 下的 xxx_config 作为当前配置
* xxx_saveconfig: 将当前配置保存到 CONF_SAVE_PATH 下的 xxx_config
* xxx_defonfig: 将 CONF_SAVE_PATH 下的 xxx_defconfig 作为当前配置
* xxx_savedefconfig: 将当前配置保存到 CONF_SAVE_PATH 下的 xxx_defconfig


#### 配置模板的可设置变量说明

* OUT_PATH: 编译输出目录，保持默认即可
* CONF_SRC: kconfig 工具的源码目录，目前是在 `$(ENV_TOP_DIR)/scripts/kconfig`，和实际一致即可
* CONF_PATH: kconfig 工具的安装目录，和实际一致即可
* CONF_PREFIX: 设置 conf 运行的变量，主要是下面两个设置
    * `srctree=path_name`: Kconfig 文件中 source 其它配置参数文件的相对的目录是 srctree 指定的目录，如果不指定，默认是运行 `conf/mconf` 命令的目录
    * `CONFIG_=""` : 设置生成的 .config 和 config.h 文件中的选项名称(对比 Kconfig 对应的选项名称)的前缀，不设置时，默认值是 `CONFIG_`，本例的设置是无前缀
* CONF_HEADER: 设置生成的 config.h 中使用的包含宏，默认值是 `__大写包名_CONFIG_H__`
    * kconfig 生成的头文件默认不包含宏 `#ifndef xxx ... #define xxx ... #endif`，本模板使用 sed 命令添加了宏
* KCONFIG: 配置参数文件，默认是包下的 Kconfig 文件
* CONF_SAVE_PATH: 配置文件的获取和保存目录，默认是包下的 config 目录
* CONF_APPEND_CMD: config 改变时追加运行的命令

注: 目录下的 [Kconfig](./examples/test-conf/Kconfig) 文件也说明了如何写配置参数


#### scripts/kconfig 工程说明

* 源码完全来自 linux-5.18 内核的 `scripts/kconfig`
* 在原始代码的基础上增加了命令传入参数 `CONFIG_PATH` `AUTOCONFIG_PATH` `AUTOHEADER_PATH`，原先这些参数要作为环境变量传入
* Makefile 是完全重新编写的


### 驱动模板 inc.mod.mk

* 驱动模板用于编译外部内核模块

#### 驱动模板的 Makefile 部分说明 (KERNELRELEASE 为空时)

* 支持的目标
    * modules: 编译驱动
    * modules_clean: 清理内核模块的编译输出
    * modules_install: 安装内核模块
        * 驱动默认的安装路径为 `$(INS_PREFIX)/lib/modules/<kernel_release>/extra/`
    * symvers_install: 安装 Module.symvers 符号文件到指定位置(已设置此目标为 `install_hdrs` 目标的依赖)
<br>

* 可设置的变量
    * MOD_MAKES: 用户指定一些模块自己的信息，例如 XXXX=xxxx
    * KERNEL_SRC: Linux 内核源码目录 (必须）
    * KERNEL_OUT: Linux 内核编译输出目录 （`make -O $(KERNEL_OUT)` 编译内核的情况下必须）


#### 驱动模板的 Kbuild 部分说明 (KERNELRELEASE 有值时)

* 支持的目标
    * MOD_NAME: 模块名称，可以是多个模块名称使用空格隔开
<br>

* 可设置的变量
    * IGNORE_PATH: 查找源码文件时，忽略搜索的目录名集合，默认已忽略 `.git scripts output` 文件夹
    * SRCS: 所有的 C 和汇编源码文件，默认是当前目录下的所有的 `*.c *.S` 文件
    * `ccflags-y` `asflags-y` `ldflags-y`: 分别对应内核模块编译、汇编、链接时的参数
<br>

* 提供的函数
    * `$(call translate_obj,源码文件集)`: 将源码文件集名字转换为KBUILD需要的 `*.o` 格式，不管源码是不是以 `$(src)/` 开头
    * `$(call set_flags,标记名称,源文件列表,标记值)`: 单独为指定源码集设置编译标记，参考 inc.app.mk 的说明
<br>

* 其它说明
    * 如果 MOD_NAME 含有多个模块名称，需要用户自己填写各个模块下的对象，例如

        ```makefile
        MOD_NAME = mod1 mod2
        mod1-y = a1.o b1.o c1.o
        mod2-y = a2.o b2.o c2.o
        ```

    * 使用源码和编译输出分离时， 需要先将 Kbuild 或 Makefile 复制到 OUT_PATH 目录下，如果不想复制，需要修改内核源码的 `scripts/Makefile.modpost`，linux-5.19 内核和最新版本的 LTS 内核已合并此补丁

        ```makefile
        -include $(if $(wildcard $(KBUILD_EXTMOD)/Kbuild), \
        -             $(KBUILD_EXTMOD)/Kbuild, $(KBUILD_EXTMOD)/Makefile)
        +include $(if $(wildcard $(src)/Kbuild), $(src)/Kbuild, $(src)/Makefile)
        ```


## 网络、缓存和 OSS 层

* 仅适用于 Normal Build

### 下载 fetch_package.sh

* 用法 `fetch_package.sh <method> <urls> <package> [outdir] [outname]`
    *  outdir outname 不指定时只下载包，不复制或解压到输出
    * method: 包下载方式，目前支持 4 种方式
        * tar: 可用 `tar` 命令解压的包，使用 `curl` 下载包，后缀名为 `tar.gz` `tar.bz2` `tar.xz` `tar` 等
        * zip: 使用 `unzip` 命令解压的包，使用 `curl` 下载包，后缀名为 `gz` `zip` 等
        * git: 使用 `git clone` 下载包
        * svn: 使用 `svn checkout` 下载包
    * urls: 下载链接
        * tar/zip: 最好同时设置 MD5, 例如:
            * `https://xxx/xxx.tar.xz;md5=yyy`
            * `https://xxx/xxx.gz;md5=yyy`
        * git: 最好同时设置 branch / tag / revision (tag 和 revision 不要同时设置)，例如:
            * `https://xxx/xxx.git;branch=xxx;tag=yyy`
            * `https://xxx/xxx.git;branch=xxx;rev=yyy`
            * `https://xxx/xxx.git;tag=yyy`
            * `https://xxx/xxx.git;rev=yyy`
        * svn: 最好同时设置 revision, 例如:
            * `https://xxx/xxx;rev=yyy`
    * package: tar zip 是保存的文件名，git svn 是保存的文件夹名，保存的目录是 `ENV_DOWN_DIR`
    * outdir: 解压或复制到的目录，用于编译
    * outname: outdir 中包的文件夹名称

注: 下载包优先尝试 `ENV_MIRROR_URL` 指定的镜像 URL 下载包，下载失败时才从原始的 URL 下载


### 打补丁 exec_patch.sh

* 用法 `exec_patch.sh <method> <patch_srcs> <patch_dst>`
    * method: 只有两个值: patch 打补丁，unpatch 去补丁
    * patch_srcs: 补丁的文件或存储的目录的路径名，可以是多个项目
    * patch_dst: 要打补丁的源码路径名
<br>

* 例子: 选择是否打补丁的方法
    * 每类补丁建立两个包，打补丁包和去补丁包，包名格式必须为 `源码包名-patch-补丁ID名` 和 `源码包名-unpatch-补丁ID名`
    * 源码包弱依赖这两个包，源码包的 `#DEPS` 语句的 Depend_Names 加上 `xxx-patch-xxx|xxx-unpatch-xxx`
    * 建立虚依赖规则文件 `#VDEPS(choice) xxx-patch-xxx-choice(xxx-unpatch-xxx xxx-patch-xxx):`
    * 源码包的所有补丁包共用一个 Makefile，示例如下:
        * PATCH_PACKAGE : 源码包名
        * PATCH_TOPATH  : 源码路径
        * PATCH_FOLDER  : 补丁存放路径
        * PATCH_NAME_补丁ID名 : 补丁名，可以是多个补丁

    ```makefile
    PATCH_SCRIPT        := $(ENV_TOOL_DIR)/exec_patch.sh
    PATCH_PACKAGE       := xxx
    PATCH_TOPATH        := xxx

    PATCH_FOLDER        := xxx
    PATCH_NAME_xxx      := 0001-xxx.patch
    PATCH_NAME_yyy      := 0001-yyy.patch 0002-yyy.patch

    $(PATCH_PACKAGE)-unpatch-all:
    	@$(PATCH_SCRIPT) unpatch $(PATCH_FOLDER) $(PATCH_TOPATH)
    	@echo "Unpatch $(PATCH_TOPATH) Done."

    $(PATCH_PACKAGE)-patch-%-all:
    	@$(PATCH_SCRIPT) patch "$(patsubst %,$(PATCH_FOLDER)/%,$(PATCH_NAME_$(patsubst $(PATCH_PACKAGE)-patch-%-all,%,$@)))" $(PATCH_TOPATH)
    	@echo "Build $(patsubst %-all,%,$@) Done."

    $(PATCH_PACKAGE)-unpatch-%-all:
    	@$(PATCH_SCRIPT) unpatch "$(patsubst %,$(PATCH_FOLDER)/%,$(PATCH_NAME_$(patsubst $(PATCH_PACKAGE)-unpatch-%-all,%,$@)))" $(PATCH_TOPATH)
    	@echo "Build $(patsubst %-all,%,$@) Done."

    %-clean:
    	@

    %-install:
    	@
    ```


### 缓存处理 process_cache.sh

* `process_cache.sh -h` 查看命令帮助
* 作用原理
    * 对对包编译结果有影响的元素做校验当做缓存文件的名字的一部分
    * 影响包编译的元素有: 编译脚本、补丁、依赖包的输出、包的压缩包文件或本地源码文件
    * 注意绝不要把编译后输出的文件加入到校验


### 缓存模板 inc.cache.mk


### 缓存模板可能要设置的变量

* 下载编译的变量
    * FETCH_METHOD    : 下载包的方式，可选择 `tar zip git svn`，默认值为 tar
    * SRC_URLS        : 下载包的 URLs，包含 branch / revision / tag / md5 等信息，默认值根据下面设置的变量生成
        * SRC_URL     : 裸的 URL
        * SRC_BRANCH  : git 的 branch
        * SRC_TAG     : git 的 tag
        * SRC_REV     : git 或 svn 的 revision
        * SRC_MD5     : tar 或 zip 的 MD5
    * SRC_PATH        : 包的源码路径，默认取变量 `$(OUT_PATH)/$(SRC_DIR)` 设置的值
    * OBJ_PATH        : 包的编译输出路径，默认取变量 `$(OUT_PATH)/build` 设置的值
    * INS_PATH        : 包的安装根目录，默认取变量 `$(OUT_PATH)/image` 设置的值
    * INS_SUBDIR      : 包的安装子目录，默认值为 `/usr`，则真正的安装目录为 `$(INS_PATH)$(INS_SUBDIR)`
    * PC_FILES        : 包安装的 pkg-config 配置文件的文件名，多个文件空格分开
    * MAKES           : make 命令的值，默认值为 `make $(ENV_BUILD_JOBS) $(ENV_MAKE_FLAGS) $(MAKES_FLAGS)`，用户可以设置额外的参数 `MAKES_FLAGS`
        * meson 编译时默认值为 `ninja $(ENV_BUILD_JOBS) $(MAKES_FLAGS)`，用户可以设置额外的参数 `MAKES_FLAGS`
<br>

* 缓存处理的变量
    * CACHE_SRCFILE   : 网络下载保存的文件名或文件夹名，默认取变量 `$(SRC_NAME)` 设置的值
        * 指定了此变量会自动对下载的文件校验，本地代码不需要指定此变量
    * CACHE_OUTPATH   : 包的输出目录，会在此目录生成校验文件和 log 文件等，默认取变量 `$(OUT_PATH)` 设置的值
    * CACHE_INSPATH   : 包的安装目录，默认取变量 `$(INS_PATH)` 设置的值
    * CACHE_GRADE     : 缓存级别，默认取 2，决定了编译缓存文件的前缀
        * 缓存一般有4个级别, 分别是 `soc_name` `cpu_name` `arch_name` `cpu_family`
            * 例如: 我有一颗 cortex-a55 的 soc 名字叫做 v9，那么缓存级别数组为 `v9 cortex-a55 armv8-a aarch64`
    * CACHE_CHECKSUM  : 额外需要校验的文件或目录，多个项目使用空格分开，默认加上当前目录的 mk.deps 文件
        * 目录支持如下语法: `搜索的目录路径:搜索的字符串:忽略的文件夹名:忽略的字符串`，其中子项目可以使用竖线 `|` 隔开
            * 例如: `"srca|srcb:*.c|*.h|Makefile:test:*.o|*.d"`, `"src:*.c|*.h|*.cpp|*.hpp"`
    * CACHE_DEPENDS   : 手动指定包的依赖，默认值为空(即自动分析依赖)
        * 如果包没有依赖可以设置为 `none`
        * 如果不指定依赖会自动分析 `${ENV_CFG_ROOT}` 中的 DEPS 和 .config 文件获取依赖
    * CACHE_APPENDS   : 增加额外的校验字符串，例如动态变化的配置
    * CACHE_URL       : 指定网络下载的 URL，如果设置了 SRC_URLS，默认取变量 `[$(FETCH_METHOD)]$(SRC_URLS)` 设置的值
        * 格式需要是 `[download_method]urls`，例如 `[tar]urls` `[zip]urls` `[git]urls` `[svn]urls`
    * CACHE_VERBOSE   : 是否生成 log 文件，默认取 1， 生成 log 文件是 `$(CACHE_OUTPATH)/$(CACHE_PACKAGE)-cache.log`


#### 缓存模板提供的函数

* do_inspc / do_syspc: 将 pkg-config 配置文件中的路径转换为虚拟路径和实际路径，需要先设置配置文件名变量 PC_FILES
* do_fetch: 自动从网络拉取代码并解压到输出目录
* do_patch: 打补丁，用户需要设置补丁目录 `PATCH_FOLDER`
* do_compile: 用户如果没有设置此函数，将采用模板中的默认 do_compile 函数
    * 如果用户设置了 SRC_URL 变量，会自动加上拉取代码操作
    * 如果用户设置了 PATCH_FOLDER 变量，会自动加上打补丁操作
    * 如果用户设置了 do_prepend 函数，会在 make 命令前运行此函数
    * 如果用户设置了 COMPILE_TOOL 变量，提供如下编译方式的支持:
        * 如果 COMPILE_TOOL 值是 configure，会在 make 命令前运行 configure 命令，通过 `CONFIGURE_FLAGS` 变量提供额外的命令参数
            * CROSS_CONFIGURE: configure 配置交叉编译时的参数
        * 如果 COMPILE_TOOL 值是 cmake，会在编译命令 make 前运行 cmake 命令，通过 `CMAKE_FLAGS` 变量提供额外的命令参数
            * CROSS_CMAKE: cmake 配置交叉编译时的参数
        * 如果 COMPILE_TOOL 值是 meson，会在编译命令 ninja 前运行 meson 配置命令，通过 `MESON_FLAGS` 变量提供额外的命令参数
            * meson 使用 ini 文件配置交叉编译，用户可以定义 do_meson_cfg 函数追加或修改默认的配置
            * MESON_WRAP_MODE 默认值 `--wrap-mode=nodownload` 表示禁止 meson 下载依赖包编译
            * MESON_LIBDIR 默认值 `--libdir=$(INS_PATH)$(INS_SUBDIR)/lib`，表示设置安装库文件路径，不然本地编译时会安装到 lib 下的 x86_64-linux-gnu
    * 如果用户设置了 do_append 函数，会在 make 命令后运行此函数
* do_check: 检查是否匹配 cache，返回的字符串有 MATCH 表示匹配，ERROR 表示错误
* do_pull: 如果 INS_PATH 目录不存在，将 cache 解压的输出目录
* do_push: 将 cache 加入到全局缓存目录
* do_setforce: 设置强制编译，用户某些操作后需要重新编译的操作需要调用此函数，例如用户修改 config
* do_set1force: 设置强制编译一次，下次编译就是正常编译
* do_unsetforce: 取消强制编译，例如用户还原默认 config


#### 缓存模板提供的目标

* all / clean / install: 包的必要目标
    * 如果用户没有设置 `USER_DEFINED_TARGET` 为 y，采用模板默认提供的 `all clean install` 目标
    * 如果用户设置了 do_install_append 函数，会在 install 目标尾部运行此函数
* psysroot: 在 OUT_PATH 目录准备 sysroot
* srcbuild: 没有缓存机制的编译
* cachebuild: 有缓存机制的编译
* dofetch: 仅下载源码
* setforce: 设置强制编译
* set1force: 设置强制编译一次
* unsetforce: 取消强制编译

注: 我们从源码编译 OSS 包时，一般会在 DEPS 语句的其它目标加上 cache psysroot，表示使用缓存机制加快再次编译和在 OUT_PATH 准备 sysroot 防止 OSS 自动加上未声明的依赖包导致编译出错


### 编译 OSS 层

* OSS 层的包不断增加中，目前已有50多个包
* 编译缓存演示 demo [cache_demo](https://www.bilibili.com/video/BV15R4y1C7e6)
* 编译命令
    * `make time_statistics` 是一个一个包编译过去(包内可能是多线程编译)，获取每个包的编译时间
        * 每个 OSS 包有三行: 第1行是准备依赖的 sysroot，第2行是编译，第3行是安装到全局 sysroot
    * `make` 是不仅是包内可能是多线程编译，多个包也是同时编译，不统计编译时间
    * `make all_fetchs` 只下载所有选中的支持缓存的包的源码
        *
注: 第一次编译前最好选中支持缓存的包后下载所有的源码 `make all_fetchs`，防止源码无法一次下载成功导致其它问题
    * `make all_caches` 下载并编译所有选中的支持缓存的包的源码


* 编译交叉编译工具链，举例 cortex-a53

    ```sh
    lengjing@lengjing:~/data/cbuild$ source scripts/build.env cortex-a53
    ...
    lengjing@lengjing:~/data/cbuild$ make -C scripts/toolchain
    make: Entering directory '/home/lengjing/data/cbuild/scripts/toolchain'
    make[1]: Entering directory '/home/lengjing/data/cbuild/scripts/toolchain'
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz" gmp-6.2.1.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs gmp-6.2.1
    curl http://ftp.gnu.org/gnu/gmp/gmp-6.2.1.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/gmp-6.2.1.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/gmp-6.2.1.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://ftp.gnu.org/gnu/mpfr/mpfr-4.1.1.tar.xz" mpfr-4.1.1.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs mpfr-4.1.1
    curl http://ftp.gnu.org/gnu/mpfr/mpfr-4.1.1.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/mpfr-4.1.1.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/mpfr-4.1.1.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz" mpc-1.3.1.tar.gz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs mpc-1.3.1
    curl http://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/mpc-1.3.1.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/mpc-1.3.1.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    /home/lengjing/data/cbuild/scripts/bin/exec_patch.sh patch patch/mpc /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs/mpc-1.3.1
    patching file src/mpc.h
    Patch patch/mpc/0001-mpc-Fix-configuring-gcc-failed.patch to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs/mpc-1.3.1 Done.
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://libisl.sourceforge.io/isl-0.25.tar.xz" isl-0.25.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs isl-0.25
    curl http://libisl.sourceforge.io/isl-0.25.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/isl-0.25.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/isl-0.25.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.88.tar.xz" linux-5.15.88.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs linux-5.15.88
    curl http://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.88.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/linux-5.15.88.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/linux-5.15.88.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz" binutils-2.40.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs binutils-2.40
    curl http://ftp.gnu.org/gnu/binutils/binutils-2.40.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/binutils-2.40.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/binutils-2.40.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz" gcc-12.2.0.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs gcc-12.2.0
    curl http://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/gcc-12.2.0.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/gcc-12.2.0.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    sed -i 's@print-multi-os-directory@print-multi-directory@g' \
        `find /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs/gcc-12.2.0 -name configure -o -name configure.ac -o -name Makefile.in | xargs`
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://ftp.gnu.org/gnu/glibc/glibc-2.36.tar.xz" glibc-2.36.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs glibc-2.36
    curl http://ftp.gnu.org/gnu/glibc/glibc-2.36.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/glibc-2.36.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/glibc-2.36.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs
    /home/lengjing/data/cbuild/scripts/bin/fetch_package.sh tar "http://ftp.gnu.org/gnu/gdb/gdb-12.1.tar.xz" gdb-12.1.tar.xz /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs gdb-12.1
    curl http://ftp.gnu.org/gnu/gdb/gdb-12.1.tar.xz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/gdb-12.1.tar.xz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/gdb-12.1.tar.xz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs

     ./output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/bin/aarch64-linux-gnu-gcc -v
    Using built-in specs.
    COLLECT_GCC=./output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/bin/aarch64-linux-gnu-gcc
    COLLECT_LTO_WRAPPER=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/libexec/gcc/aarch64-linux-gnu/12.2.0/lto-wrapper
    Target: aarch64-linux-gnu
    Configured with: /home/lengjing/data/cbuild/output/cortex-a53/objects-native/scripts/toolchain/srcs/gcc-12.2.0/configure --target=aarch64-linux-gnu --prefix=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15 --with-gmp=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/host --with-mpfr=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/host --with-mpc=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/host --with-isl=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/host --with-sysroot=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/aarch64-linux-gnu/libc --with-build-sysroot=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/aarch64-linux-gnu/libc --with-toolexeclibdir=/home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/aarch64-linux-gnu/libc/lib --enable-languages=c,c++ --enable-shared --enable-threads=posix --enable-checking=release --with-arch=armv8-a --with-cpu=cortex-a53 --disable-bootstrap --disable-multilib --enable-multiarch --enable-nls --without-included-gettext --enable-clocale=gnu --enable-lto --enable-linker-build-id --enable-gnu-unique-object --enable-libstdcxx-debug --enable-libstdcxx-time=yes
    Thread model: posix
    Supported LTO compression algorithms: zlib zstd
    gcc version 12.2.0 (GCC)
    lengjing@lengjing:~/data/cbuild$ ls output/mirror-cache/build-cache/
    x86_64--cortex-a53-toolchain-gcc12.2.0-linux5.15-native--8ec20b3593ccaf0a87712ade12d00de6.tar.gz
    ```

* 清理下载后，统计各个包的编译时间，只选中如下几个具有代表性的包测试
    * busybox: 使用 menuconfig 配置参数
    * cjson: 使用 CMake 编译
    * libpcap: 使用 Autotools 编译
    * ljson: 自定义 Makefile 编译
    * lua: 对源码打了补丁
    * ncurses: 依赖自己 native 包的工具
    * tcpdump: 依赖 libpcap 包

    ```sh
    lengjing@lengjing:~/data/cbuild$ rm -rf output/cortex-a53 output/mirror-cache/downloads
    ...
    lengjing@lengjing:~/data/cbuild$ make test_config
    ...
    lengjing@lengjing:~/data/cbuild$ make time_statistics
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/Kconfig OK.
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/auto.mk OK.
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/DEPS OK.
    curl http://www.busybox.net/downloads/busybox-1.35.0.tar.bz2 to /home/lengjing/data/cbuild/output/mirror-cache/downloads/busybox-1.35.0.tar.bz2
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/busybox-1.35.0.tar.bz2 to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox
    /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox/busybox-1.35.0/applets/usage.c: In function 'main':
    /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox/busybox-1.35.0/applets/usage.c:52:3: warning: ignoring return value of 'write', declared with attribute warn_unused_result [-Wunused-result]
    ...
    Push busybox Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build busybox Done.
    Install busybox Done.
    curl http://github.com/DaveGamble/cJSON/archive/refs/tags/v1.7.15.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/cJSON-1.7.15.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/cJSON-1.7.15.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/cjson
    Push cjson Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build cjson Done.
    Install cjson Done.
    curl http://www.tcpdump.org/release/libpcap-1.10.1.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/libpcap-1.10.1.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/libpcap-1.10.1.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/libpcap
    Push libpcap Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build libpcap Done.
    Install libpcap Done.
    git clone https://github.com/lengjingzju/json.git to /home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson
    Cloning into '/home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson'...
    remote: Enumerating objects: 39, done.
    remote: Counting objects: 100% (2/2), done.
    remote: Compressing objects: 100% (2/2), done.
    remote: Total 39 (delta 1), reused 0 (delta 0), pack-reused 37
    Unpacking objects: 100% (39/39), done.
    copy /home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/ljson
    Push ljson Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ljson Done.
    Install ljson Done.
    curl http://www.lua.org/ftp/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/lua
    patching file Makefile
    patching file src/Makefile
    Patch /home/lengjing/data/cbuild/oss/lua/patch/0001-lua-Support-dynamic-library-compilation.patch to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/lua/lua-5.4.4 Done.
    patching file src/lparser.c
    Patch /home/lengjing/data/cbuild/oss/lua/patch/CVE-2022-28805.patch to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/lua/lua-5.4.4 Done.
    Push lua Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    Install lua Done.
    curl http://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.3.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/ncurses-6.3.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/ncurses-6.3.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects-native/oss/ncurses
    configure: WARNING: This option applies only to wide-character library
    ...
    Push ncurses-native Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ncurses-native Done.
    Install ncurses-native Done.
    Install ncurses-native Done.
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/ncurses-6.3.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/ncurses
    configure: WARNING: If you wanted to set the --build type, don't use --host.
    ...
    Push ncurses Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ncurses Done.
    Install ncurses Done.
    Install libpcap Done.
    curl http://www.tcpdump.org/release/tcpdump-4.99.1.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/tcpdump-4.99.1.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/tcpdump-4.99.1.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/tcpdump
    configure: WARNING: using cross tools not prefixed with host triplet
    configure: WARNING: pcap/pcap-inttypes.h: accepted by the compiler, rejected by the preprocessor!
    configure: WARNING: pcap/pcap-inttypes.h: proceeding with the compiler's result
    Push tcpdump Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build tcpdump Done.
    Install tcpdump Done.
    Build rootfs Done.
    Install packages from /home/lengjing/data/cbuild/output/cortex-a53/sysroot
    Install busybox Done.
    Install Glibc target from /home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/aarch64-linux-gnu/libc
    Build done!

    lengjing@lengjing:~/data/cbuild$ cat output/cortex-a53/config/time_statistics
    real		user		sys		package
    0.04		0.04		0.00		deps
    0.04		0.04		0.01		busybox
    23.77		77.62		16.90		busybox
    0.01		0.00		0.00		busybox
    0.06		0.05		0.01		cjson
    4.92		1.71		0.47		cjson
    0.00		0.00		0.00		cjson
    0.05		0.04		0.01		libpcap
    14.59		8.47		1.15		libpcap
    0.01		0.00		0.00		libpcap
    0.05		0.05		0.00		ljson
    4.23		1.16		0.09		ljson
    0.00		0.00		0.00		ljson
    0.06		0.05		0.00		lua
    7.93		6.59		0.41		lua
    0.00		0.00		0.00		lua
    0.06		0.05		0.01		ncurses-native
    30.24		65.82		12.07		ncurses-native
    0.08		0.01		0.06		ncurses-native
    0.08		0.00		0.07		ncurses-native_install
    0.17		0.08		0.09		ncurses
    31.85		107.68		18.63		ncurses
    0.08		0.01		0.06		ncurses
    0.01		0.00		0.00		libpcap_install
    0.07		0.06		0.01		tcpdump
    13.14		10.84		3.02		tcpdump
    0.01		0.00		0.00		tcpdump
    0.00		0.00		0.00		rootfs
    1.17		0.53		0.44		rootfs
    132.74		281.01		53.54		total_time
    ```

* 再次编译，直接从本地缓存取了，没有重新从代码编译

    ```sh
    lengjing@lengjing:~/data/cbuild$ make -C scripts/toolchain
    make: Entering directory '/home/lengjing/data/cbuild/scripts/toolchain'
    Use cortex-a53-toolchain-gcc12.2.0-linux5.15 Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build cortex-a53-toolchain-gcc12.2.0-linux5.15 Done.
    make: Leaving directory '/home/lengjing/data/cbuild/scripts/toolchain'
    lengjing@lengjing:~/data/cbuild$ make time_statistics
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/Kconfig OK.
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/auto.mk OK.
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/DEPS OK.
    Use busybox Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build busybox Done.
    Install busybox Done.
    Use cjson Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build cjson Done.
    Install cjson Done.
    Use libpcap Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build libpcap Done.
    Install libpcap Done.
    Use ljson Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ljson Done.
    Install ljson Done.
    Use lua Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    Install lua Done.
    Use ncurses-native Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ncurses-native Done.
    Install ncurses-native Done.
    Use ncurses Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ncurses Done.
    Install ncurses Done.
    Use tcpdump Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build tcpdump Done.
    Install tcpdump Done.
    Build rootfs Done.
    Install packages from /home/lengjing/data/cbuild/output/cortex-a53/sysroot
    Install busybox Done.
    Install Glibc target from /home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/aarch64-linux-gnu/libc
    Build done!
    lengjing@lengjing:~/data/cbuild$
    lengjing@lengjing:~/data/cbuild$ cat output/cortex-a53/config/time_statistics
    real		user		sys		package
    0.04		0.03		0.00		deps
    0.04		0.04		0.00		busybox
    0.09		0.08		0.02		busybox
    0.01		0.00		0.00		busybox
    0.05		0.05		0.00		cjson
    0.08		0.07		0.01		cjson
    0.00		0.00		0.00		cjson
    0.04		0.04		0.01		libpcap
    0.08		0.07		0.01		libpcap
    0.03		0.00		0.01		libpcap
    0.04		0.04		0.00		ljson
    0.08		0.07		0.01		ljson
    0.00		0.00		0.00		ljson
    0.05		0.05		0.00		lua
    0.08		0.08		0.01		lua
    0.00		0.00		0.00		lua
    0.05		0.04		0.01		ncurses-native
    0.08		0.08		0.01		ncurses-native
    0.28		0.01		0.19		ncurses-native
    0.06		0.05		0.01		ncurses
    0.09		0.09		0.01		ncurses
    0.25		0.01		0.18		ncurses
    0.05		0.04		0.01		tcpdump
    0.09		0.08		0.01		tcpdump
    0.00		0.00		0.00		tcpdump
    0.03		0.00		0.02		rootfs
    1.14		0.53		0.44		rootfs
    2.96		1.66		1.09		total_time
    ```

* 另启一个终端，启动镜像服务器

    ```sh
    lengjing@lengjing:~/data/cbuild$ cd output
    lengjing@lengjing:~/data/cbuild/output$ mv mirror-cache mirror
    lengjing@lengjing:~/data/cbuild/output$ cd mirror
    lengjing@lengjing:~/data/cbuild/output/mirror$ rm -rf downloads/lock
    lengjing@lengjing:~/data/cbuild/output/mirror$ tree
    .
    ├── build-cache
    │   ├── cortex-a53--busybox--b7c40d7a733221bbd8327e487cfee505.tar.gz
    │   ├── cortex-a53--cjson--8167d8f3fd82197b44bb7498b4d97bb0.tar.gz
    │   ├── cortex-a53--libpcap--5db3b7c187d08870a29ee48f725e96bc.tar.gz
    │   ├── cortex-a53--ljson--1cb819ebcb847f1feff24879246c30d5.tar.gz
    │   ├── cortex-a53--lua--370ffcee1a70bc93516df21de9de0634.tar.gz
    │   ├── cortex-a53--ncurses--96424c436be9e0bc02bcdaea10083a8f.tar.gz
    │   ├── cortex-a53--tcpdump--5652e8bf037a2ee5792fcbf02adee2b7.tar.gz
    │   ├── x86_64--cortex-a53-toolchain-gcc12.2.0-linux5.15-native--8ec20b3593ccaf0a87712ade12d00de6.tar.gz
    │   └── x86_64--ncurses-native--54a6ab0af25ad68f24bff08355b59efb.tar.gz
    └── downloads
        ├── busybox-1.35.0.tar.bz2
        ├── busybox-1.35.0.tar.bz2.src.hash
        ├── cJSON-1.7.15.tar.gz
        ├── cJSON-1.7.15.tar.gz.src.hash
        ├── libpcap-1.10.1.tar.gz
        ├── libpcap-1.10.1.tar.gz.src.hash
        ├── ljson
        │   ├── json.c
        │   ├── json.h
        │   ├── json_test.c
        │   ├── json_test.png
        │   ├── LICENSE
        │   └── README.md
        ├── ljson-git-br.-rev.7b2f6ae6cf7011e94682b073669f5ff8f69095cc.tar.gz
        ├── ljson.src.hash
        ├── lua-5.4.4.tar.gz
        ├── lua-5.4.4.tar.gz.src.hash
        ├── ncurses-6.3.tar.gz
        ├── ncurses-6.3.tar.gz.src.hash
        ├── tcpdump-4.99.1.tar.gz
        └── tcpdump-4.99.1.tar.gz.src.hash

    3 directories, 29 files
    lengjing@lengjing:~/data/cbuild/output/mirror$ python3 -m http.server 8888
    Serving HTTP on 0.0.0.0 port 8888 (http://0.0.0.0:8888/) ...
    ```

* 原终端删除所有编译输出和缓存，开始全新编译，直接从网络缓存取了，没有重新从代码编译

    ```sh
    lengjing@lengjing:~/data/cbuild$ rm -rf output/cortex-a53 output/mirror-cache output/toolchain
    lengjing@lengjing:~/data/cbuild$ make test_config
    ...
    lengjing@lengjing:~/data/cbuild$ make -C scripts/toolchain
    make: Entering directory '/home/lengjing/data/cbuild/scripts/toolchain'
    curl http://127.0.0.1:8888/build-cache/x86_64--cortex-a53-toolchain-gcc12.2.0-linux5.15-native--8ec20b3593ccaf0a87712ade12d00de6.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/x86_64--cortex-a53-toolchain-gcc12.2.0-linux5.15-native--8ec20b3593ccaf0a87712ade12d00de6.tar.gz
    Use cortex-a53-toolchain-gcc12.2.0-linux5.15 Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build cortex-a53-toolchain-gcc12.2.0-linux5.15 Done.
    make: Leaving directory '/home/lengjing/data/cbuild/scripts/toolchain'
    lengjing@lengjing:~/data/cbuild$ make time_statistics
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/Kconfig OK.
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/auto.mk OK.
    Generate /home/lengjing/data/cbuild/output/cortex-a53/config/DEPS OK.
    curl http://127.0.0.1:8888/build-cache/cortex-a53--busybox--b7c40d7a733221bbd8327e487cfee505.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--busybox--b7c40d7a733221bbd8327e487cfee505.tar.gz
    Use busybox Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build busybox Done.
    Install busybox Done.
    curl http://127.0.0.1:8888/build-cache/cortex-a53--cjson--8167d8f3fd82197b44bb7498b4d97bb0.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--cjson--8167d8f3fd82197b44bb7498b4d97bb0.tar.gz
    Use cjson Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build cjson Done.
    Install cjson Done.
    curl http://127.0.0.1:8888/build-cache/cortex-a53--libpcap--5db3b7c187d08870a29ee48f725e96bc.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--libpcap--5db3b7c187d08870a29ee48f725e96bc.tar.gz
    Use libpcap Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build libpcap Done.
    Install libpcap Done.
    curl http://127.0.0.1:8888/build-cache/cortex-a53--ljson--1cb819ebcb847f1feff24879246c30d5.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--ljson--1cb819ebcb847f1feff24879246c30d5.tar.gz
    Use ljson Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ljson Done.
    Install ljson Done.
    curl http://127.0.0.1:8888/build-cache/cortex-a53--lua--370ffcee1a70bc93516df21de9de0634.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--lua--370ffcee1a70bc93516df21de9de0634.tar.gz
    Use lua Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    Install lua Done.
    curl http://127.0.0.1:8888/build-cache/x86_64--ncurses-native--54a6ab0af25ad68f24bff08355b59efb.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/x86_64--ncurses-native--54a6ab0af25ad68f24bff08355b59efb.tar.gz
    Use ncurses-native Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ncurses-native Done.
    Install ncurses-native Done.
    curl http://127.0.0.1:8888/build-cache/cortex-a53--ncurses--96424c436be9e0bc02bcdaea10083a8f.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--ncurses--96424c436be9e0bc02bcdaea10083a8f.tar.gz
    Use ncurses Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ncurses Done.
    Install ncurses Done.
    curl http://127.0.0.1:8888/build-cache/tcpdump--5652e8bf037a2ee5792fcbf02adee2b7.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/tcpdump--5652e8bf037a2ee5792fcbf02adee2b7.tar.gz
    Use tcpdump Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build tcpdump Done.
    Install tcpdump Done.
    Build rootfs Done.
    Install packages from /home/lengjing/data/cbuild/output/cortex-a53/sysroot
    Install busybox Done.
    Install Glibc target from /home/lengjing/data/cbuild/output/toolchain/cortex-a53-toolchain-gcc12.2.0-linux5.15/aarch64-linux-gnu/libc
    Build done!

    lengjing@lengjing:~/data/cbuild$ cat output/cortex-a53/config/time_statistics
    real		user		sys		package
    0.04		0.03		0.00		deps
    0.06		0.05		0.01		busybox
    0.12		0.10		0.02		busybox
    0.01		0.00		0.00		busybox
    0.07		0.06		0.00		cjson
    0.08		0.07		0.02		cjson
    0.00		0.00		0.00		cjson
    0.07		0.06		0.01		libpcap
    0.12		0.09		0.03		libpcap
    0.01		0.00		0.00		libpcap
    0.06		0.05		0.01		ljson
    0.11		0.09		0.04		ljson
    0.00		0.00		0.00		ljson
    0.07		0.06		0.00		lua
    0.10		0.10		0.01		lua
    0.01		0.01		0.00		lua
    0.08		0.05		0.03		ncurses-native
    0.21		0.15		0.10		ncurses-native
    0.08		0.01		0.07		ncurses-native
    0.09		0.08		0.01		ncurses
    0.21		0.17		0.07		ncurses
    0.09		0.01		0.07		ncurses
    0.08		0.06		0.02		tcpdump
    0.11		0.11		0.01		tcpdump
    0.00		0.00		0.00		tcpdump
    0.00		0.00		0.00		rootfs
    1.00		0.54		0.45		rootfs
    3.00		2.07		1.10		total_time
    ```

* 设置强制编译，总是从代码编译

    ```sh
    lengjing@lengjing:~/data/cbuild$ make lua_setforce
    Set lua Force Build.
    lengjing@lengjing:~/data/cbuild$ make lua
    WARNING: Force Build lua.
    curl http://127.0.0.1:8888/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/lua
    patching file Makefile
    patching file src/Makefile
    Patch /home/lengjing/data/cbuild/oss/lua/patch/0001-lua-Support-dynamic-library-compilation.patch to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/lua/lua-5.4.4 Done.
    patching file src/lparser.c
    Patch /home/lengjing/data/cbuild/oss/lua/patch/CVE-2022-28805.patch to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/lua/lua-5.4.4 Done.
    Push lua Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    Install lua Done.
    lengjing@lengjing:~/data/cbuild$ make lua
    WARNING: Force Build lua.
    Push lua Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    Install lua Done.
    ```

* 取消强制编译，再次编译直接从缓存取了，没有重新从代码编译(没有网络缓存时需要重新从代码编译一次)

    ```sh
    lengjing@lengjing:~/data/cbuild$ make lua_unsetforce
    Unset lua Force Build.
    lengjing@lengjing:~/data/cbuild$ make lua
    curl http://127.0.0.1:8888/build-cache/cortex-a53--lua--370ffcee1a70bc93516df21de9de0634.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--lua--370ffcee1a70bc93516df21de9de0634.tar.gz
    Use lua Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    Install lua Done.
    lengjing@lengjing:~/data/cbuild$ make lua
    Use lua Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    Install lua Done.
    ```

* 修改加入到校验的文件，从代码编译了一次

    ```sh
    lengjing@lengjing:~/data/cbuild$ echo >> oss/ljson/patch/Makefile
    lengjing@lengjing:~/data/cbuild$ make ljson
    curl http://127.0.0.1:8888/downloads/ljson-git-br.-rev.7b2f6ae6cf7011e94682b073669f5ff8f69095cc.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson-git-br.-rev.7b2f6ae6cf7011e94682b073669f5ff8f69095cc.tar.gz
    copy /home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/ljson
    Push ljson Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ljson Done.
    Install ljson Done.
    lengjing@lengjing:~/data/cbuild$ make ljson
    Use ljson Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build ljson Done.
    Install ljson Done.
    ```

* 修改代码的 config，设置了强制编译，总是从代码编译

    ```sh
    lengjing@lengjing:~/data/cbuild$ make busybox_menuconfig
    curl http://127.0.0.1:8888/downloads/busybox-1.35.0.tar.bz2 to /home/lengjing/data/cbuild/output/mirror-cache/downloads/busybox-1.35.0.tar.bz2
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/busybox-1.35.0.tar.bz2 to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox
      GEN     /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox/build/Makefile
    #
    # using defaults found in .config
    #

    *** End of configuration.
    *** Execute 'make' to build the project or try 'make help'.

    Set busybox Force Build.
    lengjing@lengjing:~/data/cbuild$ make busybox
    WARNING: Force Build busybox.
    /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox/busybox-1.35.0/applets/usage.c: In function 'main':
    /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox/busybox-1.35.0/applets/usage.c:52:3: warning: ignoring return value of 'write', declared with attribute warn_unused_result [-Wunused-result]
    ...
    Push busybox Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build busybox Done.
    Install busybox Done.
    lengjing@lengjing:~/data/cbuild$ make busybox
    WARNING: Force Build busybox.
    Push busybox Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build busybox Done.
    Install busybox Done.
    ```

* 还原代码的默认 config，取消设置了强制编译，直接从缓存取了，没有重新从代码编译

    ```sh
    lengjing@lengjing:~/data/cbuild$ make busybox_defconfig
      GEN     /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/busybox/build/Makefile
    *
    * Busybox Configuration
    *
    *
    * Settings
    *
    ...
    Unset busybox Force Build.
    lengjing@lengjing:~/data/cbuild$ make busybox
    curl http://127.0.0.1:8888/build-cache/cortex-a53--busybox--b7c40d7a733221bbd8327e487cfee505.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/build-cache/cortex-a53--busybox--b7c40d7a733221bbd8327e487cfee505.tar.gz
    Use busybox Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build busybox Done.
    Install busybox Done.
    lengjing@lengjing:~/data/cbuild$ make busybox
    Use busybox Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build busybox Done.
    Install busybox Done.
    ```

* 修改依赖包的加入到校验的文件，依赖包和依赖它的包都重新编译了

    ```sh
    lengjing@lengjing:~/data/cbuild$ echo >> oss/libpcap/mk.deps
    lengjing@lengjing:~/data/cbuild$ make tcpdump
    curl http://127.0.0.1:8888/downloads/libpcap-1.10.1.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/libpcap-1.10.1.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/libpcap-1.10.1.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/libpcap
    Push libpcap Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build libpcap Done.
    Install libpcap Done.
    Install libpcap Done.
    curl http://127.0.0.1:8888/downloads/tcpdump-4.99.1.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/tcpdump-4.99.1.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/tcpdump-4.99.1.tar.gz to /home/lengjing/data/cbuild/output/cortex-a53/objects/oss/tcpdump
    configure: WARNING: using cross tools not prefixed with host triplet
    configure: WARNING: pcap/pcap-inttypes.h: accepted by the compiler, rejected by the preprocessor!
    configure: WARNING: pcap/pcap-inttypes.h: proceeding with the compiler's result
    Push tcpdump Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build tcpdump Done.
    Install tcpdump Done.
    ```

