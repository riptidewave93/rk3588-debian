#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Docker image name
docker_tag=rk3588-builder:builder

# Supported Devices
supported_devices=(rk3588-quartzpro64 rk3588s-rock-5a rk3588-rock-5b-plus)

# Toolchain
toolchain_url="https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
toolchain_filename="$(basename ${toolchain_url})"
toolchain_bin_path="${toolchain_filename%.tar.xz}/bin"
toolchain_cross_compile="aarch64-none-linux-gnu-"

# Arm Trusted Firmware
atf_src="https://github.com/ARM-software/arm-trusted-firmware/archive/74dd541f91bfe5f10b88a0028dcfb0ff55b369b2.tar.gz"
atf_filename="arm-trusted-firmware-74dd541f91bfe5f10b88a0028dcfb0ff55b369b2.tar.gz"
atf_platform="rk3588"

# TPL for U-Boot (Stupid RK3588 BS)
tpl_src="https://github.com/rockchip-linux/rkbin/raw/7c35e21a8529b3758d1f051d1a5dc62aae934b2b/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.18.bin"
tpl_filename="rk3588_tpl.bin"

# U-Boot
uboot_src="https://github.com/u-boot/u-boot/archive/refs/tags/v2025.04-rc2.zip"
uboot_filename="u-boot-2025.04-rc2.zip"
uboot_overlay_dir="u-boot"

# Mainline Kernel
kernel_src="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/archive/e6efacc63426f7cbad6122f14c9eb3e80fe67f46/linux-e6efacc63426f7cbad6122f14c9eb3e80fe67f46.tar.gz"
kernel_filename="$(basename ${kernel_src})"
kernel_config="rk3588_defconfig"
kernel_overlay_dir="kernel"

# Distro
distrib_name="debian"
deb_mirror="http://ftp.us.debian.org/debian"
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
