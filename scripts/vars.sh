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
optee_src="https://github.com/OP-TEE/optee_os/archive/6dfa501fae923f444358fa337febf16932fc63a1.zip"
optee_filename="optee_os-6dfa501fae923f444358fa337febf16932fc63a1.zip"
optee_overlay_dir="optee"

# Arm Trusted Firmware
#atf_src="https://github.com/ARM-software/arm-trusted-firmware/archive/b68861c7298d981545f89bb95a468c23420b49bb.tar.gz"
#atf_filename="arm-trusted-firmware-b68861c7298d981545f89bb95a468c23420b49bb.tar.gz"
atf_src="https://github.com/worproject/arm-trusted-firmware/archive/d5c68fd928586f4152a3402dfdd9a6ae6e39e392.tar.gz"
atf_filename="arm-trusted-firmware-d5c68fd928586f4152a3402dfdd9a6ae6e39e392.tar.gz"
atf_platform="rk3588"

# TPL for U-Boot (Stupid RK3588 BS)
tpl_src="https://github.com/rockchip-linux/rkbin/raw/69bc9afdef1a15e06c1bd4238fc109bca3b3479a/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.19.bin"
tpl_filename="rk3588_tpl.bin"

# U-Boot
uboot_src="https://github.com/u-boot/u-boot/archive/refs/tags/v2025.07.zip"
uboot_filename="u-boot-2025.07.zip"
uboot_overlay_dir="u-boot"

# Mainline Kernel
kernel_src="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/archive/e920af0b1bde9eae93f6f03c765c2ee2725d7e6a/linux-e920af0b1bde9eae93f6f03c765c2ee2725d7e6a.tar.gz"
kernel_filename="$(basename ${kernel_src})"
kernel_config="rk3588_defconfig"
kernel_overlay_dir="kernel"

# Set BOOTLOADER_ONLY based on a flag file
if [ -f "${build_path}/.bootloader-only" ]; then
    BOOTLOADER_ONLY=true
fi

# Set BOOTLOADER_ONLY based on a flag file
if [ -f "${build_path}/.distro" ]; then
    DISTRO=$(cat "${build_path}/.distro")
fi

# Distro
if [ "${DISTRO}" == "ubuntu" ]; then
    distrib_name="ubuntu"
    deb_mirror="https://ports.ubuntu.com/ubuntu-ports" 
    deb_release="noble"
    deb_args=""
else
    # Default to debian
    distrib_name="debian"
    deb_mirror="https://deb.debian.org/debian" 
    deb_release="bookworm"
    deb_args="--include=apt-transport-https"
fi
deb_arch="arm64"
fs_overlay_dir="filesystem"

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
