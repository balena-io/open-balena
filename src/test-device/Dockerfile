# https://hub.docker.com/r/qemux/qemu
# https://github.com/qemus/qemu-docker
FROM ghcr.io/qemus/qemu:7.48@sha256:4e8fccb01a992e89d4ca2ed84c12676c196cbed7fb7fc24d18eb91911c64c83b

RUN apt-get update && apt-get install -y --no-install-recommends \
    minicom \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY balena.sh /usr/sbin/

WORKDIR /balena
