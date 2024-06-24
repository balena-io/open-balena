#!/bin/sh

set -ea

CERTS=${CERTS:-/certs}

ls "${CERTS}/self-signed/certs" -alh
if [[ -e "${CERTS}/self-signed/certs/rootCA.pem" ]]; then
    ROOT_CA=$(cat "${CERTS}/self-signed/certs/rootCA.pem" | openssl base64 -A)
    export ROOT_CA
else
    printf "No %s/self-signed/certs/rootCA.pem" "${CERTS}"
fi
if [[ -e "${CERTS}/self-signed/certs/cert.pem" ]]; then
    HAPROXY_CRT=$(cat "${CERTS}/self-signed/certs/cert.pem" | openssl base64 -A)
    export HAPROXY_CRT
else
    printf "No %s/self-signed/certs/cert.pem" "${CERTS}"
fi
ls "${CERTS}/self-signed/keys" -alh

if [[ -e "${CERTS}/self-signed/keys/cert-key.pem" ]]; then
    HAPROXY_KEY=$(cat "${CERTS}/self-signed/keys/cert-key.pem" | openssl base64 -A)
    export HAPROXY_KEY
else
    printf "No %s/self-signed/keys/cert-key.pem" "${CERTS}"
fi
/start-haproxy
