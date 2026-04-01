#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Exports
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Mount our loopback for the image
# Use kpartx instead of losetup -P for macOS Docker VM compatibility
disk_loop_dev=$(losetup -f --show ${build_path}/disk.img)
kpartx -av ${disk_loop_dev}
loop_name=$(basename ${disk_loop_dev})

# note that p1 is reserved for u-boot

# Now format our partitions since were mounted as a loop device
mkfs.fat -F 32 -n EFI /dev/mapper/${loop_name}p2
mkfs.ext4 -L ${distrib_name} /dev/mapper/${loop_name}p3

# Setup mounts!
mkdir -p ${build_path}/rootfs
mount -t ext4 /dev/mapper/${loop_name}p3 ${build_path}/rootfs
mkdir -p ${build_path}/rootfs/boot/efi
mount -t vfat /dev/mapper/${loop_name}p2 ${build_path}/rootfs/boot/efi

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
kpartx -dv ${disk_loop_dev}
losetup -d ${disk_loop_dev}
rm -rf ${build_path}/rootfs
