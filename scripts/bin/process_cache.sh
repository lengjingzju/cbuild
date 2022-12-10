#!/bin/bash

usage() {
    echo "========================================"
    echo -e "\033[34mUsage: '$0 -m method -p package -s srcfile -o outdir -i insdir -g grade -c checksum -d depends -u url -v verbose\033[0m"
    echo -e "\033[34moptions:\033[0m"
    echo -e "\033[34m-m method\033[0m       : Specify the method: check pull push force cache"
    echo                   "    check       : Check if cache is available, return 'MATCH' if it is available"
    echo                   "                  Necessary options are '-m -p -o -i -g'; Optional options are '-s -c -d -u'"
    echo                   "    pull        : Decompress the image package to outdir"
    echo                   "                  Necessary options are '-m -p -o -i -g'"
    echo                   "    push        : Compress the image dir in outdir to image package"
    echo                   "                  Necessary options are '-m -p -o -i -g'; Optional options are '-s -c -d'"
    echo                   "    setforce    : Set force build from source code"
    echo                   "                  Necessary options are '-m -p -o'"
    echo                   "    unsetforce  : Unset force build from source code"
    echo                   "                  Necessary options are '-m -p -o -i'"
    echo -e "\033[34m-p package\033[0m      : Specify the package name in DEPS statement"
    echo -e "\033[34m-s srcname\033[0m      : Specify the download package name"
    echo -e "\033[34m-o outdir\033[0m       : Specify the output path"
    echo -e "\033[34m-i insdir\033[0m       : Specify the install dir name, it's not ENV_INS_ROOT"
    echo -e "\033[34m-g grade\033[0m        : Specify the grade number in ENV_BUILD_GRADE"
    echo                   "    For Example : If ENV_BUILD_GRADE is 'socname cortex-a55 armv8-a', 1 means socname, 2 means cortex-a55, 3 means armv8-a"
    echo -e "\033[34m-c checksum\033[0m     : Specify extra files and dirs to checksum, dirs support the following grammar"
    echo                   "    Dir Grammar : findpaths:findstrs:ignoredirs:ignorestrs, multiple items in subitems can be separated by '|'"
    echo                   "    For Example : 'srca|srcb:*.c|*.h', 'src::.git:*.o|*.d'"
    echo -e "\033[34m-d depends\033[0m      : Specify the depends manually instead of automatically analyzing global DEPS and .config, 'none' means no depends"
    echo -e "\033[34m-u url\033[0m          : Specify the package download url, the format needs to be '[type]url'"
    echo                   "    For Example : '[tar]url', '[zip]url', '[git]url', '[svn]url'"
    echo -e "\033[34m-v verbose\033[0m      : Specify the verbose mode, log file is outdir/package-cache.log"
    echo "========================================"
}

cmd="$0 $*"
method=
package=
srcname=
outdir=
insdir=
grade=
checksum=
depends=
url=
verbose=1

while getopts "m:p:s:o:i:g:c:d:u:v:h" opt; do
    case $opt in
        m) method=$OPTARG;;
        p) package=$OPTARG;;
        s) srcname=$OPTARG;;
        o) outdir=$OPTARG;;
        i) insdir=$OPTARG;;
        g) grade=$OPTARG;;
        c) checksum=$OPTARG;;
        d) depends=$OPTARG;;
        u) url=$OPTARG;;
        v) verbose=$OPTARG;;
        h) usage; exit 0;;
        *) echo -e "\033[31mERROR: invalid option: '-$opt'\033[0m"; usage; exit 1;;
    esac
done

checktool=md5sum
checktmp1=${outdir}/${package}-checktmp1
checktmp2=${outdir}/${package}-checktmp2
checkfile=${outdir}/${package}-checksum
forcefile=${outdir}/${package}-force
fetchtool=${ENV_TOOL_DIR}/fetch_package.sh
confpath=${ENV_CFG_ROOT}/.config
deppath=${ENV_CFG_ROOT}/DEPS

