# CBuild Test Cases

[中文版](./examples_zh-cn.md)

## Initialize Environment

* `export LOGOUTPUT=`: Outputs more detailed compilation information

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
ENV_TOP_HOST     : /home/lengjing/data/cbuild/output/x86_64-native
ENV_OUT_HOST     : /home/lengjing/data/cbuild/output/x86_64-native/objects
ENV_INS_HOST     : /home/lengjing/data/cbuild/output/x86_64-native/sysroot
ENV_DEP_HOST     : /home/lengjing/data/cbuild/output/x86_64-native/sysroot
============================================================
lengjing@lengjing:~/data/cbuild$ export LOGOUTPUT=
```


## Test Application Compilation

* Tests generating shared libraries, static libraries, and executables

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

* Tests that if the header file is changed, the c files that depend on it are also re-compiled

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

* Tests dependency, (`test-app2` depends on `test-app`)

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

* Tests generating multiple shared libraries in one Makefile

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


## Test Kconfig Configuration

* Tests loading the default config to the current config

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-app3$ cd ../test-conf
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ ls config/
    def_config
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ make def_config
    bison	/home/lengjing/data/cbuild/output/x86_64-native/objects/scripts/kconfig/autogen/parser.tab.c
    gcc	/home/lengjing/data/cbuild/output/x86_64-native/objects/scripts/kconfig/autogen/parser.tab.c
    flex	/home/lengjing/data/cbuild/output/x86_64-native/objects/scripts/kconfig/autogen/lexer.lex.c
    gcc	/home/lengjing/data/cbuild/output/x86_64-native/objects/scripts/kconfig/autogen/lexer.lex.c
    gcc	parser/confdata.c
    gcc	parser/menu.c
    gcc	parser/util.c
    gcc	parser/preprocess.c
    gcc	parser/expr.c
    gcc	parser/symbol.c
    gcc	conf.c
    gcc	/home/lengjing/data/cbuild/output/x86_64-native/objects/scripts/kconfig/conf
    gcc	lxdialog/checklist.c
    gcc	lxdialog/inputbox.c
    gcc	lxdialog/util.c
    gcc	lxdialog/textbox.c
    gcc	lxdialog/yesno.c
    gcc	lxdialog/menubox.c
    gcc	mconf.c
    gcc	/home/lengjing/data/cbuild/output/x86_64-native/objects/scripts/kconfig/mconf
    #
    # configuration written to /home/lengjing/data/cbuild/output/noarch/objects/examples/test-conf/.config
    #
    lengjing@lengjing:~/data/cbuild/examples/test-conf$ ls -a ${ENV_OUT_ROOT}/examples/test-conf
    .  ..  .config  .config.old  autoconfig  config.h
    ```

* Tests saving the current config to the specific config

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


## Test Driver Compilation

* Tests compiling drivers and driver dependency (test_hello depends on test_hello_add and test_hello_sub)

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

* Tests generating multiple kernel modules (hello_op and hello_sec) in one Makefile

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


## Test Build Chain

* Tests compilation order of multiple dependency packages

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


## Test Cache Compilation

* Tests downloading, patching, compiling, cache processing

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

## Test Download

