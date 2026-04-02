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
    curl -L -o ${root_path}/downloads/${toolchain64_filename} ${toolchain64_url}
fi

# 32bit Toolchain
if [ ! -f ${root_path}/downloads/${toolchain32_filename} ]; then
    debug_msg "Downloading 32bit toolchain..."
    curl -L -o ${root_path}/downloads/${toolchain32_filename} ${toolchain32_url}
fi

# OPTEE
if [ ! -f ${root_path}/downloads/${optee_filename} ]; then
    debug_msg "Downloading OP-TEE OS..."
    curl -L -o ${root_path}/downloads/${optee_filename} ${optee_src}
fi

# ATF
if [ -z "${atf_binary}" ]; then
    if [ ! -f ${root_path}/downloads/${atf_filename} ]; then
        debug_msg "Downloading Arm Trusted Firmware..."
        curl -L -o ${root_path}/downloads/${atf_filename} ${atf_src}
    fi
else
    if [ ! -f ${root_path}/downloads/bl31.bin ]; then
        debug_msg "Downloading Prebuilt Arm Trusted Firmware..."
        curl -L -o ${root_path}/downloads/bl31.bin ${atf_binary}
    fi
fi

# Stupid U-Boot TPL BS for this SoC
if [ ! -f ${root_path}/downloads/${tpl_filename} ]; then
    debug_msg "Downloading Rockchip TPL (HWInit for U-Boot)..."
    curl -L -o ${root_path}/downloads/${tpl_filename} ${tpl_src}
fi

# U-Boot
if [ ! -f ${root_path}/downloads/${uboot_filename} ]; then
    debug_msg "Downloading U-Boot..."
    curl -L -o ${root_path}/downloads/${uboot_filename} ${uboot_src}
fi

# Kernel
if [ ! -f ${root_path}/downloads/${kernel_filename} ]; then
    debug_msg "Downloading Kernel..."
    curl -L -o ${root_path}/downloads/${kernel_filename} ${kernel_src}
fi

debug_msg "Finished 02_download_dependencies.sh"
