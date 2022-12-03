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
}

if [ -z $method ] || [ -z "$url" ] || [ -z $package ] || [ -z $outdir ] || [ -z $outname ]; then
    usage
    exit 1
fi

if [ ! -e $outdir/$outname ] || [ ! -e $outdir/$outname.$checksuffix ]; then
    rm -rf $outdir/$outname $outdir/$outname.$checksuffix
    mkdir -p $outdir

    if [ ! -e ${ENV_DOWNLOADS}/$package ] || [ ! -e ${ENV_DOWNLOADS}/$package.$checksuffix ]; then
        rm -rf ${ENV_DOWNLOADS}/$package ${ENV_DOWNLOADS}/$package.$checksuffix
        mkdir -p ${ENV_DOWNLOADS}

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
                ;;

            git)
                if [ -z "$(which git)" ]; then
                    echo "ERROR: please install git first."
                    exit 1
                fi
                echo -e "\033[32mgit clone $url to ${ENV_DOWNLOADS}/$package\033[0m"
                git clone $url ${ENV_DOWNLOADS}/$package || exit 1
                ;;

            svn)
                if [ -z "$(which svn)" ]; then
                    echo "ERROR: please install svn first."
                    exit 1
                fi
                echo -e "\033[32msvn checkout $url to ${ENV_DOWNLOADS}/$package\033[0m"
                svn -q checkout $url ${ENV_DOWNLOADS}/$package || exit 1
                ;;

            *)
                usage
                exit 1
                ;;
        esac

        : > ${ENV_DOWNLOADS}/$package.$checksuffix
    fi

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

    : > $outdir/$outname.$checksuffix
fi
