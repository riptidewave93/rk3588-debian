#!/bin/bash
set -e

docker_scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# setup our workdir
mkdir -p ${build_path}/final

# We get to gen an image per board, YAY!
for board in "${supported_devices[@]}"; do
	echo "Generating disk image for ${board}"
	cp ${build_path}/uboot/${board}.uboot ${build_path}/final/u-boot.bin
	cp ${build_path}/disk.img ${build_path}/final/debian-${board}.img
    # Install u-boot to the rockchip offset for EMMC/SD
    dd if=${build_path}/final/u-boot.bin of=${build_path}/final/debian-${board}.img bs=32k seek=1 conv=notrunc
    xz -T0 -v ${build_path}/final/debian-${board}.img
    # Cleanup for next run
	rm ${build_path}/final/u-boot.bin
done

# Just create our final dir and move bits over
TIMESTAMP=`date +%Y%m%d-%H%M`
mkdir -p ${root_path}/output/${TIMESTAMP}/kernel
mkdir -p ${root_path}/output/${TIMESTAMP}/u-boot
mv ${build_path}/final/debian*.img.xz ${root_path}/output/${TIMESTAMP}/
mv ${build_path}/kernel/linux-*.deb ${root_path}/output/${TIMESTAMP}/kernel/
mv ${build_path}/uboot/*.uboot ${root_path}/output/${TIMESTAMP}/u-boot/
rm -rf ${build_path}

# And finally, update permissions of the output dir to match that of the repo dir
chown -R $(stat -c "%u:%g" ${root_path}) ${root_path}/output
