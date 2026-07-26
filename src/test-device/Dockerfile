# https://hub.docker.com/r/qemux/qemu
# https://github.com/qemus/qemu-docker
FROM ghcr.io/qemus/qemu:7.40@sha256:67e22eafd98712306e4d12ee1e760cff8c504b6e5e6d5004c8abed62c7a3f133

RUN apt-get update && apt-get install -y --no-install-recommends \
    minicom \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY balena.sh /usr/sbin/

WORKDIR /balena
