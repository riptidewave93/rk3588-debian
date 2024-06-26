#!/bin/bash

root_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
build_path="${root_path}/BuildEnv"

# Docker image name
docker_tag=rk3588-builder:builder

# Supported Devices
supported_devices=(rk3588-quartzpro64 rk3588s-rock-5a)

# Toolchain
toolchain_url="https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-linux-gnu.tar.xz"
toolchain_filename="$(basename ${toolchain_url})"
toolchain_bin_path="${toolchain_filename%.tar.xz}/bin"
toolchain_cross_compile="aarch64-none-linux-gnu-"

# Arm Trusted Firmware
# We are using the upstream patch + crypto enable patch, so we can move away from RK's prebuilt. We are using:
# https://review.trustedfirmware.org/c/TF-A/trusted-firmware-a/+/21840/ - rk3588 support
# https://review.trustedfirmware.org/c/TF-A/trusted-firmware-a/+/29363/ - crypto patch (based on rk3588 support)
atf_src="https://git.trustedfirmware.org/plugins/gitiles/TF-A/trusted-firmware-a/+archive/c805c14c1026b3ae5445e211c2101c60cd76ad0e.tar.gz"
atf_filename="$(basename ${atf_src})"
atf_platform="rk3588"

# TPL for U-Boot (Stupid RK3588 BS)
tpl_src="https://github.com/rockchip-linux/rkbin/raw/a2a0b89b6c8c612dca5ed9ed8a68db8a07f68bc0/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.16.bin"
tpl_filename="rk3588_tpl.bin"

# U-Boot
uboot_src="https://github.com/u-boot/u-boot/archive/refs/tags/v2024.07-rc4.zip"
uboot_filename="u-boot-2024.07-rc4.zip"
uboot_overlay_dir="u-boot"

# Mainline Kernel
kernel_src="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/archive/rk3588/linux-rk3588.tar.gz"
kernel_filename="$(basename ${kernel_src})"
kernel_config="rk3588_defconfig"
kernel_overlay_dir="kernel"

# Genimage
genimage_src="https://github.com/pengutronix/genimage/releases/download/v16/genimage-16.tar.xz"
genimage_filename="$(basename ${genimage_src})"
genimage_repopath="${genimage_filename%.tar.xz}"

# Distro
distrib_name="debian"
#deb_mirror="http://ftp.us.debian.org/debian"
deb_mirror="http://debian.uchicago.edu/debian"
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
