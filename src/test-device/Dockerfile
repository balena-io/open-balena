# https://hub.docker.com/r/qemux/qemu-docker
# https://github.com/qemus/qemu-docker
FROM qemux/qemu-docker:5.10

RUN apt-get update && apt-get install -y --no-install-recommends \
	minicom \
    && rm -rf /var/lib/apt/lists/*

COPY balena.sh /usr/sbin/

WORKDIR /balena
