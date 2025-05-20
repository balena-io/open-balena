# https://hub.docker.com/r/qemux/qemu
# https://github.com/qemus/qemu-docker
FROM ghcr.io/qemus/qemu:6.20

RUN apt-get update && apt-get install -y --no-install-recommends \
	minicom \
    && rm -rf /var/lib/apt/lists/*

COPY balena.sh /usr/sbin/

WORKDIR /balena
