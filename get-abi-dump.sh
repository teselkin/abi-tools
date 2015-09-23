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
WORKSPACE=${WORKSPACE:-/tmp}
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
    echo 'ddeb package for kernel ${kernel_version} not found, trying to download ...'
    aptitude download ${ddeb_name}
    ddeb_file=$(find . -name "${ddeb_name}*ddeb" -type f | head -n1)
    if [ -z "${ddeb_file}" ]; then
        echo "Unable to download file ${ddeb_file}"
        exit 1
    fi
fi


title "Extracting package"
mkdir ${ddeb_name}
dpkg -x ${ddeb_file} ${ddeb_name}


title "Cleaning up"
cd ${ddeb_name}
mv usr/lib/debug/boot/vmlinux* .
rm -rf usr
kernel_file=$(ls -1 | head -n1)


title "Generating ABI dump"
abi-dumper ${kernel_file} -o ${kernel_file}.dump


title "Converting dump to JSON format"
perl ${SCRIPTDIR}/hash2json.pl ${kernel_file}.dump


title "Generating TypeInfo list"
python ${SCRIPTDIR}/abi-parser.py typeinfo ${kernel_file}.dump.json | sort > ${kernel_file}.TypeInfo


title "Generating SymbolInfo list"
python ${SCRIPTDIR}/abi-parser.py symbolinfo ${kernel_file}.dump.json | sort > ${kernel_file}.SymbolInfo


popd

