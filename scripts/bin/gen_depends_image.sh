#!/bin/bash

package=$1
outdir=$2
deppath=$3
dones=" "

if [ -z `which dot` ]; then
    echo -e "\033[31mERROR: Please install graphviz first (sudo apt install graphviz).\033[0m"
    exit 1
fi

if [ ! -e ${outdir} ]; then
    mkdir -p ${outdir}
fi

write_rule() {
    target=$1
    if [ ! -z "${target}" ]; then
        depstr=$(cat ${deppath} | grep "^${target}=\".*\"")
        if [ ! -z "${depstr}" ]; then
            deps=$(echo "${depstr}" | sed -E "s/^${target}=\"(.*)\"/\1/g")
            if [ ! -z "${deps}" ]; then
                for dep in ${deps}; do
                    if [ ${dep:0:1} = "?" ]; then
                        dep=${dep:1}
                        echo "\"${target}\" -> \"${dep}\" [style = dashed]" >> ${outdir}/${package}.dot
                    else
                        echo "\"${target}\" -> \"${dep}\"" >> ${outdir}/${package}.dot
                    fi
                done

                for dep in ${deps}; do
                    if [ ${dep:0:1} = "?" ]; then
                        dep=${dep:1}
                    fi
                    if [ $(echo "${dones}" | grep -c " ${dep} ") -eq 0 ]; then
                        dones="${dones}${dep} "
                        write_rule ${dep}
                    fi
                done
            fi
        fi
    fi
}

echo "digraph depends {" > ${outdir}/${package}.dot
if [ "${ENV_BUILD_MODE}" = "yocto" ]; then
    bitbake -g -I .*-native$ ${package} || exit 1
    cat task-depends.dot | \
        grep '".*\.do_prepare_recipe_sysroot" -> ".*\.do_populate_sysroot"' | \
        grep -v gcc | \
        grep -v glibc | \
        sed -E 's/"(.*)\.do_prepare_recipe_sysroot" -> "(.*)\.do_populate_sysroot"/"\1" -> "\2"/g' >> ${outdir}/${package}.dot
        else
            if [ ! -e ${deppath} ]; then
                echo -e "\033[31mERROR: ${deppath} is not existed.\033[0m"
                exit 1
            fi
            write_rule ${package}
fi
echo "}" >> ${outdir}/${package}.dot

dot -Tsvg -o ${outdir}/${package}.svg ${outdir}/${package}.dot
dot -Tpng -o ${outdir}/${package}.png ${outdir}/${package}.dot
echo -e "\033[32mNote: ${package}.dot ${package}.svg and ${package}.png are generated in the ${outdir} folder.\033[0m"
