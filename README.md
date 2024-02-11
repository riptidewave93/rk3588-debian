# rk3588-debian

Build script to build a Debian 12 image for select RK3588(s) based boards, as well as all dependencies. This includes the following:

Due to the age of the RK3588(s) SoC, this repo is unable to be 100% upstream at this time. However, staging branches/PRs for upstream work are targeted to give the best experience for the time being. Expect features to be missing as the SoC is brought up to mainline support standards. **Note that this repo is EXTREMELY experimental!**

- Linux Kernel - [Collabora's rk3588 mainline staging branch](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/tree/rk3588?ref_type=heads)
- Arm Trusted Firmware - [Collabora's rk3588 fork of upstream PR](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/trusted-firmware-a/-/tree/rk3588?ref_type=heads)
- Mainline U-Boot - [v2024.04-rc1](https://github.com/u-boot/u-boot/tree/v2024.04-rc1)

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
- Take your completed image from `./output` and extract it with gunzip
- Flash directly to an SD card, or to eMMC.
  - SD Example: `dd if=./debian-rk3588*.img of=/dev/mmcblk0 bs=4M conv=fdatasync`
  - eMMC Example: `rkdeveloptool write 0 ./debian-rk3588*.img`

## To Do
* quartzpro64
  * Fixup/finish kernel device tree
    * USB3 does not work
      * Requires hynetek,husb311 driver port most likely
    * Wifi/Bluetooth do not work
      * No driver for ap6255? google says it should work...
    * Probably more...
* You tell me. Bug reports and PRs welcome!

## Notes
- This is a pet project that can change rapidly. Production use is not advised. Please only proceed if you know what you are doing!
