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

# Format the EFI partition for bootloader.img without loop devices.
# mkfs.fat works directly on regular files - create a temp file for the
# partition, format it, then dd it into the correct offset in the image.
efi_offset_kb=16384
efi_size_kb=$(( (32 * 1024) - efi_offset_kb ))
truncate -s ${efi_size_kb}K ${build_path}/bootloader_efi.tmp
mkfs.fat -n EFI ${build_path}/bootloader_efi.tmp
dd if=${build_path}/bootloader_efi.tmp of=${build_path}/bootloader.img bs=1K seek=${efi_offset_kb} conv=notrunc
rm ${build_path}/bootloader_efi.tmp
