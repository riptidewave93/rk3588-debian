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
    export PATH=${build_path}/32toolchain/${toolchain32_bin_path}:${build_path}/64toolchain/${toolchain64_bin_path}:${PATH}
    export GCC_COLORS=auto
    export CROSS_COMPILE=${toolchain64_cross_compile}
    export M0_CROSS_COMPILE=${toolchain32_cross_compile}

    # CD based on which source we build from
    if [ -d "${atf_builddir}/${atf_filename%.tar.gz}" ]; then
        cd ${atf_builddir}/${atf_filename%.tar.gz}
    else
        cd ${atf_builddir}
    fi

    # Build our ATF
    make ARCH=aarch64 PLAT=${atf_platform} SPD=opteed LOG_LEVEL=20 -j`getconf _NPROCESSORS_ONLN` bl31 
    mv ./build/${atf_platform}/release/bl31/bl31.elf ${build_path}/atf/bl31.bin
else
    cp ${root_path}/downloads/bl31.bin ${build_path}/atf/bl31.bin
fi
