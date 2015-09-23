#!/bin/bash

#set -o xtrace
set -o errexit

function title {
    local line=$@
    echo ''
    echo "*** ${line} ***"
    echo ''
}

kernel_version=${1}
WORKSPACE=${WORKSPACE:-$HOME}
SCRIPTDIR=$(readlink -f $0)
SCRIPTDIR=${SCRIPTDIR%/*}


if [ -z "${kernel_version}" ]; then
    echo "Please provide kernel version to get dump for"
    echo "For example '3.13.0-63"
    exit 1
fi

which abi-dumper

pushd "${WORKSPACE}"

title "Getting linux kernel package"
ddeb_name="linux-image-${kernel_version}-generic-dbgsym"
ddeb_file=$(find . -name "${ddeb_name}*ddeb" -type f | head -n1)
if [ -z "${ddeb_file}" ]; then
    echo "ddeb package for kernel ${kernel_version} not found, trying to download ..."
    aptitude download ${ddeb_name}
    ddeb_file=$(find . -name "${ddeb_name}*ddeb" -type f | head -n1)
    if [ -z "${ddeb_file}" ]; then
        echo "Unable to download file ${ddeb_file}"
        exit 1
    fi
fi


title "Extracting package"
kernel="vmlinux-${kernel_version}-generic"
if [ ! -d ${ddeb_name} ]; then
    mkdir ${ddeb_name}
fi

if [ ! -f ${kernel} ]; then
    if [ ! -f ${ddeb_name}/usr/lib/debug/boot/${kernel} ]; then
        dpkg -x ${ddeb_file} ${ddeb_name}
    fi

    cd ${ddeb_name}
    if [ ! -f usr/lib/debug/boot/${kernel} ]; then
        echo "Something went wrong, can't find ${kernel} file"
        exit 1
    fi

    mv usr/lib/debug/boot/${kernel} .
    rm -rf usr
fi


title "Generating ABI dump"
abi-dumper ${kernel} -o ${kernel}.dump


title "Converting dump to JSON format"
perl ${SCRIPTDIR}/dump2json.pl ${kernel}.dump


title "Generating TypeInfo list"
python ${SCRIPTDIR}/abi-parser.py typeinfo ${kernel}.dump.json | sort > ${kernel}.TypeInfo


title "Generating SymbolInfo list"
python ${SCRIPTDIR}/abi-parser.py symbolinfo ${kernel}.dump.json | sort > ${kernel}.SymbolInfo


popd

