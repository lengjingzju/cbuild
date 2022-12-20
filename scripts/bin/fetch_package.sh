#!/bin/bash

method=$1
url=$2
package=$3
outdir=$4
outname=$5
checktool=md5sum
checksuffix=src.hash

usage() {
    echo "Usage: $0 method url package -- only fetch package"
    echo "       $0 method url package outdir outname -- fetch and unpack package"
    echo "       $0 sync -- update all git and svn packages"
    echo "       method can be 'zip / tar / git / svn'"
}

do_sync() {
    method=$1
    syncpath=$2

    case $method in
        git)
            if [ -z "$(which git)" ]; then
                echo "ERROR: please install git first."
                exit 1
            fi
            echo -e "\033[32mgit pull in $syncpath\033[0m"
            cd $syncpath && git pull -q
            echo -n "$(git log | head -1 | cut -d ' ' -f 2)" > $syncpath.$checksuffix
            ;;

        svn)
            if [ -z "$(which svn)" ]; then
                echo "ERROR: please install svn first."
                exit 1
            fi
            echo -e "\033[32msvn update in $syncpath\033[0m"
            cd $syncpath && svn update -q
            echo -n "$(svn log | sed -n '2p' | cut -d '|' -f 1 | sed 's/\s//g')" > $syncpath.$checksuffix
            ;;

        *)
            ;;
    esac
}

do_fetch() {
    packname=$package
    if [ $method = git ] || [ $method = svn ]; then
        packname=$package-$method.tar.gz
    fi

    if [ -z "$(which curl)" ]; then
        echo "ERROR: please install curl first."
        exit 1
    fi

    # download package from mirror
    if [ ! -z "${ENV_MIRROR_URL}" ] && [ "$(curl -I -m 5 -s -w %{http_code} -o /dev/null ${ENV_MIRROR_URL}/downloads/$packname)" = "200" ]; then
        echo -e "\033[32mcurl ${ENV_MIRROR_URL}/downloads/$packname to ${ENV_DOWN_DIR}/$packname\033[0m"
        curl -s ${ENV_MIRROR_URL}/downloads/$packname -o ${ENV_DOWN_DIR}/$packname || exit 1
    fi

    case $method in
        zip|tar)
            if [ -z "$(which $checktool)" ]; then
                echo "ERROR: please install $checktool first."
                exit 1
            fi
            if [ ! -e ${ENV_DOWN_DIR}/$packname ]; then
                echo -e "\033[32mcurl $url to ${ENV_DOWN_DIR}/$package\033[0m"
                curl -s $url -JLo ${ENV_DOWN_DIR}/$package || exit 1
            fi
            $checktool ${ENV_DOWN_DIR}/$package | cut -d ' ' -f 1 > ${ENV_DOWN_DIR}/$package.$checksuffix
            ;;

        git)
            if [ -z "$(which git)" ]; then
                echo "ERROR: please install git first."
                exit 1
            fi
            if [ ! -e ${ENV_DOWN_DIR}/$packname ]; then
                echo -e "\033[32mgit clone $url to ${ENV_DOWN_DIR}/$package\033[0m"
                git clone $url ${ENV_DOWN_DIR}/$package || exit 1
                cd ${ENV_DOWN_DIR} && tar -zcf $packname $package
                echo -n "$(cd ${ENV_DOWN_DIR}/$package && git log | head -1 | cut -d ' ' -f 2)" > ${ENV_DOWN_DIR}/$package.$checksuffix
            else
                cd ${ENV_DOWN_DIR} && tar -xf $packname
                do_sync $method ${ENV_DOWN_DIR}/$package
            fi
            ;;

        svn)
            if [ -z "$(which svn)" ]; then
                echo "ERROR: please install svn first."
                exit 1
            fi
            if [ ! -e ${ENV_DOWN_DIR}/$packname ]; then
                echo -e "\033[32msvn checkout $url to ${ENV_DOWN_DIR}/$package\033[0m"
                svn checkout -q $url ${ENV_DOWN_DIR}/$package || exit 1
                cd ${ENV_DOWN_DIR} && tar -zcf $packname $package
                echo -n "$(cd ${ENV_DOWN_DIR}/$package && svn log | sed -n '2p' | cut -d '|' -f 1 | sed 's/\s//g')" > ${ENV_DOWN_DIR}/$package.$checksuffix
            else
                cd ${ENV_DOWN_DIR} && tar -xf $packname
                do_sync $method ${ENV_DOWN_DIR}/$package
            fi
            ;;

        *)
            usage
            exit 1
            ;;
    esac
}

do_unpack() {
    case $method in
        zip)
            echo -e "\033[32munzip ${ENV_DOWN_DIR}/$package to $outdir\033[0m"
            unzip -q ${ENV_DOWN_DIR}/$package -d $outdir
            ;;
        tar)
            echo -e "\033[32muntar ${ENV_DOWN_DIR}/$package to $outdir\033[0m"
            tar -xf ${ENV_DOWN_DIR}/$package -C $outdir
            ;;
        git|svn)
            echo -e "\033[32mcopy ${ENV_DOWN_DIR}/$package to $outdir\033[0m"
            cp -rfp ${ENV_DOWN_DIR}/$package $outdir
            ;;
        *)
            usage
            exit 1
            ;;
    esac

    cp -fp ${ENV_DOWN_DIR}/$package.$checksuffix $outdir/$outname.$checksuffix
}

exec_main() {
    if [ "$method" = "sync" ]; then
        if [ -e "${ENV_DOWN_DIR}" ]; then
            packages=$(ls ${ENV_DOWN_DIR})
            if [ ! -z "$packages" ]; then
                for package in $packages; do
                    if [ "${package: -1}" = "/" ]; then
                        package=${package:0:-1}
                    fi
                    if [ -e ${ENV_DOWN_DIR}/$package/.git ]; then
                        do_sync git ${ENV_DOWN_DIR}/$package
                    elif [ -e ${ENV_DOWN_DIR}/$package/.svn ]; then
                        do_sync svn ${ENV_DOWN_DIR}/$package
                    fi
                done
            fi
        fi
        exit 0
    fi

    if [ -z $method ] || [ -z "$url" ] || [ -z $package ]; then
        usage
        exit 1
    fi

    if [ ! -e ${ENV_DOWN_DIR}/$package ] || [ ! -e ${ENV_DOWN_DIR}/$package.$checksuffix ]; then
        rm -rf ${ENV_DOWN_DIR}/$package ${ENV_DOWN_DIR}/$package-$method.tar.gz ${ENV_DOWN_DIR}/$package.$checksuffix
        mkdir -p ${ENV_DOWN_DIR}
        do_fetch
    fi

    if [ ! -z $outdir ] || [ ! -z $outname ]; then
        if [ ! -e $outdir/$outname ] || [ ! -e $outdir/$outname.$checksuffix ] || \
            [ "$(cat ${ENV_DOWN_DIR}/$package.$checksuffix)" != "$(cat $outdir/$outname.$checksuffix)" ]; then
            rm -rf $outdir/$outname $outdir/$outname.$checksuffix
            mkdir -p $outdir
            do_unpack
        fi
    fi
}

exec_main