wlog() {
    if [ $(echo "$1" | grep -c "ERROR:\|WARNING:") -ne 0 ]; then
        if [ $(echo "$1" | grep -c "ERROR:") -ne 0 ]; then
            echo -e "\033[31m$1\033[0m"
        else
            echo -e "\033[33m$1\033[0m"
        fi
    fi

    if [ ${verbose} -eq 1 ]; then
        echo "$1" >> ${outdir}/${package}-cache.log
    fi
}

echo_params() {
    mkdir -p ${outdir}
    wlog
    wlog
    wlog "==================== $(date '+%Y-%m-%d %H:%M:%S') ===================="
    wlog "INFO: cmd: ${cmd}"
    wlog "method   = ${method}"
    wlog "package  = ${package}"
    wlog "srcname  = ${srcname}"
    wlog "outdir   = ${outdir}"
    wlog "insdir   = ${insdir}"
    wlog "grade    = ${grade}"
    wlog "checksum = ${checksum}"
    wlog "depends  = ${depends}"
    wlog "url      = ${url}"
    wlog "verbose  = ${verbose}"
    wlog "============================================================"
}

check_env() {
    if [ -z "$(which curl)" ]; then
        wlog "ERROR: please install curl first."
        exit 1
    fi

    if [ -z "$(which git)" ]; then
        wlog "ERROR: please install git first."
        exit 1
    fi

    if [ -z "$(which svn)" ]; then
        wlog "ERROR: please install svn first."
        exit 1
    fi

    if [ -z "$(which ${checktool})" ]; then
        wlog "ERROR: please install ${checktool} first."
        exit 1
    fi

    if [ -z "${ENV_BUILD_GRADE}" ]; then
        wlog "ERROR: please export ENV_BUILD_GRADE first."
        exit 1
    fi

    if [ -z "${ENV_DOWN_DIR}" ]; then
        wlog "ERROR: please export ENV_DOWN_DIR first."
        exit 1
    fi

    if [ -z "${ENV_CACHE_DIR}" ]; then
        wlog "ERROR: please export ENV_CACHE_DIR first."
        exit 1
    fi

    ret="ok"
    case ${method} in
        check)
            if [ -z "${package}" ] || [ -z "${outdir}" ] || [ -z "${insdir}" ] || [ -z "${grade}" ]; then
                ret="fail"
            fi
            ;;
        pull)
            if [ -z "${package}" ] || [ -z "${outdir}" ] || [ -z "${insdir}" ] || [ -z "${grade}" ]; then
                ret="fail"
            fi
            ;;
        push)
            if [ -z "${package}" ] || [ -z "${outdir}" ] || [ -z "${insdir}" ] || [ -z "${grade}" ]; then
                ret="fail"
            fi
            ;;
        setforce)
            if [ -z "${package}" ] || [ -z "${outdir}" ]; then
                ret="fail"
            fi
            ;;
        unsetforce)
            if [ -z "${package}" ] || [ -z "${outdir}" ] || [ -z "${insdir}" ]; then
                ret="fail"
            fi
            ;;
        *)
            ret="fail"
            ;;
    esac

    if [ "${ret}" = "fail" ]; then
        wlog "ERROR: ${package}: necessary options are not setted all."
        usage
        exit 1
    fi
}

