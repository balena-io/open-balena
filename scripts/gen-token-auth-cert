#!/bin/bash -e

usage() {
  echo "usage: $0 COMMON_NAME [OUT]"
  echo
  echo "  COMMON_NAME   the domain name the certificate is valid for, eg. example.com"
  echo "  OUT           path to output directory generated files will be placed in"
  echo
}

if [ -z "$1" ]; then
  usage
  exit 1
fi

CMD="$(realpath "$0")"
DIR="$(dirname "${CMD}")"

CN="$1"
OUT="$(realpath "${2:-.}")"

# shellcheck source=scripts/ssl-common.sh
source "${DIR}/ssl-common.sh"

CERT_DIR="${OUT}/api"
CERT_FILE="${CERT_DIR}/api.${CN}"

keyid() {
  # NodeJS is installed as `nodejs` in some distros, `node` in others.
  node_bin="$(command -v nodejs 2>/dev/null || command -v node 2>/dev/null || true)"
  if [ -z "$node_bin" ]; then
    echo >&2 'NodeJS is required but not installed. Aborting.'
    exit 1
  fi
  # Recent Node versions complain about `new Buffer()` being deprecated
  # but the alternative is not available to older versions. Silence the
  # warning but use the deprecated form to allow greater compatibility.
  "$node_bin" --no-deprecation "${DIR}/_keyid.js" "$1"
}

JWT_CRT="${CERT_FILE}.crt"
JWT_KEY="${CERT_FILE}.pem"
JWT_KID="${CERT_FILE}.kid"

if [ ! -f $JWT_CRT ] || [ ! -f $JWT_KEY ] || [ ! -f $JWT_KID ]; then
  rm -f $JWT_CRT $JWT_KEY $JWT_KID
  mkdir -p "${CERT_DIR}"
  openssl ecparam -name prime256v1 -genkey -noout -out "${JWT_KEY}" 2>/dev/null
  openssl req -x509 -new -nodes -days "${CRT_EXPIRY_DAYS}" -key "${JWT_KEY}" -subj "/CN=api.${CN}" -out "${JWT_CRT}" 2>/dev/null
  openssl ec -in "${JWT_KEY}" -pubout -outform DER -out "${CERT_FILE}.der" 2>/dev/null
  keyid "${CERT_FILE}.der" >"${JWT_KID}"
  rm "${CERT_FILE}.der"
fi
