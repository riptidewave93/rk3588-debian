# rk3588-debian

## Developer Guidelines
- Start every new request by scanning the relevant code path before implementing.
- Keep this CLAUDE.md up to date after every request with useful context.
- Never make assumptions — ask the user for clarification if not at least 95% confident in the request.
- After every implementation, review your own work to ensure it meets requirements and is valid/functional.
- When writing in known coding languages (Python, Go, etc.), write and run unit tests for whatever was implemented. Tests must pass. Always tell the user which specific tests were written so they can verify scope.

## Project Overview
Build system for creating Debian 12 or Ubuntu 24.04 images for RK3588(s)-based ARM64 boards. Uses Docker for the build environment and produces bootable disk images with U-Boot, kernel, ATF, and OP-TEE.

## Supported Boards
- Pine64 QuartzPro64 (`rk3588-quartzpro64`)
- Radxa Rock 5A (`rk3588s-rock-5a`)
- Radxa Rock 5B Plus (`rk3588-rock-5b-plus`)

## Architecture
- **Makefile** - Entry point. Targets: `build` (full image), `bootloader` (U-Boot + kernel debs only), `clean`, `distclean`, `mountclean`
- **Dockerfile** - Debian 12 container with all cross-compilation and packaging tools
- **scripts/vars.sh** - Central configuration: URLs, versions, toolchain paths, distro settings, device list
- **scripts/0X_*.sh** - Numbered orchestration scripts run sequentially by Make:
  - `00_prereq_check.sh` - Validates host dependencies
  - `01_pre_docker.sh` - Builds Docker image, sets up BuildEnv directory
  - `02_download_dependencies.sh` - Downloads toolchains and source archives
  - `03_docker.sh` - Runs Docker containers to build ATF, OP-TEE, U-Boot, kernel, disk images, and optionally debootstrap
  - `04_post_docker.sh` - Final packaging into compressed output images
- **scripts/docker/*.sh** - Scripts that run inside Docker containers (build_atf, build_optee, build_uboot, build_kernel, build_image, run_debootstrap, run_package_final)
- **overlay/** - Custom files overlaid onto upstream sources:
  - `overlay/u-boot/` - U-Boot device trees, configs, board support files
  - `overlay/kernel/` - Kernel defconfig
  - `overlay/filesystem/` - Root filesystem overlays (cloud-init, locale, etc.)

## Host Requirements
- **Linux x86_64**: `docker-ce losetup curl sudo make`
- **macOS (ARM64, via OrbStack or Docker Desktop)**: `docker curl make`
- `wget` is NOT required on the host — all host downloads use `curl -L -o`
- `wget` is still used inside Docker containers (installed via apt in Dockerfile and 001-bootstrap)
- `qemu-user-static` and `binfmt_misc` are NOT required on any platform

## Key Variables (scripts/vars.sh)
- `host_os` - auto-detected: `linux` or `macos`
- `host_arch` - auto-detected: `x86_64` or `aarch64`
- `docker_tag` - native-arch Docker image for compilation
- `docker_tag_arm64` - arm64 Docker image for debootstrap (same as `docker_tag` on arm64 hosts)
- `docker_tty` - `-t` when TTY attached, empty otherwise (avoids OrbStack `-t` + `/dev` bug)
- `DISTRO` env var selects debian (default) or ubuntu
- `BOOTLOADER_ONLY` env var skips rootfs/debootstrap steps
- Source versions are pinned by commit hash/tag in URL variables
- Toolchains: ARM GNU 14.2 (both aarch64 and arm32), auto-selected for host arch

## Build Outputs
- `./output/` - Compressed disk images, kernel debs, U-Boot binaries
- `./BuildEnv/` - Intermediate build artifacts (gitignored)
- `./downloads/` - Cached source downloads (gitignored)

## Cross-Platform Support (Linux x86_64 + macOS ARM64)
- Toolchain URLs use `${host_arch}` to auto-select native variants (e.g., `arm-gnu-toolchain-14.2.rel1-{x86_64|aarch64}-aarch64-none-linux-gnu`)
- Compilation containers (ATF, OP-TEE, U-Boot, kernel) run at native host arch for best performance
- Debootstrap runs single-stage native ARM64 (no `--foreign`, no `qemu-aarch64-static` copy, no `--second-stage`)
- On x86_64: two Docker images (`builder` native x86 for compilation, `builder-arm64` for debootstrap via `--platform linux/arm64`)
- On aarch64: one Docker image (`builder`) used for everything — all containers run natively
- `modprobe loop` only runs on Linux; `modprobe binfmt_misc` removed entirely
- `losetup`, `mountpoint` safety checks are Linux-only; on macOS, Docker's VM handles loop devices
- All `docker run` commands use `-i ${docker_tty}` instead of `-it` for OrbStack compatibility

## OrbStack Compatibility (macOS)
- OrbStack v1.8.0+ fixed loopback devices in privileged containers
- OrbStack v1.10.0+ fixed loop device visibility
- OrbStack v1.11.4+ fixed `-v /dev:/dev` with `-t` flag (issue #2018)
- OrbStack v2.0.3+ fixed `/dev` bind mounting broadly
- The `-it` → `-i ${docker_tty}` change avoids the TTY + `/dev` interaction bug on older versions

## Kernel Build Notes
- `build_kernel.sh` runs `make bindeb-pkg` for debs, then builds DTBs per-board via `make rockchip/${board}.dtb`
- Do NOT use `make dtbs` — it builds ALL arch/arm64 DTBs including broken upstream ones (e.g., Qualcomm sc7180-trogdor)
- Standalone DTBs for each `supported_devices` entry are copied to `${build_path}/kernel/`

## Shell Scripting Conventions
- All scripts source `vars.sh` for shared config
- `debug_msg` and `error_msg` helper functions for colored output
- Scripts use `set -e` for fail-fast behavior
- Docker scripts receive toolchain paths and build config via environment variables
- Host downloads use `curl -L -o` (not `wget`); container scripts still use `wget` (installed via apt)