get_source_checksum() {
    if [ ! -z "${srcname}" ]; then
        wlog "get_source_checksum: ${ENV_DOWN_DIR}/${srcname}"
        if [ ! -e ${ENV_DOWN_DIR}/${srcname} ] && [ ! -z "${url}" ]; then
            ${fetchtool} "${url:1:3}" "${url:5}" ${srcname}
            wlog "INFO: fetchcmd: ${fetchtool} ${url:1:3} ${url:5} ${srcname}"
        fi

        if [ -f ${ENV_DOWN_DIR}/${srcname} ]; then
            ${checktool} ${ENV_DOWN_DIR}/${srcname} >> $checktmp1
        elif [ -d ${ENV_DOWN_DIR}/${srcname} ]; then
            if [ -e ${ENV_DOWN_DIR}/${srcname}/.git ]; then
                echo "$(cd ${ENV_DOWN_DIR}/${srcname} && git log | head -1)" >> $checktmp1
            elif [ -e ${ENV_DOWN_DIR}/${srcname}/.svn ]; then
                do_sync svn ${ENV_DOWN_DIR}/${srcname}
                echo "$(cd ${ENV_DOWN_DIR}/${srcname} && svn log | sed -n '2p' | cut -d '|' -f 1 | sed 's/\s//g')"  >> $checktmp1
            else
                wlog "ERROR: ${package}: only support git or svn in download source dir."
                exit 1
            fi
        else
            wlog "ERROR: ${package}: please download ${srcname} to ${ENV_DOWN_DIR} first."
            exit 1
        fi
    fi
}

get_one_depend_checksum() {
    depname=$1
    depcache=""

    if [ ! -z "${depname}" ]; then
        depcache=$(ls ${ENV_CACHE_DIR}/$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f 1)--${depname}--*.tar.gz 2>/dev/null)
        if [ ! -z "${depcache}" ]; then
            ${checktool} ${depcache} >> ${checktmp1}
        else
            depcache=$(ls ${ENV_CACHE_DIR}/$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f 2)--${depname}--*.tar.gz 2>/dev/null)
            if [ ! -z "${depcache}" ]; then
                ${checktool} ${depcache} >> ${checktmp1}
            else
                depcache=$(ls ${ENV_CACHE_DIR}/$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f 3)--${depname}--*.tar.gz 2>/dev/null)
                if [ ! -z "${depcache}" ]; then
                    ${checktool} ${depcache} >> ${checktmp1}
                else
                    depcache=""
                fi
            fi
        fi
    fi

    if [ -z "${depcache}" ]; then
        wlog "depend (${depname}) of ${package} isn't found."
    else
        wlog "depfile: ${depcache}"
    fi
}

get_depend_checksum_auto() {
    if [ -z "${ENV_CFG_ROOT}" ]; then
        wlog "ERROR: when depends is not specified, please export ENV_CFG_ROOT first."
        exit 1
    fi
    if [ ! -e ${confpath} ] || [ ! -e ${deppath} ]; then
        wlog "ERROR: when depends is not specified, ${confpath} and ${deppath} must be existed."
        exit 1
    fi

    depstr=$(cat ${deppath} | grep "^${package}=\".*\"")
    wlog "get_depend_checksum_auto: depstr: ${depstr}"
    if [ ! -z "${depstr}" ]; then
        deps=$(echo "${depstr}" | sed -E "s/^${package}=\"(.*)\"/\1/g")
        wlog "get_depend_checksum_auto: deps: ${deps}"
        if [ ! -z "${deps}" ]; then
            for dep in ${deps}; do
                depname=""
                headchar=${dep:0:1}
                if [ "${headchar}" = "?" ] || [ "${headchar}" = "|" ]; then
                    dep=${dep:1}
                else
                    headchar=""
                fi

                DEP=$(echo "${dep}" | tr 'a-z-' 'A-Z_')
                if [ $(grep -c "^CONFIG_${DEP}=y" ${confpath}) -eq 1 ]; then
                    depname="${dep}"
                else
                    if [ "${headchar}" = "|" ]; then
                        if [ $(echo "${dep}" | grep -c "\-patch\-") -eq 0 ]; then
                            dep=prebuild-${dep}
                            DEP=PREBUILD_${DEP}
                        else
                            dep=$(echo "${dep}" | sed 's/_patch_/_unpatch_/g')
                            DEP=$(echo "${DEP}" | sed 's/_PATCH_/_UNPATCH_/g')
                        fi
                    fi
                    if [ $(grep -c "^CONFIG_${DEP}=y" ${confpath}) -eq 1 ]; then
                        depname="${dep}"
                    fi
                fi

                get_one_depend_checksum ${depname}
            done
        fi
    fi
}

