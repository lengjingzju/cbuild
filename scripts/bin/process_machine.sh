#!/bin/bash

choice=$1
soc=${ENV_BUILD_SOC}
cpu=
arch=
cpu_family=
endian=
cross_compile=

linux_arch=
linux_version=5.15.88
gcc_version=12.2.0
toolchain_pathname=

case $soc in
    'cortex-a53+crypto')
        cpu=cortex-a53+crypto
        arch=armv8-a
        cpu_family=aarch64
        endian=little
        cross_compile=aarch64-linux-gnu
        linux_arch=arm64
        ;;
    'cortex-a76')
        cpu=cortex-a76
        arch=armv8-a
        cpu_family=aarch64
        endian=little
        cross_compile=aarch64-linux-gnu
        linux_arch=arm64
        ;;
    *)
        echo "ERROR: $0: Invalid soc $soc"
        exit 1;
        ;;
esac

case $choice in
    cpu)
        echo "$cpu"
        ;;
    arch)
        echo "$arch"
        ;;
    cpu_family)
        echo "$cpu_family"
        ;;
    endian)
        echo "$endian"
        ;;
    cross_compile)
        echo "$cross_compile-"
        ;;

    linux_arch)
        echo "$linux_arch"
        ;;
    linux_version)
        echo "$linux_version"
        ;;
    gcc_version)
        echo "$linux_version"
        ;;
    toolchain_pathname)
        echo "$cpu-toolchain-gcc$gcc_version-linux$linux_version"
        ;;

    cross_configure)
        echo "--host=$cross_compile"
        ;;
    cross_cmake)
        echo "-DCMAKE_SYSTEM_PROCESSOR=$cpu_family -DCMAKE_SYSTEM_NAME=Linux"
        ;;
    cross_meson)
        echo "$cross_compile- $cpu_family $cpu $endian"
        ;;
    cache_grades)
        echo "$soc $cpu $arch $cpu_family"
        ;;
    *)
        echo "ERROR: $0: Invalid choice $choice"
        exit 1;
        ;;
esac
