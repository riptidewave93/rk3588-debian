.DEFAULT_GOAL := build
CONTAINER_NAME = rk3588-builder:builder
CONTAINER_NAME_ARM64 = rk3588-builder:builder-arm64

setup:
	@if [ "$$(uname -s)" = "Linux" ]; then \
		sudo modprobe loop; \
	fi

build: setup
	@set -e;	\
	for file in `ls ./scripts/[0-99]*.sh`;	\
	do					\
		bash $${file};			\
	done					\

bootloader: setup
	@set -e;	\
	export BOOTLOADER_ONLY=true; \
	for file in `ls ./scripts/[0-99]*.sh`;	\
	do					\
		bash $${file};			\
	done					\

clean: mountclean
	sudo rm -rf $(CURDIR)/BuildEnv; \
	docker ps -a | awk '{ print $$1,$$2 }' | grep $(CONTAINER_NAME) | awk '{print $$1 }' | xargs -I {} docker rm {}; \
	docker ps -a | awk '{ print $$1,$$2 }' | grep $(CONTAINER_NAME_ARM64) | awk '{print $$1 }' | xargs -I {} docker rm {} 2>/dev/null || true;

distclean: clean
	docker rmi $(CONTAINER_NAME) -f 2>/dev/null || true; \
	docker rmi $(CONTAINER_NAME_ARM64) -f 2>/dev/null || true; \
	rm -rf $(CURDIR)/downloads $(CURDIR)/output

mountclean:
	@if [ "$$(uname -s)" = "Linux" ]; then \
		sudo umount $(CURDIR)/BuildEnv/rootfs/boot/efi 2>/dev/null || true; \
		sudo umount $(CURDIR)/BuildEnv/rootfs 2>/dev/null || true; \
		sudo losetup -D; \
	fi
