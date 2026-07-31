# https://hub.docker.com/r/qemux/qemu
# https://github.com/qemus/qemu-docker
FROM ghcr.io/qemus/qemu:7.42@sha256:1d82a357afe71883d9bbeda2ca3dce44a64ef1f3f11475fe901dbe265a957e8c

RUN apt-get update && apt-get install -y --no-install-recommends \
    minicom \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY balena.sh /usr/sbin/

WORKDIR /balena