* Creates another terminal and starts the mirror server

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ cd ../../output
    lengjing@lengjing:~/data/cbuild/output$ mv mirror-cache mirror
    lengjing@lengjing:~/data/cbuild/output$ cd mirror
    lengjing@lengjing:~/data/cbuild/output/mirror$ python3 -m http.server 8888
    Serving HTTP on 0.0.0.0 port 8888 (http://0.0.0.0:8888/) ...
    ```

* Exports some variables in the original terminal

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ export FETCH_SCRIPT=${ENV_TOOL_DIR}/fetch_package.sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ export COPY_TO_PATH=${ENV_OUT_ROOT}/test
    ```

* Tests downloading `tar` package

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ ${FETCH_SCRIPT} tar http://www.lua.org/ftp/lua-5.4.3.tar.gz lua-5.4.3.tar.gz ${COPY_TO_PATH} lua-5.4.3
    curl http://www.lua.org/ftp/lua-5.4.3.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.3.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.3.tar.gz to /home/lengjing/data/cbuild/output/noarch/objects/test
    ```

* Tests downloading `tar` package from the mirror server http://127.0.0.1:8888

    ```sh
    lengjing@lengjing:~/data/cbuild/examples/test-lua$ ${FETCH_SCRIPT} tar http://www.lua.org/ftp/lua-5.4.4.tar.gz lua-5.4.4.tar.gz ${COPY_TO_PATH} lua-5.4.4
    curl http://127.0.0.1:8888/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz
    untar /home/lengjing/data/cbuild/output/mirror-cache/downloads/lua-5.4.4.tar.gz to /home/lengjing/data/cbuild/output/noarch/objects/test
    ```

* Tests downloading `zip` package

    ```sh
    ${FETCH_SCRIPT} zip https://github.com/curl/curl/releases/download/curl-7_86_0/curl-7.86.0.zip curl-7.86.0.zip ${COPY_TO_PATH} curl-7.86.0
    curl https://github.com/curl/curl/releases/download/curl-7_86_0/curl-7.86.0.zip to /home/lengjing/data/cbuild/output/mirror-cache/downloads/curl-7.86.0.zip
    unzip /home/lengjing/data/cbuild/output/mirror-cache/downloads/curl-7.86.0.zip to /home/lengjing/data/cbuild/output/noarch/objects/test
    ```

* Tests downloading `git` package

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

* Tests downloading `svn` package

```sh
lengjing@lengjing:~/data/cbuild/examples/test-lua$ ${FETCH_SCRIPT} svn https://github.com/lengjingzju/mem mem ${COPY_TO_PATH} mem
svn checkout https://github.com/lengjingzju/mem to /home/lengjing/data/cbuild/output/mirror-cache/downloads/mem
copy /home/lengjing/data/cbuild/output/mirror-cache/downloads/mem to /home/lengjing/data/cbuild/output/noarch/objects/test
```


## Yocto Quick Start

* Install compilation environment

    ```sh
    lengjing@lengjing:~/data/cbuild/scripts$ sudo apt install gawk wget git diffstat unzip \
        texinfo gcc build-essential chrpath socat cpio \
        python3 python3-pip python3-pexpect xz-utils \
        debianutils iputils-ping python3-git python3-jinja2 \
        libegl1-mesa libsdl1.2-dev pylint3 xterm \
        python3-subunit mesa-common-dev zstd liblz4-tool qemu
    ```

* Pulls Poky, version can be get from [Yocto Releases Wiki](https://wiki.yoctoproject.org/wiki/Releases)

    ```sh
    lengjing@lengjing:~/data/cbuild/scripts$ git clone git://git.yoctoproject.org/poky
    lengjing@lengjing:~/data/cbuild/scripts$ cd poky
    lengjing@lengjing:~/data/cbuild/scripts/poky$ git branch -a
    lengjing@lengjing:~/data/cbuild/scripts/poky$ git checkout -t origin/kirkstone -b my-kirkstone
    lengjing@lengjing:~/data/cbuild/scripts/poky$ cd ../../
    ```

* Builds the image

    ```shell
    lengjing@lengjing:~/data/cbuild$ source scripts/poky/oe-init-build-env
    lengjing@lengjing:~/data/cbuild/build$ bitbake core-image-minimal
    lengjing@lengjing:~/data/cbuild/build$ ls -al tmp/deploy/images/qemux86-64/
    lengjing@lengjing:~/data/cbuild/build$ runqemu qemux86-64
    ```


## Test Yocto Build

* Adds the following variable definitions to the configuration `conf/local.conf`

    ```
    ENV_TOP_DIR = "/home/lengjing/data/cbuild"
    ENV_BUILD_MODE = "yocto"
    ```

* Adds meta to test

    ```sh
    lengjing@lengjing:~/data/cbuild/build$ bitbake-layers add-layer ../examples/meta-cbuild
    ```

* Test compilation with bitbak

    ```sh
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-app2  # Compile Application
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-app3  # Compile Application
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-hello # Compile Driver
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-mod2  # Compile Driver
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-conf  # Compile native tool `kconfig`
    lengjing@lengjing:~/data/cbuild/build$ bitbake test-conf -c menuconfig # Modify configuration
    ```

