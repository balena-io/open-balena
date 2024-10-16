FROM ubuntu:24.04

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v19.2.0

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
    && wget -q "https://github.com/balena-io/balena-cli/releases/download/${BALENA_CLI_VERSION}/balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip" \
    && unzip -q "balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip" \
    && rm -rf "balena-cli-${BALENA_CLI_VERSION}-linux-${arch}-standalone.zip"

ENV PATH=/opt/balena-cli:${PATH}

COPY functions balena.sh /usr/sbin/

WORKDIR /balena

CMD /usr/sbin/balena.sh
