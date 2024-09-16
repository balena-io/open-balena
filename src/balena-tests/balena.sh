#!/usr/bin/env bash

# shellcheck disable=SC2034,SC1090
set -aeu

read -ra curl_opts <<<'--retry 3 --fail'
if [[ $VERBOSE =~ on|On|Yes|yes|true|True ]]; then
    set -x
    curl_opts+=('--verbose')
else
    curl_opts+=('--silent')
fi

# shellcheck disable=SC1091
source /usr/sbin/functions

function remove_test_assets() {
    rm -rf /balena/config.json \
      "${GUEST_IMAGE}" \
      "${GUEST_IMAGE%.*}.ready" \
      "${tmpbuild:-}" \
      /tmp/*.img
}

function remove_update_lock() {
    rm -f /tmp/balena/updates.lock
}

function cleanup() {
   shutdown_dut
   remove_test_assets
   remove_update_lock

   # crash loop backoff
   sleep "$(( (RANDOM % 5) + 5 ))s"
}
trap 'cleanup' EXIT

function shutdown_dut() {
    local balena_device_uuid
    balena_device_uuid="$(cat </balena/config.json | jq -r .uuid)"

    if [[ -n "${balena_device_uuid:-}" ]]; then
        with_backoff balena device "${balena_device_uuid}"
        if ! with_backoff balena device shutdown -f "${balena_device_uuid}"; then
            echo 'DUT failed to shutdown properly'
        fi
    fi
}

function set_update_lock {
    if [[ -n "${BALENA_SUPERVISOR_ADDRESS:-}" ]] && [[ -n "${BALENA_SUPERVISOR_API_KEY:-}" ]]; then
        while [[ $(curl "${curl_opts[@]}" "${BALENA_SUPERVISOR_ADDRESS}/v1/device?apikey=${BALENA_SUPERVISOR_API_KEY}" \
          -H "Content-Type: application/json" | jq -r '.update_pending') == 'true' ]]; do

            curl "${curl_opts[@]}" "${BALENA_SUPERVISOR_ADDRESS}/v1/device?apikey=${BALENA_SUPERVISOR_API_KEY}" \
              -H "Content-Type: application/json" | jq -r

            sleep "$(( (RANDOM % 3) + 3 ))s"
        done
        sleep "$(( (RANDOM % 5) + 5 ))s"

        # https://www.balena.io/docs/learn/deploy/release-strategy/update-locking/
        lockfile /tmp/balena/updates.lock
    fi
}

function update_ca_certificates() {
    # only set CA bundle if using private certificate chain
    if [[ -e "${CERTS}/ca-bundle.pem" ]]; then
        if [[ "$(readlink -f "${CERTS}/${TLD}-chain.pem")" =~ \/private\/ ]]; then
            mkdir -p /usr/local/share/ca-certificates
            cat <"${CERTS}/ca-bundle.pem" > /usr/local/share/ca-certificates/balenaRootCA.crt
            # shellcheck disable=SC2034
            CURL_CA_BUNDLE=${CURL_CA_BUNDLE:-${CERTS}/ca-bundle.pem}
            NODE_EXTRA_CA_CERTS=${NODE_EXTRA_CA_CERTS:-${CURL_CA_BUNDLE}}
            # (TBC) refactor to use NODE_EXTRA_CA_CERTS instead of ROOT_CA
            # https://github.com/balena-io/e2e/blob/master/conf.js#L12-L14
            # https://github.com/balena-io/e2e/blob/master/Dockerfile#L82-L83
            # ... or
            # https://thomas-leister.de/en/how-to-import-ca-root-certificate/
            # https://github.com/puppeteer/puppeteer/issues/2377
            ROOT_CA=${ROOT_CA:-$(cat <"${NODE_EXTRA_CA_CERTS}" | openssl base64 -A)}
        else
            rm -f /usr/local/share/ca-certificates/balenaRootCA.crt
            unset NODE_EXTRA_CA_CERTS CURL_CA_BUNDLE ROOT_CA
        fi
        update-ca-certificates
    fi
}

function wait_for_api() {
    while ! curl "${curl_opts[@]}" "https://api.${DNS_TLD}/ping"; do
        echo 'waiting for API...'
        sleep "$(( (RANDOM % 5) + 5 ))s"
    done
}

function open_balena_login() {
    while ! balena login --credentials \
      --email "${SUPERUSER_EMAIL}" \
      --password "${SUPERUSER_PASSWORD}"; do
        echo 'waiting for auth...'
        sleep "$(( (RANDOM % 5) + 5 ))s"
    done
}

function create_fleet() {
    if ! balena fleet "${TEST_FLEET}"; then
        # wait for API to load DT contracts
        while ! balena fleet create "${TEST_FLEET}" --type "${DEVICE_TYPE}"; do
            echo 'waiting for device types...'
            sleep "$(( (RANDOM % 5) + 5 ))s"
        done

        # FIXME: on openBalena 'balena devices supported' always returns empty list
        balena devices supported
    fi
}

function download_os_image() {
    if ! [[ -s "$GUEST_IMAGE" ]]; then
        with_backoff wget -qO /tmp/balena.zip \
          "${BALENA_API_URL}/download?deviceType=${DEVICE_TYPE}&version=${OS_VERSION:1}&fileType=.zip"

        unzip -oq /tmp/balena.zip -d /tmp

        cat <"$(find /tmp/ -type f -name '*.img' | head -n 1)" >"${GUEST_IMAGE}"

        rm /tmp/balena.zip
    fi
}

function configure_virtual_device() {
    while ! [[ -s "$GUEST_IMAGE" ]]; do sleep "$(( (RANDOM % 5) + 5 ))s"; done

    if ! [[ -s /balena/config.json ]]; then
        balena_device_uuid="$(openssl rand -hex 16)"

        with_backoff balena device register "${TEST_FLEET}" \
          --uuid "${balena_device_uuid}"

        with_backoff balena config generate \
          --version "${OS_VERSION:1}" \
          --device "${balena_device_uuid}" \
          --network ethernet \
          --appUpdatePollInterval 10 \
          --dev \
          --output /balena/config.json
    fi
    cat </balena/config.json | jq -re

    with_backoff balena os configure "${GUEST_IMAGE}" \
      --fleet "${TEST_FLEET}" \
      --version "${OS_VERSION#v}" \
      --config-network ethernet \
      --config /balena/config.json

    touch "${GUEST_IMAGE%.*}.ready"
}

function check_device_status() {
    if [[ -e /balena/config.json ]]; then
        balena_device_uuid="$(cat </balena/config.json | jq -r .uuid)"

        if [[ -n $balena_device_uuid ]]; then
            is_online="$(balena devices --json --fleet "${TEST_FLEET}" \
              | jq -r --arg uuid "${balena_device_uuid}" '.[] | select(.uuid==$uuid).is_online == true')"

            if [[ $is_online =~ true ]]; then
                return 0
            else
                return 1
            fi
        fi
    fi
}

function wait_for_device() {
    while ! check_device_status; do sleep "$(( (RANDOM % 5) + 5 ))s"; done
}

function registry_auth() {
    if [[ -n "${REGISTRY_USER:-}" ]] && [[ -n "${REGISTRY_PASS:-}" ]]; then
        with_backoff docker login -u "${REGISTRY_USER}" -p "${REGISTRY_PASS}"

        # shellcheck disable=SC2016
        printf '{"https://index.docker.io/v1/": {"username":"%s", "password":"$s"}}' \
          "${REGISTRY_USER}" "${REGISTRY_PASS}" | jq -r > ~/.balena/secrets.json
    fi
}

function deploy_release() {
    tmpbuild="$(mktemp -d)"
    pushd "${tmpbuild}"

    echo 'FROM hello-world' >Dockerfile

    while ! balena deploy \
      --ca "${DOCKER_CERT_PATH}/ca.pem" \
      --cert "${DOCKER_CERT_PATH}/cert.pem" \
      --key "${DOCKER_CERT_PATH}/key.pem" \
      "${TEST_FLEET}"; do

        sleep "$(( (RANDOM % 5) + 5 ))s"
    done
    popd
}

function get_releases() {
      with_backoff balena releases --json "${TEST_FLEET}"
}

function get_release_commit() {
      get_releases | jq -re \
        'select((.[].status=="success")
        and (.[].is_invalidated==false)
        and (.[].is_final==true)
        and (.[].release_type=="final"))[0].commit'
}

function get_release_id() {
      get_releases | jq -re \
        'select((.[].status=="success")
        and (.[].is_invalidated==false)
        and (.[].is_final==true)
        and (.[].release_type=="final"))[0].id'
}

function supervisor_update_target_state() {
    local balena_device_uuid
    balena_device_uuid="$(cat </balena/config.json | jq -r .uuid)"

    if [[ -n "${balena_device_uuid:-}" ]]; then
        while ! curl "${curl_opts[@]}" "https://api.${DNS_TLD}/supervisor/v1/update" \
          --header "Content-Type: application/json" \
          --header "Authorization: Bearer $(cat <~/.balena/token)" \
          --data "{\"uuid\": \"${balena_device_uuid}\", \"data\": {\"force\": true}}"; do

            sleep "$(( (RANDOM % 5) + 5 ))s"
        done
    fi
}

function check_running_release() {
    local balena_device_uuid
    balena_device_uuid="$(cat </balena/config.json | jq -r .uuid)"

    local should_be_running_release
    should_be_running_release="$(get_release_commit)"
    [[ -z "$should_be_running_release" ]] && false

    if [[ -n "${balena_device_uuid:-}" ]]; then
        while ! [[ $(balena device "${balena_device_uuid}" | grep -E ^COMMIT | awk '{print $2}') =~ ${should_be_running_release} ]]; do
            running_release_id="$(balena device "${balena_device_uuid}" | grep -E ^COMMIT | awk '{print $2}')"
            printf 'please wait, device %s should be running %s, but is still running %s...\n' \
              "${balena_device_uuid}" \
              "${should_be_running_release}" \
              "${running_release_id}"

            sleep "$(( (RANDOM % 5) + 5 ))s"
        done
    fi
}

function get_os_version() {
    local BALENARC_BALENA_URL
    BALENARC_BALENA_URL="${BALENA_API_URL//https:\/\/api\./}"

    local os_version
    os_version=${OS_VERSION:-$(with_backoff balena os versions "${DEVICE_TYPE}" | head -n 1)}
    echo "${os_version}"
}

function upload_release_asset() {
    if [[ "${RELEASE_ASSETS_T:-}" =~ true ]]; then
        local release_id
        release_id=${1:-1}
        release_asset="$(find / -type f -name '*.png' | head -n 1)"

        curl "${curl_opts[@]}" "https://api.${DNS_TLD}/resin/release_asset" \
          --header "Authorization: Bearer $(cat <~/.balena/token)" \
          --form "asset=@${release_asset}" \
          --form "release=${release_id}" \
          --form "asset_key=$((RANDOM))-$(basename "${release_asset}")" \
          | jq -re .asset.href \
          | xargs curl "${curl_opts[@]}" -o "/tmp/$((RANDOM))-$(basename "${release_asset}")"
    fi
}

# --- main
if [[ "${PRODUCTION_MODE:-}" =~ true ]]; then
    exit
fi

if [[ -n "${BALENA_DEVICE_UUID:-}" ]]; then
    # prepend the device UUID if running on balenaOS
    TLD="${BALENA_DEVICE_UUID}.${DNS_TLD}"
else
    TLD="${DNS_TLD}"
fi

BALENA_API_URL=${BALENA_API_URL:-https://api.balena-cloud.com}
BALENARC_BALENA_URL="${DNS_TLD}"
CERTS=${CERTS:-/certs}
CONF=${CONF:-/balena/${TLD}.env}
DEVICE_TYPE=${DEVICE_TYPE:-generic-amd64}
GUEST_DISK_SIZE=${GUEST_DISK_SIZE:-8}
GUEST_IMAGE=${GUEST_IMAGE:-/balena/balena.img}
OS_VERSION="$(get_os_version)"
TEST_FLEET=${TEST_FLEET:-test-fleet}

# wait here until global config is ready
until [[ -s "$CONF" ]]; do
    echo 'waiting for config...'
    sleep "$(( (RANDOM % 5) + 5 ))s"
done
source "${CONF}"

# wait her until we have valid login credentials
until [[ -n "${SUPERUSER_EMAIL:-}" ]] && [[ -n "${SUPERUSER_PASSWORD:-}" ]]; do
    echo 'waiting for credentials...'
    sleep "$(( (RANDOM % 5) + 5 ))s"
    source "${CONF}"
done

update_ca_certificates  # ensure self-signed root CA certificate(s) trust

registry_auth  # optionally authenticate with DockerHub (rate-limiting)

wait_for_api  # spin here until the API is responding

balena whoami || open_balena_login  # spin here until authenticated

create_fleet  # spin here until the fleet is created

# critical section
set_update_lock
download_os_image
configure_virtual_device
deploy_release
upload_release_asset "$(get_release_id)"  # upload an additional asset to a release
remove_update_lock
# .. end

wait_for_device  # spin here until test-device comes online
check_running_release  # .. and ensure the device is running our release
