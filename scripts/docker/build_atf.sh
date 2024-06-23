#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Atf output dir
mkdir -p ${build_path}/atf

# If atf_binary is unset, build. Otherwise, download.
if [ -z "${atf_binary}" ]; then
    # Make our temp builddir outside of the world of mounts for SPEEDS
    atf_builddir=$(mktemp -d)
    tar xzf ${root_path}/downloads/${atf_filename} -C ${atf_builddir}

    # Exports baby
    export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
    export GCC_COLORS=auto
    export CROSS_COMPILE=${toolchain_cross_compile}
    export ARCH=arm64

    # CD based on which source we build from
    if [ -d "${atf_builddir}/${atf_filename%.tar.gz}" ]; then
        cd ${atf_builddir}/${atf_filename%.tar.gz}
    else
        cd ${atf_builddir}
    fi

    # Build our ATF
    make LOG_LEVEL=10 PLAT=${atf_platform} bl31
    mv ./build/${atf_platform}/release/bl31/bl31.elf ${build_path}/atf/bl31.bin
else
    cp ${root_path}/downloads/bl31.bin ${build_path}/atf/bl31.bin
fi