get_depend_checksum() {
    if [ -z "${depends}" ]; then
        get_depend_checksum_auto
    elif [ "${depends}" = "none" ]; then
        : # do nothing
    else
        for depname in depends; do
            get_one_depend_checksum ${depname}
        done
    fi
}

get_extra_checksum() {
    wlog "extra_checksum: ${checksum}"
    if [ ! -z "${checksum}" ]; then
        for item in ${checksum}; do
            if [ $(echo ${item} | grep -c ':') -ne 0 ]; then
                findpaths=$(echo ${item}  | cut -d ':' -f 1 | sed 's/|/ /g')
                findstrs=$(echo ${item}   | cut -d ':' -f 2 | sed 's/|/ /g')
                ignoredirs=$(echo ${item} | cut -d ':' -f 3 | sed 's/|/ /g')
                ignorestrs=$(echo ${item} | cut -d ':' -f 4 | sed 's/|/ /g')

                for findpath in ${findpaths}; do
                    if [ ! -d ${findpath} ]; then
                        wlog "ERROR: ${package}: extra checksum path (${findpath}) isn't folder."
                        exit 1
                    fi
                done

                findcmd=$(echo find ${findpaths} -path \'*/.git\' -prune -o -path \'*/.svn\' -prune \
                    $(echo "${ignoredirs}" | sed "s:\([^ ]\+\):-o -path '*/\1' -prune:g") \
                    $(echo "${ignorestrs}" | sed "s:\([^ ]\+\):-o -name '\1' -prune:g"))

                if [ -z "${findstrs}" ]; then
                    findcmd="${findcmd} -o -type f -print"
                else
                    findcmd="${findcmd} -o -not -type f $(echo "${findstrs}" | sed "s:\([^ ]\+\):-o -name '\1' -print:g")"
                fi

                wlog "--------------------------- find ---------------------------"
                wlog "findpaths  = ${findpaths}"
                wlog "findstrs   = ${findstrs}"
                wlog "ignoredirs = ${ignoredirs}"
                wlog "ignorestrs = ${ignorestrs}"
                wlog "INFO: findcmd: ${findcmd}"
                wlog "------------------------------------------------------------"
                eval $findcmd | xargs ${checktool} >> ${checktmp1}
            elif [ -f ${item} ]; then
                ${checktool} ${item} >> ${checktmp1}
            elif [ -d ${item} ]; then
                find ${item} -type f -print | xargs ${checktool} >> ${checktmp1}
            else
                wlog "ERROR: ${package}: extra checksum path (${item}) isn't existed."
                exit 1
            fi
        done
    fi
}

get_checksum() {
    rm -f ${checktmp1} ${checktmp2} ${checkfile}
    if [ "$1" = "check" ] && [ -e "${forcefile}" ]; then
        wlog "WARNING: Force Build ${package}."
        exit 0
    fi

    mkdir -p ${outdir}
    if [ -e "${forcefile}" ]; then
        echo force > ${checktmp1}
    else
        : > ${checktmp1}
    fi

    get_source_checksum
    get_depend_checksum
    get_extra_checksum

    wlog "-------------------------- ${checktool} --------------------------"
    wlog "$(cat ${checktmp1})"
    wlog "------------------------------------------------------------"
    cat ${checktmp1} | cut -d ' ' -f 1 | sort > ${checktmp2}
    ${checktool} ${checktmp2} | cut -d ' ' -f 1 > ${checkfile}
    rm -f ${checktmp1} ${checktmp2}
}

del_cache() {
    rm -f ${ENV_CACHE_DIR}/$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f 1)--${package}--*.tar.gz \
        ${ENV_CACHE_DIR}/$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f 2)--${package}--*.tar.gz \
        ${ENV_CACHE_DIR}/$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f 3)--${package}--*.tar.gz
    }

