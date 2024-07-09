# rk3588-debian

Build script to build a Debian 12 image for select RK3588(s) based boards, as well as all dependencies. This includes the following:

Due to the age of the RK3588(s) SoC, this repo is unable to be 100% upstream at this time. However, staging branches/PRs for upstream work are targeted to give the best experience for the time being. Expect features to be missing as the SoC is brought up to mainline support standards. **Note that this repo is experimental!**

- Linux Kernel - [Collabora's rk3588 mainline staging branch](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/tree/rk3588?ref_type=heads)
- Arm Trusted Firmware - [Upstream RK3588 ATF PR + Crypto enablement patch](https://review.trustedfirmware.org/c/TF-A/trusted-firmware-a/+/29363/)
- Mainline U-Boot - [v2024.07](https://github.com/u-boot/u-boot/tree/v2024.07)

Note that there are patches/modifications applied to the kernel and u-boot. The changes made can be seen in the `./patches` and `./overlay` directories. Also, a `./downloads` directory is generated to store a copy of the toolchain during the first build.

## Supported Boards

Currently images for the following devices are generated:
* Pine64 QuartzPro64
* Raxda Rock 5A

## Requirements

- The following packages below are required to use this build script. Note that this repo uses a Dockerfile to handle most of the heavy lifting, but some system requirements still exist.

`docker-ce losetup wget sudo make qemu-user-static`

Note that without qemu-user-static, debootstrap will fail!

## Usage

- Just run `make`.
- Completed builds output to `./output`
- To cleanup and clear all builds, run `make clean`

Other helpful commands:

- Have a build fail and have stale mounts? `make mountclean`
- Want to delete the download cache and do a 100% fresh build? `make distclean`

Default login is username and password of debian.

## Flashing

- Take your completed image from `./output` and extract it with xz.
- Flash directly to an SD card, or to eMMC.
  - SD Example: `dd if=./debian-rk3588*.img of=/dev/mmcblk0 bs=4M conv=fdatasync`
  - eMMC Example: `rkdeveloptool write 0 ./debian-rk3588*.img`

Note you can flash the `uboot-only-*.img` file, but it only contains a single GPT partition to protect U-Boot. If you decide to use this image, it's recommended to NOT erase the GPT layout, and to add new partitions only. This image is also useful for installing/booting your own OS off of NVMe/USB.

## To Do

* quartzpro64
  * Fixup/finish kernel device tree
    * USB3 does not work
      * Requires [hynetek,husb311 driver port](https://github.com/radxa/kernel/blob/linux-6.1-stan-rkr1/drivers/usb/typec/tcpm/tcpci_husb311.c)
    * Wifi/Bluetooth do not work
      * Known issue, being worked on [here](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/commit/b4f3c74742302298b54025df73d26c5550707c37)
    * Probably more...
* Display currently does not work, as the HDMI ports are not wired up in the device tree
* You tell me. Bug reports and PRs welcome!

## Notes

- This is a pet project that can change rapidly. Production use is not advised. Please only proceed if you know what you are doing!
