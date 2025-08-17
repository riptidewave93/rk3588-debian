#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# See if we are not bootloader only
if [ -z "${BOOTLOADER_ONLY}" ]; then
    # Generate disk image file
    truncate -s 4G ${build_path}/disk.img

    # Setup disk image
    parted ${build_path}/disk.img --script mktable gpt \
        mkpart U-Boot ext4 32KiB 16383.9KiB \
        set 1 hidden on \
        mkpart EFI fat32 16384KiB 528MiB \
        set 2 boot on \
        set 2 esp on \
        mkpart ${distrib_name} ext4 554MB 100%
fi

# Also generate our bootloader disk image for those who run thier own OS
truncate -s 32M ${build_path}/bootloader.img

# Setup bootloader image
parted ${build_path}/bootloader.img --script mktable gpt \
    mkpart U-Boot ext4 32KiB 16383.9KiB \
    set 1 hidden on \
    mkpart EFI fat32 16384KiB 100% \
    set 2 boot on \
    set 2 esp on

# We will format the EFI for the bootloader.img here, since we can only do one
# loopback mount once per docker container before it explodes in sadness.
disk_loop_dev=$(losetup -f -P --show ${build_path}/bootloader.img)
mkfs.fat -n EFI ${disk_loop_dev}p2
losetup -d ${disk_loop_dev}
