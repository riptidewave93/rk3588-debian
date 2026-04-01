#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Exports
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Parse partition offsets and sizes from disk image (in 512-byte sectors)
# Avoids kpartx/device-mapper which doesn't work in macOS Docker VMs
p2_start=$(sfdisk -d ${build_path}/disk.img | grep "disk.img2" | sed 's/.*start= *\([0-9]*\).*/\1/')
p2_size=$(sfdisk -d ${build_path}/disk.img | grep "disk.img2" | sed 's/.*size= *\([0-9]*\).*/\1/')
p3_start=$(sfdisk -d ${build_path}/disk.img | grep "disk.img3" | sed 's/.*start= *\([0-9]*\).*/\1/')
p3_size=$(sfdisk -d ${build_path}/disk.img | grep "disk.img3" | sed 's/.*size= *\([0-9]*\).*/\1/')

# Create separate loop devices per partition using offset/sizelimit
# This uses plain /dev/loopN devices (no device-mapper needed)
efi_loop=$(losetup --offset $((p2_start * 512)) --sizelimit $((p2_size * 512)) -f --show ${build_path}/disk.img)
root_loop=$(losetup --offset $((p3_start * 512)) --sizelimit $((p3_size * 512)) -f --show ${build_path}/disk.img)

# note that p1 is reserved for u-boot

# Now format our partitions
mkfs.fat -F 32 -n EFI ${efi_loop}
mkfs.ext4 -L ${distrib_name} ${root_loop}

# Setup mounts!
mkdir -p ${build_path}/rootfs
mount -t ext4 ${root_loop} ${build_path}/rootfs
mkdir -p ${build_path}/rootfs/boot/efi
mount -t vfat ${efi_loop} ${build_path}/rootfs/boot/efi

# CD into our rootfs mount, and starts the fun!
cd ${build_path}/rootfs
debootstrap --no-check-gpg --arch=${deb_arch} ${deb_args} ${deb_release} ${build_path}/rootfs ${deb_mirror}

# Apply our apt mirror settings
if [ "${distrib_name}" == "debian" ]; then
	echo """deb ${deb_mirror} ${deb_release} main contrib non-free-firmware
deb-src ${deb_mirror} ${deb_release} main contrib non-free-firmware
deb ${deb_mirror} ${deb_release}-updates main contrib non-free-firmware
deb-src ${deb_mirror} ${deb_release}-updates main contrib non-free-firmware
deb https://security.debian.org/debian-security ${deb_release}-security main
deb-src https://security.debian.org/debian-security ${deb_release}-security main""" > ${build_path}/rootfs/etc/apt/sources.list
elif [ "${distrib_name}" == "ubuntu" ]; then
	echo """deb ${deb_mirror} ${deb_release} main restricted universe multiverse
deb-src ${deb_mirror} ${deb_release} main restricted universe multiverse
deb ${deb_mirror} ${deb_release}-updates main restricted universe multiverse
deb-src ${deb_mirror} ${deb_release}-updates main restricted universe multiverse
deb ${deb_mirror} ${deb_release}-security main restricted universe multiverse
deb-src ${deb_mirror} ${deb_release}-security main restricted universe multiverse""" > ${build_path}/rootfs/etc/apt/sources.list
fi

# Copy over our overlay if we have one
if [[ -d ${root_path}/overlay/${fs_overlay_dir}/ ]]; then
	echo "Applying ${fs_overlay_dir} overlay"
	cp -R ${root_path}/overlay/${fs_overlay_dir}/* ./
fi

# Hostname
echo "${distrib_name}" > ${build_path}/rootfs/etc/hostname
echo "127.0.1.1	${distrib_name}" >> ${build_path}/rootfs/etc/hosts

# Populate fstab with UUIDs
echo "UUID=$(findmnt -no uuid ${build_path}/rootfs)  /  ext4  discard,errors=remount-ro  0  0" > ${build_path}/rootfs/etc/fstab
echo "UUID=$(findmnt -no uuid ${build_path}/rootfs/boot/efi)  /boot/efi  vfat  defaults  0  1" >> ${build_path}/rootfs/etc/fstab

# Console settings
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	us
" > ${build_path}/rootfs/debconf.set

# Copy over kernel goodies
cp -r ${build_path}/kernel ${build_path}/rootfs/root/

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
umount ${build_path}/rootfs/boot/efi
umount ${build_path}/rootfs
losetup -d ${efi_loop}
losetup -d ${root_loop}
rm -rf ${build_path}/rootfs
