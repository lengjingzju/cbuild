#!/bin/bash

method=$1
url=$2
package=$3
outdir=$4
outname=$5
checksuffix=status.ok

usage() {
    echo "Usage: $0 method url package outdir outname"
    echo "    method can be 'zip / tar / git / svn'"
    echo "Usage: $0 sync -- update all git and svn packages"
}

do_fetch() {
    case $method in
        zip|tar)
            if [ -z "$(which curl)" ]; then
                echo "ERROR: please install curl first."
                exit 1
            fi
            if [ ! -z "${ENV_MIRROR_URL}" ] && [ "$(curl -I -m 5 -s -w %{http_code} -o /dev/null ${ENV_MIRROR_URL}/$package)" = "200" ]; then
                echo -e "\033[32mcurl ${ENV_MIRROR_URL}/$package to ${ENV_DOWNLOADS}/$package\033[0m"
                curl ${ENV_MIRROR_URL}/$package -o ${ENV_DOWNLOADS}/$package || exit 1
            else
                echo -e "\033[32mcurl $url to ${ENV_DOWNLOADS}/$package\033[0m"
                curl $url -JLo ${ENV_DOWNLOADS}/$package || exit 1
            fi
            echo -n "$package: $(date '+%Y-%m-%d %H:%M:%S')" > ${ENV_DOWNLOADS}/$package.$checksuffix
            ;;

        git)
            if [ -z "$(which git)" ]; then
                echo "ERROR: please install git first."
                exit 1
            fi
            echo -e "\033[32mgit clone $url to ${ENV_DOWNLOADS}/$package\033[0m"
            git clone $url ${ENV_DOWNLOADS}/$package || exit 1
            echo -n "$(cd ${ENV_DOWNLOADS}/$package && git log | head -1)" > ${ENV_DOWNLOADS}/$package.$checksuffix
            ;;

        svn)
            if [ -z "$(which svn)" ]; then
                echo "ERROR: please install svn first."
                exit 1
            fi
            echo -e "\033[32msvn checkout $url to ${ENV_DOWNLOADS}/$package\033[0m"
            svn checkout -q $url ${ENV_DOWNLOADS}/$package || exit 1
            echo -n "$(cd ${ENV_DOWNLOADS}/$package && svn log | sed -n '2p' | cut -d '|' -f 1 | sed 's/\s//g')" > ${ENV_DOWNLOADS}/$package.$checksuffix
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
            echo -e "\033[32munzip ${ENV_DOWNLOADS}/$package to $outdir\033[0m"
            unzip -q ${ENV_DOWNLOADS}/$package -d $outdir
            ;;
        tar)
            echo -e "\033[32muntar ${ENV_DOWNLOADS}/$package to $outdir\033[0m"
            tar -xf ${ENV_DOWNLOADS}/$package -C $outdir
            ;;
        git|svn)
            echo -e "\033[32mcopy ${ENV_DOWNLOADS}/$package to $outdir\033[0m"
            cp -rfp ${ENV_DOWNLOADS}/$package $outdir
            ;;
        *)
            usage
            exit 1
            ;;
    esac

    cp -fp ${ENV_DOWNLOADS}/$package.$checksuffix $outdir/$outname.$checksuffix
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
            cd $syncpath && git pull -q|| exit 1
            echo -n "$(git log | head -1)" > $syncpath.$checksuffix
            ;;

        svn)
            if [ -z "$(which svn)" ]; then
                echo "ERROR: please install svn first."
                exit 1
            fi
            echo -e "\033[32msvn update in $syncpath\033[0m"
            cd $syncpath && svn update -q || exit 1
            echo -n "$(svn log | sed -n '2p' | cut -d '|' -f 1 | sed 's/\s//g')" > $syncpath.$checksuffix
            ;;

        *)
            ;;
    esac
}

exec_main() {
    if [ "$method" = "sync" ]; then
        if [ -e "${ENV_DOWNLOADS}" ]; then
            packages=$(ls ${ENV_DOWNLOADS})
            if [ ! -z "$packages" ]; then
                for package in $packages; do
                    if [ "${package: -1}" = "/" ]; then
                        package=${package:0:-1}
                    fi
                    if [ -e ${ENV_DOWNLOADS}/$package/.git ]; then
                        do_sync git ${ENV_DOWNLOADS}/$package
                    elif [ -e ${ENV_DOWNLOADS}/$package/.svn ]; then
                        do_sync svn ${ENV_DOWNLOADS}/$package
                    fi
                done
            fi
        fi
        exit 0
    fi

    if [ -z $method ] || [ -z "$url" ] || [ -z $package ] || [ -z $outdir ] || [ -z $outname ]; then
        usage
        exit 1
    fi

    if [ ! -e ${ENV_DOWNLOADS}/$package ] || [ ! -e ${ENV_DOWNLOADS}/$package.$checksuffix ]; then
        rm -rf ${ENV_DOWNLOADS}/$package ${ENV_DOWNLOADS}/$package.$checksuffix
        mkdir -p ${ENV_DOWNLOADS}
        rm -rf $outdir/$outname $outdir/$outname.$checksuffix
        mkdir -p $outdir
        do_fetch
        do_unpack
    elif [ ! -e $outdir/$outname ] || [ ! -e $outdir/$outname.$checksuffix ]; then
        rm -rf $outdir/$outname $outdir/$outname.$checksuffix
        mkdir -p $outdir
        do_unpack
    elif [ "$(cat ${ENV_DOWNLOADS}/$package.$checksuffix)" != "$(cat $outdir/$outname.$checksuffix)" ]; then
        case $method in
            zip|tar)
                rm -rf $outdir/$outname $outdir/$outname.$checksuffix
                mkdir -p $outdir
                do_unpack
                ;;
            git|svn)
                do_sync $method ${ENV_DOWNLOADS}/$package
                do_sync $method $outdir/$outname
                ;;
            *)
                usage
                exit 1
                ;;
        esac
    fi
}

exec_main
