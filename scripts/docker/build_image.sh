#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Generate disk image file
truncate -s 4G ${build_path}/disk.img

# Setup GPT partition layout
parted ${build_path}/disk.img --script mktable gpt

# Add EFI partition
parted ${build_path}/disk.img --script mkpart EFI fat32 16384KiB 528MiB \
    set 1 boot on \
    set 1 esp on

# Add rootfs partition (start at 554MB, aka end of EFI)
parted ${build_path}/disk.img --script mkpart Debian ext4 554MB 3.5GiB
