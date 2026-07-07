FROM ubuntu:26.04@sha256:b7f48194d4d8b763a478a621cdc81c27be222ba2206ca3ca6bc42b49685f3d9e

# renovate: datasource=github-releases depName=balena-io/balena-cli
ARG BALENA_CLI_VERSION=v25.1.10

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
