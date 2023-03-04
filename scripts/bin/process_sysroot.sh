#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2021-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

opt=$1
src=$2
dst=$3

usage() {
    echo "Usage: $0 <opt> <src> <dst>; and opt can be:"
    echo "    link: link all files in src sysroot to dst sysroot"
    echo "    install: copy all files in src sysroot to dst sysroot"
    echo "    release: copy all files except headers and static libraries in src sysroot to dst sysroot"
    echo "    replace: replace \${src} to \${DEP_PREFIX} of all pkgconfig files in src sysroot"
}

link_sysroot() {
    local s=$1
    local d=$2
    local v=

    mkdir -p $d
    for v in $(ls $s); do
        if [ -d $s/$v ]; then
            link_sysroot $s/$v $d/$v
        else
            if [ $(echo $v | grep -c '\.pc$') -eq 1 ]; then
                cp -df $s/$v $d/$v
                sed -i "s@\${DEP_PREFIX}@${dst}@g" $d/$v
            else
                ln -sf $s/$v $d/$v
            fi
        fi
    done
}

install_sysroot() {
    local s=$1
    local d=$2
    local o=$3
    local v=

    mkdir -p $d
    for v in $(ls $s); do
        if [ -d $s/$v ]; then
            if [ "$v" == "include" ]; then
                install_sysroot $s/$v $d/$v p
            else
                install_sysroot $s/$v $d/$v $o
            fi
        else
            cp -df$o $s/$v $d/$v
            if [ $(echo $v | grep -c '\.pc$') -eq 1 ]; then
                sed -i "s@\${DEP_PREFIX}@${dst}@g" $d/$v
            fi
        fi
    done
}

release_sysroot() {
    local s=$1
    local d=$2
    local v=

    mkdir -p $d
    for v in $(ls $s); do
        if [ -d $s/$v ]; then
            case $v in
                include)
                    continue
                    ;;
                pkgconfig|aclocal|cmake)
                    continue
                    ;;
                include)
                    continue
                    ;;
                locale|man|info|doc)
                    if [ $(echo $s | grep -c '/share$') -eq 1 ]; then
                        continue
                    fi
                    ;;
            esac
            release_sysroot $s/$v $d/$v
        else
            if [ $(echo $v | grep -Ec '\.l?a$') -eq 0 ]; then
                cp -df $s/$v $d/$v
            fi
        fi
    done
}

replace_pkgconfig() {
    pcs="$(find $src -name '*.pc' | xargs)"
    if [ ! -z "$pcs" ]; then
        sed -i "s@${src}@\${DEP_PREFIX}@g" $pcs
    fi
}

case $opt in
    link) link_sysroot $src $dst;;
    install) install_sysroot $src $dst;;
    release) release_sysroot $src $dst;;
    replace) replace_pkgconfig;;
    *) usage; exit 1;;
esac
