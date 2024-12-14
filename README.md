# rk3588-debian

Build script to build a Debian 12 image for select RK3588(s) based boards, as well as all dependencies. This includes the following:

Due to the age of the RK3588(s) SoC, this repo is unable to be 100% upstream at this time. However, staging branches/PRs for upstream work are targeted to give the best experience for the time being. Expect features to be missing as the SoC is brought up to mainline support standards. **Note that this repo is experimental!**

- Linux Kernel - [Collabora's rk3588-test branch at commit 3b518030](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/tree/3b5180306d5e009272ef1fc09a571beabec5964c)
- Arm Trusted Firmware - [Mainline at commit f340f3d](https://github.com/ARM-software/arm-trusted-firmware/tree/f340f3d891b7184e1ab790955137d508b45a63cd)
- Mainline U-Boot - [v2025.01-rc3](https://github.com/u-boot/u-boot/tree/v2025.01-rc3)

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

Note that if you want to manually flash the .uboot image to update an existing install, this can be done with something similar to below. Just be sure to update the target block device to match where your u-boot image currently lives.

`dd if=./rk3588-BOARDNAME.uboot of=/dev/mmcblk0 bs=32k seek=1 conv=notrunc`

## To Do
* All Boards
  * HDM1 does not work
  * No NPU support (should be ready soon)
* Board Specific
  * QuartzPro64
    * USB3 does not work
      * Requires [hynetek,husb311 driver port](https://github.com/radxa/kernel/blob/linux-6.1-stan-rkr1/drivers/usb/typec/tcpm/tcpci_husb311.c), or can look at using [fcs,fusb302](https://github.com/torvalds/linux/blob/v6.12/drivers/usb/typec/tcpm/fusb302.c) as it [should work](https://en.hynetek.com/2567.html).

* You tell me. Bug reports and PRs welcome!

## Notes

- This is a pet project that can change rapidly. Production use is not advised. Please only proceed if you know what you are doing!
