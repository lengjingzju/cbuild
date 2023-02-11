# CBuild 编译系统测试举例

[English Edition](./examples.md)

## 初始化环境

* `export LOGOUTPUT=` 的作用是输出更详细的编译信息

```sh
lengjing@lengjing:~/data/cbuild$ source scripts/build.env
============================================================
ENV_BUILD_MODE   : external
ENV_BUILD_JOBS   : -j8
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
lengjing@lengjing:~/data/cbuild$ export LOGOUTPUT=
```


## 测试编译应用

* 测试用例1位于 `test-app`，测试生成动态库、静态库和可执行文件

    ```sh
    lengjing@lengjing:~/data/cbuild$ cd examples/test-app
    lengjing@lengjing:~/data/cbuild/examples/test-app$ make
    gcc	sub.c
    gcc	main.c
    gcc	add.c
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app/libtest.a
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app/libtest.so.1.2.3
    bin:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app/test
    Build test-app Done.
    ```

* 测试修改头文件，依赖它的 c 文件也重新编译了

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-app$ vi include/sub.h
    lengjing@lengjing:~/data/cbuild/examples/test-app$ make
    gcc	sub.c
    gcc	main.c
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app/libtest.a
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app/libtest.so.1.2.3
    bin:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app/test
    Build test-app Done.
    lengjing@lengjing:~/data/cbuild/examples/test-app$ make install
    ```

* 测试用例2位于 `test-app2`，测试依赖 (`test-app2` 依赖 `test-app`)

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-app$ cd ../test-app2
    lengjing@lengjing:~/data/cbuild/examples/test-app2$ make
    gcc	main.c
    bin:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app2/test2
    Build test-app2 Done.
    lengjing@lengjing:~/data/cbuild/examples/test-app2$ make install
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ readelf -d /home/lengjing/data/cbuild/output/noarch/objects/examples/test-app2/test2 | grep NEEDED
     0x0000000000000001 (NEEDED)             Shared library: [libtest.so.1]
     0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
    ```

* 测试用例3位于 `test-app3`，测试一个 Makefile 生成多个库

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-app2$
    lengjing@lengjing:~/data/cbuild/examples/test-app2$ cd ../test-app3
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ make
    gcc	add.c
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libadd.a
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libadd.so.1.2.3
    gcc	sub.c
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libsub.a
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libsub.so.1.2
    gcc	mul.c
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libmul.a
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libmul.so.1
    gcc	div.c
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libdiv.a
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libdiv.so
    lib:	/home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libadd2.so.1.2.3
    Build test-app3 Done.
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ make install
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ readelf -d /home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libadd.so.1.2.3 | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libadd.so.1]
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ readelf -d /home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libsub.so.1.2 | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libsub.so.1]
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ readelf -d /home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libmul.so.1 | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libmul.so.1]
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ readelf -d /home/lengjing/data/cbuild/output/noarch/objects/examples/test-app3/libdiv.so | grep SONAME
     0x000000000000000e (SONAME)             Library soname: [libdiv.so]
    ```


## 测试 Kconfig 配置

* 测试用例位于 `test-conf`

* 测试加载默认配置

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ cd ../test-conf
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ ls config/
    def_config
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ make def_config
    bison	/home/lengjing/data/cbuild/output/noarch/objects-native/scripts/kconfig/autogen/parser.tab.c
    gcc	/home/lengjing/data/cbuild/output/noarch/objects-native/scripts/kconfig/autogen/parser.tab.c
    flex	/home/lengjing/data/cbuild/output/noarch/objects-native/scripts/kconfig/autogen/lexer.lex.c
    gcc	/home/lengjing/data/cbuild/output/noarch/objects-native/scripts/kconfig/autogen/lexer.lex.c
    gcc	parser/confdata.c
    gcc	parser/menu.c
    gcc	parser/util.c
    gcc	parser/preprocess.c
    gcc	parser/expr.c
    gcc	parser/symbol.c
    gcc	conf.c
    gcc	/home/lengjing/data/cbuild/output/noarch/objects-native/scripts/kconfig/conf
    gcc	lxdialog/checklist.c
    gcc	lxdialog/inputbox.c
    gcc	lxdialog/util.c
    gcc	lxdialog/textbox.c
    gcc	lxdialog/yesno.c
    gcc	lxdialog/menubox.c
    gcc	mconf.c
    gcc	/home/lengjing/data/cbuild/output/noarch/objects-native/scripts/kconfig/mconf
    #
    # configuration written to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-conf/.config
    #
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ ls -a ${ENV_OUT_ROOT}/examples/test-conf
    .  ..  .config  .config.old  autoconfig  config.h
    ```

