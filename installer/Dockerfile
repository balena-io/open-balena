FROM ubuntu:bionic AS docker

RUN apt-get update \
    && apt-get install -y \
    ca-certificates \
    curl \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENV DOCKERVERSION=18.03.1-ce
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

RUN curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

FROM alpine AS scripts

WORKDIR /scripts
COPY ./installer/scripts/* ./
RUN chmod +x ./*

FROM node:8.12-slim

COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker /usr/local/bin/docker-compose /usr/local/bin/docker-compose
COPY --from=scripts /scripts/entry.sh /entry.sh
COPY --from=scripts /scripts/install.sh /usr/sbin/balena-install

COPY ./haproxy/* /haproxy/
COPY ./installer/compose/* /deploy/

ENTRYPOINT [ "/entry.sh" ]
CMD [ "balena-install", "up", "-d" ]