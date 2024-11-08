# Our AIO builder docker file
FROM debian:12

RUN mkdir /repo

RUN dpkg --add-architecture arm64 \
    && apt-get update \
    && apt-get install -yq \
    autoconf \
    bc \
    binfmt-support \
    bison \
    bsdextrautils \
    build-essential \
    cpio \
    debootstrap \
    debhelper \
    device-tree-compiler \
    dosfstools \
    dwarves \
    fakeroot \
    flex \
    gcc-aarch64-linux-gnu \
    genext2fs \
    git \
    kmod \
    kpartx \
    libconfuse-common \
    libconfuse-dev \
    libelf-dev \
    libgnutls28-dev \
    libncurses-dev \
    libssl-dev \
    libssl-dev:arm64 \
    lvm2 \
    mtools \
    parted \
    pkg-config \
    python3-dev \
    python3-pyelftools \
    python3-setuptools \
    qemu-utils \
    qemu-user-static \
    rsync \
    swig \
    unzip \
    uuid-dev \
    wget \
    xz-utils \
    zstd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Note the above has the workaround added mentioned at https://github.com/torvalds/linux/commit/e2c318225ac13083cdcb4780cdf5b90edaa8644d
