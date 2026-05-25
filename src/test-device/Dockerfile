# https://hub.docker.com/r/qemux/qemu
# https://github.com/qemus/qemu-docker
FROM ghcr.io/qemus/qemu:7.30@sha256:d987eaf929bef5aa4e813da065b764773e8daaaac0afadf55fd3f38173793834

RUN apt-get update && apt-get install -y --no-install-recommends \
    minicom \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY balena.sh /usr/sbin/

WORKDIR /balena
