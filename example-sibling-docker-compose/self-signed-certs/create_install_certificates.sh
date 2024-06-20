#!/bin/sh
# usage: 
set -e

usage() {
  echo "usage: $0 DOMAIN "
  echo
  echo "  DOMAIN  the domain name generate certificates for e.g. example.com"
  echo
  echo "  The certificates will also be valid for .local e.g. example.local"
}

if [ -z "$1" ]; then
  usage
  exit 1
fi

SCRIPT_LOCATION=$(dirname "$0")

SERVER_DOMAIN=$1
SERVER_DOMAIN_LOCAL="${SERVER_DOMAIN%.*}.local"

printf "Identified the SERVER_DOMAIN: %s\nand generated the mdns equivalent: %s\n\nWill create certificates.\n\n" "$SERVER_DOMAIN" "$SERVER_DOMAIN_LOCAL"

"$SCRIPT_LOCATION"/gen-root-ca "$SERVER_DOMAIN" "$SCRIPT_LOCATION"
"$SCRIPT_LOCATION"/gen-root-cert "$SERVER_DOMAIN" "$SCRIPT_LOCATION"

rm -rf "$SCRIPT_LOCATION/certs" || true
rm -rf "$SCRIPT_LOCATION/keys" || true
mkdir -p "$SCRIPT_LOCATION/certs" || true
mkdir -p "$SCRIPT_LOCATION/keys" || true
cp "$SCRIPT_LOCATION/root/issued/$SERVER_DOMAIN.crt" "$SCRIPT_LOCATION/certs/cert.pem"
cp "$SCRIPT_LOCATION/root/ca.crt" "$SCRIPT_LOCATION/certs/rootCA.pem"
cp "$SCRIPT_LOCATION/root/private/$SERVER_DOMAIN.key" "$SCRIPT_LOCATION/keys/cert-key.pem"
tree "$SCRIPT_LOCATION"