#!/bin/sh

OPENBALENA_CERT=/etc/ssl/private/open-balena.pem
mkdir -p "$(dirname "${OPENBALENA_CERT}")"

if [ -f "/certs/open-balena.pem" ]; then
    echo "Using certificate from cert-provider..."
    cp /certs/open-balena.pem "${OPENBALENA_CERT}"
else
    echo "Building certificate from environment variables..."
    (
        echo "${BALENA_HAPROXY_CRT}" | base64 -d
        echo "${BALENA_HAPROXY_KEY}" | base64 -d
        echo "${BALENA_ROOT_CA}" | base64 -d
    ) > "${OPENBALENA_CERT}"
fi

haproxy -f /usr/local/etc/haproxy/haproxy.cfg -W &
HAPROXY_PID=$!

while true; do
    inotifywait -r -e create -e modify -e delete /certs
    
    if [ -f "/certs/open-balena.pem" ]; then
        echo "Updating certificate from cert-provider..."
        cp /certs/open-balena.pem "${OPENBALENA_CERT}"
    fi
    
    echo "Certificate change detected. Reloading..."
    kill -SIGUSR2 $HAPROXY_PID
    sleep 1;
done
