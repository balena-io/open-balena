FROM ubuntu:26.04@sha256:53958ec7b67c2c9355df922dd08dbf0360611f8c3cdb656875e81873db9ffdba

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v25.1.6

RUN apt-get update && apt-get install -y --no-install-recommends \
	bash \
	ca-certificates \
	curl \
	jq \
	openssl \
	procmail \
	qemu-utils \
	unzip \
	wget \
    && rm -rf /var/lib/apt/lists/*

# https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
RUN curl -fsSL https://get.docker.com | sh

WORKDIR /opt

RUN set -x; arch=$(uname -m | sed 's/86_64/64/g') \
    && wget -qO- "https://github.com/balena-io/balena-cli/releases/download/${BALENA_CLI_VERSION}/balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.tar.gz" | tar -xzf -

ENV PATH=/opt/balena/bin:${PATH}

COPY balena.sh /usr/sbin/

WORKDIR /balena

CMD /usr/sbin/balena.sh