* 测试修改配置后保存到另一配置

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ make menuconfig
    configuration written to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-conf/.config

    *** End of the configuration.
    *** Execute 'make' to start the build or try 'make help'.

    lengjing@lengjing:~/data/cbuild/examples/test-conf$ make def2_saveconfig
    Save .config to config/def2_config
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ ls config/
    def2_config  def_config
    ```


## 测试编译驱动

* 测试用例1位于 `test-mod`，其中 test_hello 依赖于 test_hello_add 和 test_hello_sub，test_hello_sub 采用 Makefile 和 Kbuild 分离的模式

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ cd ../test-mod
    lengjing@lengjing:~/data/cbuild/examples/test-mod$ make deps
    Generate Kconfig OK.
    Generate auto.mk OK.
    lengjing@lengjing:~/data/cbuild/examples/test-mod$ ls test-hello
    Makefile  hello_div.c  hello_main.c  hello_main.h  hello_mul.c  mk.deps
    lengjing@lengjing:~/data/cbuild/examples/test-mod$ ls test-hello-sub
    Kbuild  Makefile  hello_sub.c  hello_sub.h  mk.deps
    lengjing@lengjing:~/data/cbuild/examples/test-mod$ make deps
    Generate Kconfig OK.
    Generate auto.mk OK.
    lengjing@lengjing:~/data/cbuild/examples/test-mod$ make menuconfig
    configuration written to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-mod/.config

    *** End of the configuration.
    *** Execute 'make' to start the build or try 'make help'.

    lengjing@lengjing:~/data/cbuild/examples/test-mod$ make all
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild/examples/test-mod/test-hello-add PWD=/home/lengjing/data/cbuild/examples/test-mod
    KERNELRELEASE=5.4.0-137-generic pwd=/usr/src/linux-headers-5.4.0-137-generic PWD=/home/lengjing/data/cbuild/examples/test-mod
    KERNELRELEASE=5.4.0-137-generic pwd=/usr/src/linux-headers-5.4.0-137-generic PWD=/home/lengjing/data/cbuild/examples/test-mod
    Build test-hello-add Done.
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild/examples/test-mod/test-hello-add PWD=/home/lengjing/data/cbuild/examples/test-mod
    At main.c:160:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    Build test-hello-sub Done.
    At main.c:160:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild/examples/test-mod/test-hello PWD=/home/lengjing/data/cbuild/examples/test-mod
    KERNELRELEASE=5.4.0-137-generic pwd=/usr/src/linux-headers-5.4.0-137-generic PWD=/home/lengjing/data/cbuild/examples/test-mod/test-hello
    KERNELRELEASE=5.4.0-137-generic pwd=/usr/src/linux-headers-5.4.0-137-generic PWD=/home/lengjing/data/cbuild/examples/test-mod/test-hello
    Build test-hello Done.
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild/examples/test-mod/test-hello PWD=/home/lengjing/data/cbuild/examples/test-mod
    At main.c:160:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.

    lengjing@lengjing:~/data/cbuild/examples/test-mod2$ ls ../../output/noarch/
    objects/        objects-native/ sysroot/        sysroot-native/
    lengjing@lengjing:~/data/cbuild/examples/test-mod2$ ls ../../output/noarch/sysroot/lib/modules/5.4.0-137-generic/extra/
    hello_add.ko  hello_dep.ko  hello_sub.ko
    lengjing@lengjing:~/data/cbuild/examples/test-mod2$ ls ../../output/noarch/sysroot/usr/include/test-hello-*
    ../../output/noarch/sysroot/usr/include/test-hello-add:
    Module.symvers  hello_add.h

    ../../output/noarch/sysroot/usr/include/test-hello-sub:
    Module.symvers  hello_sub.h
    ```

