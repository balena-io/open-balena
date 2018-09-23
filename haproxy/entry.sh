#!/bin/bash -eu

HAPROXY_CHAIN=/etc/ssl/private/open-balena.pem
mkdir -p "$(dirname "${HAPROXY_CHAIN}")"
(
    echo "${BALENA_HAPROXY_CRT}" | base64 -d
    echo "${BALENA_HAPROXY_KEY}" | base64 -d
    echo "${BALENA_ROOT_CA}" | base64 -d
) > "${HAPROXY_CHAIN}"
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg