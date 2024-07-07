#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Exports
export PATH=${build_path}/toolchain/${toolchain_bin_path}:${PATH}
export GCC_COLORS=auto
export CROSS_COMPILE=${toolchain_cross_compile}
export ARCH=arm64
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Mount our loopback for the image
disk_loop_dev=$(losetup -f -P --show ${build_path}/disk.img)

# Now format our partitions since were mounted as a loop device
mkfs.fat -F 32 -n EFI ${disk_loop_dev}p1
mkfs.ext4 -L Debian ${disk_loop_dev}p2

# Setup mounts!
mkdir -p ${build_path}/rootfs
mount -t ext4 ${disk_loop_dev}p2 ${build_path}/rootfs
mkdir -p ${build_path}/rootfs/boot/efi
mount -t vfat ${disk_loop_dev}p1 ${build_path}/rootfs/boot/efi

# CD into our rootfs mount, and starts the fun!
cd ${build_path}/rootfs
debootstrap --no-check-gpg --foreign --arch=${deb_arch} --include=apt-transport-https ${deb_release} ${build_path}/rootfs ${deb_mirror}
cp /usr/bin/qemu-aarch64-static usr/bin/
chroot ${build_path}/rootfs /debootstrap/debootstrap --second-stage

# Copy over our overlay if we have one
if [[ -d ${root_path}/overlay/${fs_overlay_dir}/ ]]; then
	echo "Applying ${fs_overlay_dir} overlay"
	cp -R ${root_path}/overlay/${fs_overlay_dir}/* ./
fi

# Hostname
echo "${distrib_name}" > ${build_path}/rootfs/etc/hostname
echo "127.0.1.1	${distrib_name}" >> ${build_path}/rootfs/etc/hosts

# Console settings
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > ${build_path}/rootfs/debconf.set

# Copy over kernel goodies
cp -r ${build_path}/kernel ${build_path}/rootfs/root/

# Remove the debug kernel
#rm ${build_path}/rootfs/root/kernel/linux-image-*-dbg_*.deb

# Do mounts for grub
mount --bind /dev ${build_path}/rootfs/dev
mount --bind /sys ${build_path}/rootfs/sys
mount --bind /proc ${build_path}/rootfs/proc

# Kick off bash setup script within chroot
cp ${docker_scripts_path}/bootstrap/001-bootstrap ${build_path}/rootfs/bootstrap
chroot ${build_path}/rootfs /bootstrap
rm ${build_path}/rootfs/bootstrap

# Cleanup mounts for grub
umount ${build_path}/rootfs/proc
umount ${build_path}/rootfs/sys
umount ${build_path}/rootfs/dev

# CD out before cleanup!
cd ${build_path}

# Final cleanup
rm ${build_path}/rootfs/usr/bin/qemu-aarch64-static
umount ${build_path}/rootfs/boot/efi
umount ${build_path}/rootfs
losetup -d ${disk_loop_dev}
rm -rf ${build_path}/rootfs