* 测试用例2位于 `test-mod2`，一个 Makefile 同时编译出两个模块 hello_op 和 hello_sec

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-mod$ cd ../test-mod2
    lengjing@lengjing:~/data/cbuild/examples/test-mod2$ make
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild/examples/test-mod2 PWD=/home/lengjing/data/cbuild/examples/test-mod2
    KERNELRELEASE=5.4.0-137-generic pwd=/usr/src/linux-headers-5.4.0-137-generic PWD=/home/lengjing/data/cbuild/examples/test-mod2
    KERNELRELEASE=5.4.0-137-generic pwd=/usr/src/linux-headers-5.4.0-137-generic PWD=/home/lengjing/data/cbuild/examples/test-mod2
    Build test-mod2 Done.

    lengjing@lengjing:~/data/cbuild/examples/test-mod2$ make install
    KERNELRELEASE= pwd=/home/lengjing/data/cbuild/examples/test-mod2 PWD=/home/lengjing/data/cbuild/examples/test-mod2
    At main.c:160:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    At main.c:160:
    - SSL error:02001002:system library:fopen:No such file or directory: ../crypto/bio/bss_file.c:72
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    - SSL error:2006D080:BIO routines:BIO_new_file:no such file: ../crypto/bio/bss_file.c:79
    sign-file: certs/signing_key.pem: No such file or directory
    Warning: modules_install: missing 'System.map' file. Skipping depmod.

    lengjing@lengjing:~/data/cbuild/examples/test-mod2$ ls ../../output/noarch/sysroot/lib/modules/5.4.0-137-generic/extra/
    hello_add.ko  hello_dep.ko  hello_op.ko  hello_sec.ko  hello_sub.ko
    lengjing@lengjing:~/data/cbuild/examples/test-mod2$
    ```


## 测试编译链

* 测试用例位于 `test-deps`

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-deps$ cd ../test-deps
    lengjing@lengjing:~/data/cbuild/examples/test-deps$ make deps
    Generate Kconfig OK.
    Generate auto.mk OK.
    Generate DEPS OK.
    lengjing@lengjing:~/data/cbuild/examples/test-deps$ make menuconfig
    configuration written to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-deps/.config

    *** End of the configuration.
    *** Execute 'make' to start the build or try 'make help'.

    lengjing@lengjing:~/data/cbuild/examples/test-deps$ make d
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pe/pe
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pe/pe
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pd/pd
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pd/pd

    lengjing@lengjing:~/data/cbuild/examples/test-deps$ make
    ext.mk
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pc/pc
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pe/pe
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pe/pe
    ext.mk
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pd/pd
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pd/pd
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pc/pc
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pb/pb
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pb/pb
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pa/pa
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pa/pa
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pf/pf
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pf/pf
    target=all path=/home/lengjing/data/cbuild/examples/test-deps/pf/pf
    target=install path=/home/lengjing/data/cbuild/examples/test-deps/pf/pf

    lengjing@lengjing:~/data/cbuild/examples/test-deps$ make a-deps
    Note: a.dot a.svg and a.png are generated in the depends folder.

    lengjing@lengjing:~/data/cbuild/examples/test-deps$ make clean
    ext.mk
    target=clean path=/home/lengjing/data/cbuild/examples/test-deps/pc/pc
    target=clean path=/home/lengjing/data/cbuild/examples/test-deps/pe/pe
    target=clean path=/home/lengjing/data/cbuild/examples/test-deps/pd/pd
    target=clean path=/home/lengjing/data/cbuild/examples/test-deps/pb/pb
    target=clean path=/home/lengjing/data/cbuild/examples/test-deps/pa/pa
    target=clean path=/home/lengjing/data/cbuild/examples/test-deps/pf/pf
    target=clean path=/home/lengjing/data/cbuild/examples/test-deps/pf/pf
    rm -rf auto.mk Kconfig Target DEPS depends
    ```


## 测试缓存编译

* 测试用例位于 `test-lua`，测试网络下载包、打补丁、编译、缓存处理

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-deps$ cd ../test-lua
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ make
    curl http://127.0.0.1:8888/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-lua
    patching file Makefile
    patching file src/Makefile
    Patch /home/lengjing/data/cbuild/examples/test-lua/patch/0001-lua-Support-dynamic-library-compilation.patch to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-lua/lua-5.4.4 Done.
    patching file src/lparser.c
    Patch /home/lengjing/data/cbuild/examples/test-lua/patch/CVE-2022-28805.patch to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-lua/lua-5.4.4 Done.
    Guessing Linux
    ar: `u' modifier ignored since `D' is the default (see `U')
    Push lua Cache to /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.

    lengjing@lengjing:~/data/cbuild/examples/test-lua$ make
    Use lua Cache in /home/lengjing/data/cbuild/output/mirror-cache/build-cache.
    Build lua Done.
    ```

## 测试下载包

* 另启一个终端，启动镜像服务器

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ cd ../../output
    lengjing@lengjing:~/data/cbuild/output$ mv mirror-cache mirror
    lengjing@lengjing:~/data/cbuild/output$ cd mirror
    lengjing@lengjing:~/data/cbuild/output/mirror$ python3 -m http.server 8888
    Serving HTTP on 0.0.0.0 port 8888 (http://0.0.0.0:8888/) ...
    ```

* 原终端导出如下变量

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ export FETCH_SCRIPT=${ENV_TOOL_DIR}/fetch_package.sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ export COPY_TO_PATH=${ENV_OUT_ROOT}/test
    ```

* 测试 tar 类型的包

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ ${FETCH_SCRIPT} tar http://www.lua.org/ftp/lua-5.4.3.tar.gz lua-5.4.3.tar.gz ${COPY_TO_PATH} lua-5.4.3
    curl http://www.lua.org/ftp/lua-5.4.3.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.3.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.3.tar.gz to /home/lengjing/data/cbuild/output/noarch/objects/test
    ```