check_cache() {
    get_checksum check

    if [ -e ${checkfile} ]; then
        cachefile=$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f ${grade})--${package}--$(cat ${checkfile}).tar.gz
        wlog "INFO: cachefile: ${cachefile}"

        if [ -e "${ENV_CACHE_DIR}/${cachefile}" ]; then
            echo "MATCH"
            wlog "INFO: cachefile: MATCH"
        elif [ ! -z "${ENV_MIRROR_URL}" ] && [ "$(curl -I -m 5 -s -w %{http_code} -o /dev/null ${ENV_MIRROR_URL}/build-cache/${cachefile})" = "200" ]; then
            del_cache
            rm -rf ${insdir}
            mkdir -p ${ENV_CACHE_DIR}
            curl -s ${ENV_MIRROR_URL}/build-cache/${cachefile} -o ${ENV_CACHE_DIR}/${cachefile} || exit 1
            echo "MATCH"
            wlog "INFO: fetchcmd: curl -s ${ENV_MIRROR_URL}/build-cache/${cachefile} -o ${ENV_CACHE_DIR}/${cachefile}"
            wlog "INFO: cachefile: MATCH"
        else
            wlog "INFO: cachefile: UNMATCH, ${ENV_CACHE_DIR}/${cachefile} isn't existed."
        fi
    else
        wlog "INFO: cachefile: UNMATCH, ${checkfile} isn't existed."
    fi
}

pull_cache() {
    if [ ! -e ${insdir} ]; then
        if [ -e ${checkfile} ]; then
            cachefile=$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f ${grade})--${package}--$(cat ${checkfile}).tar.gz
            if [ -e "${ENV_CACHE_DIR}/${cachefile}" ]; then
                mkdir -p ${outdir}
                tar -xf ${ENV_CACHE_DIR}/${cachefile} -C ${outdir}
                wlog "INFO: unpack ${ENV_CACHE_DIR}/${cachefile} to ${outdir}"
                exit 0
            else
                wlog "ERROR: ${package}: cache file (${ENV_CACHE_DIR}/${cachefile}) isn't existed."
                exit 1
            fi
        else
            wlog "ERROR: ${package}: checksum file (${checkfile}) isn't existed."
            exit 1
        fi
    else
        wlog "INFO: pull_cache: ${insdir} is existed, do nothing."
    fi
}

push_cache() {
    if [ ! -d ${insdir} ]; then
        wlog "EERROR: ${package}: install dir (${insdir}) isn't existed."
        exit 1
    fi

    if [ ! -e ${checkfile} ]; then
        get_checksum
        wlog "INFO: push_cache: redo checksum"
    fi
    if [ -e ${checkfile} ]; then
        cachefile=$(echo ${ENV_BUILD_GRADE} | cut -d ' ' -f ${grade})--${package}--$(cat ${checkfile}).tar.gz
        cd $(dirname ${insdir})
        tar -jcf ${cachefile} $(basename ${insdir})
        del_cache
        mkdir -p ${ENV_CACHE_DIR}
        mv ${cachefile} ${ENV_CACHE_DIR}
        wlog "INFO: move ${cachefile} to ${ENV_CACHE_DIR}"
        exit 0
    else
        wlog "ERROR: ${package}: checksum file (${checkfile}) isn't existed."
        exit 1
    fi
}

set_force() {
    mkdir -p ${outdir}
    : > ${forcefile}
}

clean_force() {
    rm -f ${forcefile}
    rm -rf ${insdir}
    del_cache
}

exec_main() {
    echo_params
    check_env
    case ${method} in
        check) check_cache;;
        pull) pull_cache;;
        push) push_cache;;
        setforce) set_force;;
        unsetforce) clean_force;;
        *) exit 1;;
    esac
}

exec_main
