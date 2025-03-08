#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Make our temp builddir outside of the world of mounts for SPEEDS
uboot_builddir=$(mktemp -d)
unzip -q ${root_path}/downloads/${uboot_filename} -d ${uboot_builddir}

# Exports baby
export PATH=${build_path}/64toolchain/${toolchain64_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain64_cross_compile}
export ARCH=arm64
export BL31=${build_path}/atf/bl31.bin
export TEE=${build_path}/optee/tee.bin

# Stupid TPL has to be prebuilt
export ROCKCHIP_TPL=${root_path}/downloads/${tpl_filename}

# Here we go
cd ${uboot_builddir}/${uboot_filename%.zip}

# If we have patches, apply them
if [[ -d ${root_path}/patches/u-boot/ ]]; then
    for file in ${root_path}/patches/u-boot/*.patch; do
        echo "Applying u-boot patch ${file}"
        patch -p1 < ${file}
    done
fi

# Apply overlay if it exists
if [[ -d ${root_path}/overlay/${uboot_overlay_dir}/ ]]; then
    echo "Applying ${uboot_overlay_dir} overlay"
    cp -R ${root_path}/overlay/${uboot_overlay_dir}/* ./
fi

# Each board gets it's own u-boot, so build each at a time
mkdir -p ${build_path}/uboot
for board in "${supported_devices[@]}"; do
    cfg=${board}
    cfg+="_defconfig"
    make distclean
    make ${cfg}
    make -j`getconf _NPROCESSORS_ONLN`

    # Save the config
    make savedefconfig
    mv defconfig ${build_path}/uboot/${board}_defconfig

    # Save the MMC U-Boot image (always exists)
    mv u-boot-rockchip.bin ${build_path}/uboot/${board}.uboot

    # IF we have an SPI image, save that as well!
    if [ -f "u-boot-rockchip-spi.bin" ]; then
        mv u-boot-rockchip-spi.bin ${build_path}/uboot/${board}-spi.uboot
    fi

    # Also save u-boot dtb
    mv u-boot.dtb ${build_path}/uboot/${board}.dtb
done
