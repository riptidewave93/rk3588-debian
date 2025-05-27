#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Docker image name
docker_tag=rk3588-builder:builder

# Supported Devices
supported_devices=(rk3588-quartzpro64 rk3588s-rock-5a rk3588-rock-5b-plus)

# 64bit Toolchain
toolchain64_url="https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
toolchain64_filename="$(basename ${toolchain64_url})"
toolchain64_bin_path="${toolchain64_filename%.tar.xz}/bin"
toolchain64_cross_compile="aarch64-none-linux-gnu-"

# 32bit Toolchain
toolchain32_url="https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz"
toolchain32_filename="$(basename ${toolchain32_url})"
toolchain32_bin_path="${toolchain32_filename%.tar.xz}/bin"
toolchain32_cross_compile="arm-none-linux-gnueabihf-"

# OP-TEE OS
optee_src="https://github.com/OP-TEE/optee_os/archive/b63e12e4bacb9d35002839c7e837e3372d84d813.zip"
optee_filename="optee_os-b63e12e4bacb9d35002839c7e837e3372d84d813.zip"
optee_overlay_dir="optee"

# Arm Trusted Firmware
atf_src="https://github.com/ARM-software/arm-trusted-firmware/archive/b68861c7298d981545f89bb95a468c23420b49bb.tar.gz"
atf_filename="arm-trusted-firmware-b68861c7298d981545f89bb95a468c23420b49bb.tar.gz"
atf_platform="rk3588"

# TPL for U-Boot (Stupid RK3588 BS)
tpl_src="https://github.com/rockchip-linux/rkbin/raw/7c35e21a8529b3758d1f051d1a5dc62aae934b2b/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin"
tpl_filename="rk3588_tpl.bin"

# U-Boot
uboot_src="https://github.com/u-boot/u-boot/archive/refs/tags/v2025.07-rc3.zip"
uboot_filename="u-boot-2025.07-rc3.zip"
uboot_overlay_dir="u-boot"

# Mainline Kernel
kernel_src="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/archive/d11b3c9daf21d70b24dfbb4ab69b95540d9eb90d/linux-d11b3c9daf21d70b24dfbb4ab69b95540d9eb90d.tar.gz"
kernel_filename="$(basename ${kernel_src})"
kernel_config="rk3588_defconfig"
kernel_overlay_dir="kernel"

# Distro
distrib_name="debian"
deb_mirror="https://deb.debian.org/debian" 
deb_release="bookworm"
deb_arch="arm64"
fs_overlay_dir="filesystem"

# Set BOOTLOADER_ONLY based on a flag file
if [ -f "${build_path}/.bootloader-only" ]; then
    BOOTLOADER_ONLY=true
fi

debug_msg () {
    BLU='\033[0;32m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}

error_msg () {
    BLU='\033[0;31m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}
