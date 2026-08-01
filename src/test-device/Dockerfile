# https://hub.docker.com/r/qemux/qemu
# https://github.com/qemus/qemu-docker
FROM ghcr.io/qemus/qemu:7.42@sha256:73f85c89a2d5210fa2419fe4e725079914dfd34163364100aa077b639229850a

RUN apt-get update && apt-get install -y --no-install-recommends \
    minicom \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY balena.sh /usr/sbin/

WORKDIR /balena
