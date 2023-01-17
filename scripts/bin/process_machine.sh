#!/bin/bash

choice=$1
soc=${ENV_BUILD_SOC}

cpu=
arch=
cpu_family=
endian=
linux_arch=
cross_target=
gcc_arch_option=

linux_version=5.15.88
gcc_version=12.2.0

case $soc in
    'cortex-a53')
        cpu=cortex-a53
        arch=armv8-a
        cpu_family=aarch64
        endian=little
        linux_arch=arm64
        cross_target=aarch64-linux-gnu
        gcc_arch_option="--with-arch=armv8-a --with-cpu=cortex-a53"
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

    cross_target)
        echo "$cross_target"
        ;;
    cross_compile)
        echo "$cross_target-"
        ;;

    linux_arch)
        echo "$linux_arch"
        ;;
    linux_version)
        echo "$linux_version"
        ;;
    gcc_version)
        echo "$gcc_version"
        ;;
    gcc_arch_option)
        echo "$gcc_arch_option"
        ;;
    toolchain_dir)
        echo "$cpu-toolchain-gcc$gcc_version-linux$(echo $linux_version | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)/\1.\2/g')"
        ;;
    toolchain_path)
        echo "${ENV_TOP_DIR}/output/toolchain"
        ;;

    cross_configure)
        echo "--host=$cross_target"
        ;;
    cross_cmake)
        echo "-DCMAKE_SYSTEM_PROCESSOR=$cpu_family -DCMAKE_SYSTEM_NAME=Linux"
        ;;
    cross_meson)
        echo "$cross_target- $cpu_family $cpu $endian"
        ;;
    cache_grades)
        echo "$soc $cpu $arch $cpu_family"
        ;;
    *)
        echo "ERROR: $0: Invalid choice $choice"
        exit 1;
        ;;
esac
