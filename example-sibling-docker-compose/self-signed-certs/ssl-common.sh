#!/bin/bash -e
# shellcheck disable=SC2034

# Ensure we have `easyrsa` available
if [ -z "${easyrsa_bin-}" ] || [ ! -x "${easyrsa_bin}" ]; then
    easyrsa_bin="$(command -v easyrsa 2>/dev/null || true)"
    if [ -z "${easyrsa_bin}" ]; then
        easyrsa_dir="$(mktemp -dt easyrsa.XXXXXXXX)"
        easyrsa_url="https://github.com/OpenVPN/easy-rsa/releases/download/v3.1.7/EasyRSA-3.1.7.tgz"
        echo "  - Downloading easy-rsa..."
        (cd "${easyrsa_dir}"; curl -sL "${easyrsa_url}" | tar xz --strip-components=1)
        easyrsa_bin="${easyrsa_dir}/easyrsa"
        # shellcheck disable=SC2064
        trap "rm -rf \"${easyrsa_dir}\"" EXIT
    fi
    export EASYRSA_BATCH=1
    export EASYRSA_KEY_SIZE=4096
fi

# Setup ROOT_PKI path
ROOT_PKI="$(realpath "${OUT}/root")"

# Global expiry settings
CA_EXPIRY_DAYS=3650
CRT_EXPIRY_DAYS=730