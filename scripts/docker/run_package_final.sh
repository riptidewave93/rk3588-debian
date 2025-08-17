#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# Build timestamp
TIMESTAMP=`date +%Y%m%d-%H%M`

# setup our workdir
mkdir -p ${build_path}/final

# We get to gen an image per board, YAY!
for board in "${supported_devices[@]}"; do
	echo "Generating disk image for ${board}"

    # Copy, install, and compress the bootloader image
    cp ${build_path}/bootloader.img ${build_path}/final/uboot-only-${board}.img
    dd if=${build_path}/uboot/${board}.uboot of=${build_path}/final/uboot-only-${board}.img bs=32k seek=1 conv=notrunc
    xz -T0 -v ${build_path}/final/uboot-only-${board}.img

    # Is this a full build? Do the full debian image as well then.
    if [ -z "${BOOTLOADER_ONLY}" ]; then
        # Copy, install, and compress the disk image
        cp ${build_path}/disk.img ${build_path}/final/${distrib_name}-${deb_release}-${board}.img
        dd if=${build_path}/uboot/${board}.uboot of=${build_path}/final/${distrib_name}-${deb_release}-${board}.img bs=32k seek=1 conv=notrunc
        xz -T0 -v ${build_path}/final/${distrib_name}-${deb_release}-${board}.img
    fi
done

# Move bootloaders
mkdir -p ${root_path}/output/${TIMESTAMP}/u-boot
mv ${build_path}/uboot/*.uboot ${root_path}/output/${TIMESTAMP}/u-boot/
mv ${build_path}/final/uboot-only-*.img.xz ${root_path}/output/${TIMESTAMP}/

# Move kernel
mkdir -p ${root_path}/output/${TIMESTAMP}/kernel
mv ${build_path}/kernel/linux-*.deb ${root_path}/output/${TIMESTAMP}/kernel/
mv ${build_path}/kernel/kernel_config ${root_path}/output/${TIMESTAMP}/kernel/
mv ${build_path}/uboot/*.dtb ${root_path}/output/${TIMESTAMP}/kernel/

# Were we not just bootloader?
if [ -z "${BOOTLOADER_ONLY}" ]; then
    # Move debian image
    mv ${build_path}/final/${distrib_name}-${deb_release}-*.img.xz ${root_path}/output/${TIMESTAMP}/
fi

rm -rf ${build_path}

# And finally, update permissions of the output dir to match that of the repo dir
chown -R $(stat -c "%u:%g" ${root_path}) ${root_path}/output
