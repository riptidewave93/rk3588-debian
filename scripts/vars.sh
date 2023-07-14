#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Docker image name
docker_tag=rk3588-builder:builder

# Supported Devices
supported_devices=(rk3588-quartzpro64 rk3588s-rock-5a)

# Toolchain
toolchain_url="https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
toolchain_filename="$(basename $toolchain_url)"
toolchain_bin_path="${toolchain_filename%.tar.xz}/bin"
toolchain_cross_compile="aarch64-none-linux-gnu-"

# Arm Trusted Firmware
atf_src="https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git/snapshot/trusted-firmware-a-d247b8bb2f1dfb30533389cc5516e0d149c50824.tar.gz"
atf_filename="trusted-firmware-a-d247b8bb2f1dfb30533389cc5516e0d149c50824.tar.gz"
atf_platform="rk3588"

# TPL for U-Boot (Stupid RK3588 BS)
tpl_src="https://github.com/rockchip-linux/rkbin/raw/d6ccfe401ca84a98ca3b85c12b9554a1a43a166c/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_v1.11.bin"
tpl_filename="rk3588_tpl.bin"

# U-Boot
uboot_src="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot/-/archive/rk3588-rock5b/u-boot-rk3588-rock5b.zip"
uboot_filename="u-boot-rk3588-rock5b.zip"
uboot_overlay_dir="u-boot"

# Kernel
kernel_src="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/archive/rk3588/linux-rk3588.tar.gz"
kernel_filename="linux-rk3588.tar.gz"
kernel_config="rk3588_defconfig"
kernel_overlay_dir="kernel"

# Distro
distrib_name="debian"
deb_mirror="https://mirrors.kernel.org/debian/"
deb_release="bookworm"
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