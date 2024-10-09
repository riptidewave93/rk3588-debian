# rk3588-debian

Build script to build a Debian 12 image for select RK3588(s) based boards, as well as all dependencies. This includes the following:

Due to the age of the RK3588(s) SoC, this repo is unable to be 100% upstream at this time. However, staging branches/PRs for upstream work are targeted to give the best experience for the time being. Expect features to be missing as the SoC is brought up to mainline support standards. **Note that this repo is experimental!**

- Linux Kernel - [Collabora's rk3588 mainline test branch](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/commits/rk3588-test/?ref_type=heads)
- Arm Trusted Firmware - [Mainline at commit 5765e0c](https://github.com/ARM-software/arm-trusted-firmware/tree/5765e0c95ae04119b90fb4c4ce27de032fc4404a)
- Mainline U-Boot - [v2024.10](https://github.com/u-boot/u-boot/tree/v2024.10)

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

### Full Debian 12 Image

  - Run `make`.
  - Completed builds output to `./output`
  - To cleanup and clear all builds, run `make clean`

  Default login is username and password of `debian`.

### EFI Bootloader Image

  If you only want a U-Boot image and kernel debs that pair with it, this is for you. Note that if you "repartition" the disk you flash this to, u-boot will be erased unless you manually re-flash it, so this is for advanced users only!

  - Run `make bootloader`.
  - Completed builds output to `./output`
  - To cleanup and clear all builds, run `make clean`

### Other helpful commands

  - Have a build fail and have stale mounts? `make mountclean`
  - Want to delete the download cache and do a 100% fresh build? `make distclean`

## Flashing

- Take your completed image from `./output` and extract it with xz.
- Flash directly to an SD card, or to eMMC.
  - SD Example: `dd if=./debian-rk3588*.img of=/dev/mmcblk0 bs=4M conv=fdatasync`
  - eMMC Example: `rkdeveloptool write 0 ./debian-rk3588*.img`

Note you can flash the `uboot-only-*.img` file, but it only contains a single GPT partition to protect U-Boot. If you decide to use this image, it's recommended to NOT erase the GPT layout, and to add new partitions only. This image is also useful for installing/booting your own OS off of NVMe/USB.

## To Do

* QuartzPro64
  * USB3 does not work
    * Requires [hynetek,husb311 driver port](https://github.com/radxa/kernel/blob/linux-6.1-stan-rkr1/drivers/usb/typec/tcpm/tcpci_husb311.c)
  * Wifi/Bluetooth do not work
    * Known issue, being worked on [here](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/commit/b4f3c74742302298b54025df73d26c5550707c37)
  * HDMI1 does not work
  * Probably more...
* Rock 5A
  * HDMI1 does not work
* You tell me. Bug reports and PRs welcome!

## Notes

- This is a pet project that can change rapidly. Production use is not advised. Please only proceed if you know what you are doing!