* 测试 tar 类型的包从镜像 http://127.0.0.1:8888 下载

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ ${FETCH_SCRIPT} tar http://www.lua.org/ftp/lua-5.4.4.tar.gz lua-5.4.4.tar.gz ${COPY_TO_PATH} lua-5.4.4
    curl http://127.0.0.1:8888/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/noarch/objects/test
    ```

* 测试 zip 类型的包

    ```sh
    ${FETCH_SCRIPT} zip https://github.com/curl/curl/releases/download/curl-7_86_0/curl-7.86.0.zip curl-7.86.0.zip ${COPY_TO_PATH} curl-7.86.0
    curl https://github.com/curl/curl/releases/download/curl-7_86_0/curl-7.86.0.zip to /home/lengjing/data/cbuild/output/mirror-cache/downloads/curl-7.86.0.zip
    unzip /home/lengjing/data/cbuild/output/mirror-cache/downloads/curl-7.86.0.zip to /home/lengjing/data/cbuild/output/noarch/objects/test
    ```

* 测试 git 类型的包

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ ${FETCH_SCRIPT} git https://github.com/lengjingzju/json.git ljson ${COPY_TO_PATH} ljson
    git clone https://github.com/lengjingzju/json.git to /home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson
    Cloning into '/home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson'...
    remote: Enumerating objects: 39, done.
    remote: Counting objects: 100% (2/2), done.
    remote: Compressing objects: 100% (2/2), done.
    remote: Total 39 (delta 1), reused 0 (delta 0), pack-reused 37
    Unpacking objects: 100% (39/39), done.
    copy /home/lengjing/data/cbuild/output/mirror-cache/downloads/ljson to /home/lengjing/data/cbuild/output/noarch/objects/test
    ```

* 测试 svn 类型的包

```sh
lengjing@lengjing:~/data/cbuild/examples/test-lua$ ${FETCH_SCRIPT} svn https://github.com/lengjingzju/mem mem ${COPY_TO_PATH} mem
svn checkout https://github.com/lengjingzju/mem to /home/lengjing/data/cbuild/output/mirror-cache/downloads/mem
copy /home/lengjing/data/cbuild/output/mirror-cache/downloads/mem to /home/lengjing/data/cbuild/output/noarch/objects/test
```


## Yocto 快速开始

* 安装编译环境

    ```sh
    lengjing@lengjing:~/data/cbuild/scripts$ sudo apt install gawk wget git diffstat unzip \
        texinfo gcc build-essential chrpath socat cpio \
        python3 python3-pip python3-pexpect xz-utils \
        debianutils iputils-ping python3-git python3-jinja2 \
        libegl1-mesa libsdl1.2-dev pylint3 xterm \
        python3-subunit mesa-common-dev zstd liblz4-tool qemu
    ```

* 拉取 Poky 工程，通过 [Yocto Releases Wiki](https://wiki.yoctoproject.org/wiki/Releases) 界面获取版本代号

    ```sh
    lengjing@lengjing:~/data/cbuild/scripts$ git clone git://git.yoctoproject.org/poky
    lengjing@lengjing:~/data/cbuild/scripts$ cd poky
    lengjing@lengjing:~/data/cbuild/scripts/poky$ git branch -a
    lengjing@lengjing:~/data/cbuild/scripts/poky$ git checkout -t origin/kirkstone -b my-kirkstone
    lengjing@lengjing:~/data/cbuild/scripts/poky$ cd ../../
    ```

* 构建镜像

    ```shell
    lengjing@lengjing:~/data/cbuild$ source scripts/poky/oe-init-build-env       # 初始化环境
    lengjing@lengjing:~/data/cbuild/build$ bitbake core-image-minimal            # 构建最小镜像
    lengjing@lengjing:~/data/cbuild/build$ ls -al tmp/deploy/images/qemux86-64/  # 输出目录
    lengjing@lengjing:~/data/cbuild/build$ runqemu qemux86-64                    # 运行仿真器
    ```

注: `source oe-init-build-env <dirname>`功能: 初始化环境，并将工具目录(`bitbake/bin/` 和 `scripts/`)加入到环境变量; 在当前目录自动创建并切换到工作目录(不指定时默认为 build)


## 测试 Yocto 编译

* `conf/local.conf` 配置文件中增加如下变量定义

    ```
    ENV_TOP_DIR = "/home/lengjing/data/cbuild"
    ENV_BUILD_MODE = "yocto"
    ```

* 增加测试的层

    ```sh
    lengjing@lengjing:~/data/cbuild/build$ bitbake-layers add-layer ../examples/meta-cbuild
    ```

* bitbake 编译

    ```sh
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-app2  # 编译应用
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-app3  # 编译应用
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-hello # 编译内核模块
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-mod2  # 编译内核模块
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-conf  # 编译 kconfig 测试程序
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-conf -c menuconfig # 修改配置
    ```

注: 常见 Yocto 问题可以查看 [Yocto 笔记](../notes/yoctoqa.md)

