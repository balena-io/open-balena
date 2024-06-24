# usage:
# docker build -t openbalena-airgapped-contracts

FROM --platform=linux/amd64 amd64/alpine:3.15
RUN apk add --no-cache curl
WORKDIR /contracts
RUN curl -LJO https://github.com/aivero/balena-io-contracts/archive/refs/heads/master.zip