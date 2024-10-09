#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 03_docker.sh"

# Start with things we can do now
if [ ! -d ${build_path}/toolchain ]; then
    debug_msg "Setting up the toolchain for docker..."
    mkdir -p ${build_path}/toolchain
    tar -xf ${root_path}/downloads/${toolchain_filename} -C ${build_path}/toolchain
fi

if [ ! -f ${build_path}/atf/bl31.bin ]; then
    debug_msg "Docker: Building ATF..."
    docker run --ulimit nofile=1024 --rm -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/build_atf.sh
fi

if [ ! -d ${build_path}/uboot ]; then
    debug_msg "Docker: Building U-Boot..."
    docker run --ulimit nofile=1024 --rm -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/build_uboot.sh
fi

if [ ! -d ${build_path}/kernel ]; then
    debug_msg "Docker: Building Kernel..."
    docker run --ulimit nofile=1024 --rm -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/build_kernel.sh
fi

debug_msg "Doing safety checks... please enter your password for sudo if prompted..."
# Before we do anything, make our dirs, and validate they are not mounted atm. If they are, exit!
if mountpoint -q ${build_path}/rootfs/boot/efi; then
    error_msg "ERROR: ${build_path}/rootfs/boot/efi is mounted before it should be! Cleaning up..."
    sudo umount ${build_path}/rootfs/boot/efi
fi
if mountpoint -q ${build_path}/rootfs; then
    error_msg "ERROR: ${build_path}/rootfs is mounted before it should be! Cleaning up..."
    sudo umount ${build_path}/rootfs
fi

debug_msg "Docker: Generating Disk Images..."
docker run --ulimit nofile=1024 --rm --privileged --cap-add=ALL -v "/dev:/dev:Z" -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/build_image.sh

# Only debootstrap on full build
if [ -z "${BOOTLOADER_ONLY}" ]; then
    debug_msg "Docker: debootstraping..."
    docker run --ulimit nofile=1024 --rm --privileged --cap-add=ALL -v "/dev:/dev:Z" -v "${root_path}:/repo:Z" -it ${docker_tag} /repo/scripts/docker/run_debootstrap.sh
fi

debug_msg "Finished 03_docker.sh"