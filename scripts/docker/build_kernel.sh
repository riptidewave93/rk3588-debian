#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
kernel_builddir=$(mktemp -d)
tar -xzf ${root_path}/downloads/${kernel_filename} -C ${kernel_builddir}

# Exports baby
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64

# Here we go
cd ${kernel_builddir}/${kernel_filename%.tar.gz}

# If we have patches, apply them
if [[ -d ${root_path}/patches/kernel/ ]]; then
    for file in ${root_path}/patches/kernel/*.patch; do
        echo "Applying kernel patch ${file}"
        patch -p1 < ${file}
    done
fi

# Apply overlay if it exists
if [[ -d ${root_path}/overlay/${kernel_overlay_dir}/ ]]; then
    echo "Applying ${kernel_overlay_dir} overlay"
    cp -R ${root_path}/overlay/${kernel_overlay_dir}/* ./
fi

# Build as normal, with our extra version set to a timestamp
make ${kernel_config}
make -j`getconf _NPROCESSORS_ONLN` EXTRAVERSION=-$(date +%Y%m%d-%H%M%S) bindeb-pkg dtbs

# Save our config
mkdir -p ${build_path}/kernel
make savedefconfig
mv defconfig ${build_path}/kernel/kernel_config

# Prep for storage of important bits
for i in "${supported_devices[@]}"; do
	cp arch/arm64/boot/dts/rockchip/${i}.dtb ${build_path}/kernel
done
cp ${kernel_builddir}/linux-*.deb ${build_path}/kernel
