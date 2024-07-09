#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Generate disk image file
truncate -s 4G ${build_path}/disk.img

# Setup disk image
parted ${build_path}/disk.img --script mktable gpt \
    mkpart U-Boot ext4 32KiB 16383.9KiB \
    set 1 hidden on \
    mkpart EFI fat32 16384KiB 528MiB \
    set 2 boot on \
    set 2 esp on

# Add rootfs partition (start at 554MB, aka end of EFI)
parted ${build_path}/disk.img --script mkpart Debian ext4 554MB 100%

# Also generate our bootloader disk image for those who run thier own OS
truncate -s 32M ${build_path}/bootloader.img

# Setup bootloader image
parted ${build_path}/bootloader.img --script mktable gpt \
    mkpart U-Boot ext4 32KiB 16383.9KiB \
    set 1 hidden on
