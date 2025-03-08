#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 02_download_dependencies.sh"

# Make sure our BuildEnv dir exists
if [ ! -d ${root_path}/downloads ]; then
    mkdir ${root_path}/downloads
fi

# 64bit Toolchain
if [ ! -f ${root_path}/downloads/${toolchain64_filename} ]; then
    debug_msg "Downloading 64bit toolchain..."
    wget ${toolchain64_url} -P ${root_path}/downloads
fi

# 32bit Toolchain
if [ ! -f ${root_path}/downloads/${toolchain32_filename} ]; then
    debug_msg "Downloading 32bit toolchain..."
    wget ${toolchain32_url} -P ${root_path}/downloads
fi

# OPTEE
if [ ! -f ${root_path}/downloads/${optee_filename} ]; then
    debug_msg "Downloading OP-TEE OS..."
    wget ${optee_src} -O ${root_path}/downloads/${optee_filename}
fi

# ATF
if [ -z "${atf_binary}" ]; then
    if [ ! -f ${root_path}/downloads/${atf_filename} ]; then
        debug_msg "Downloading Arm Trusted Firmware..."
        wget ${atf_src} -O ${root_path}/downloads/${atf_filename}
    fi
else
    if [ ! -f ${root_path}/downloads/bl31.bin ]; then
        debug_msg "Downloading Prebuilt Arm Trusted Firmware..."
        wget ${atf_binary} -O ${root_path}/downloads/bl31.bin
    fi
fi

# Stupid U-Boot TPL BS for this SoC
if [ ! -f ${root_path}/downloads/${tpl_filename} ]; then
    debug_msg "Downloading Rockchip TPL (HWInit for U-Boot)..."
    wget ${tpl_src} -O ${root_path}/downloads/${tpl_filename}
fi

# U-Boot
if [ ! -f ${root_path}/downloads/${uboot_filename} ]; then
    debug_msg "Downloading U-Boot..."
    wget ${uboot_src} -O ${root_path}/downloads/${uboot_filename}
fi

# Kernel
if [ ! -f ${root_path}/downloads/${kernel_filename} ]; then
    debug_msg "Downloading Kernel..."
    wget ${kernel_src} -O ${root_path}/downloads/${kernel_filename}
fi

debug_msg "Finished 02_download_dependencies.sh"
