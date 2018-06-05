#!/bin/sh

CA_B64="$BALENA_ROOT_CA"
CA_FILE=/etc/ssl/private/root.chain.pem

mkdir -p $(dirname "$CA_FILE")
echo "$CA_B64" | base64 -d >"$CA_FILE"

exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg
