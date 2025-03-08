#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
optee_builddir=$(mktemp -d)
unzip -q ${root_path}/downloads/${optee_filename} -d ${optee_builddir}

# Exports baby
export PATH=${build_path}/64toolchain/${toolchain64_bin_path}:${build_path}/32toolchain/${toolchain32_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE64=${toolchain64_cross_compile}
export CROSS_COMPILE32=${toolchain32_cross_compile}
export O=out/rk3588
export CFG_TEE_CORE_LOG_LEVEL=2 
export PLATFORM=rockchip-rk3588
export CFG_ENABLE_EMBEDDED_TESTS=y
export CFG_VIRTUALIZATION=y
export CFG_CORE_DYN_SHM=y
export CFG_CORE_RESERVED_SHM=n
export CFG_DRAM_BASE=0x60000000
export CFG_DRAM_SIZE=0x20000000 # 1GB

# Here we go
cd ${optee_builddir}/${optee_filename%.zip}

# If we have patches, apply them
if [[ -d ${root_path}/patches/optee/ ]]; then
    for file in ${root_path}/patches/optee/*.patch; do
        echo "Applying optee patch ${file}"
        patch -p1 < ${file}
    done
fi

# Apply overlay if it exists
if [[ -d ${root_path}/overlay/${optee_overlay_dir}/ ]]; then
    echo "Applying ${optee_overlay_dir} overlay"
    cp -R ${root_path}/overlay/${optee_overlay_dir}/* ./
fi

# Shared tee application for all rk3588 boards
mkdir -p ${build_path}/optee

make -j`getconf _NPROCESSORS_ONLN`

mv out/rk3588/core/tee.bin ${build_path}/optee/tee.bin
