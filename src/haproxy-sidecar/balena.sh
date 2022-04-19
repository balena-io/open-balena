#!/usr/bin/env bash

set -ea

[[ $VERBOSE =~ on|On|Yes|yes|true|True ]] && set -x

which curl || apk add curl --no-cache
which jq || apk add jq --no-cache

if docker inspect "${BALENA_APP_UUID}_default" --format "{{.ID}}"; then
    network="${BALENA_APP_UUID}_default"
elif docker inspect "${BALENA_APP_ID}_default" --format "{{.ID}}"; then
    network="${BALENA_APP_ID}_default"
else
    network=open-balena_default
fi

# shellcheck disable=SC2153
for alias in ${ALIASES//,/ }; do
    hostname="${alias}.${DNS_TLD}"
    aliases="--alias ${hostname} ${aliases}"
done

while true; do
    if [[ -n $BALENA_SUPERVISOR_ADDRESS ]] && [[ -n $BALENA_SUPERVISOR_API_KEY ]]; then
        while [[ "$(curl --silent --retry 3 --fail \
          "${BALENA_SUPERVISOR_ADDRESS}/v1/device?apikey=${BALENA_SUPERVISOR_API_KEY}" \
          -H "Content-Type:application/json" | jq -r '.update_pending')" =~ true ]]; do
            sleep "$(( (RANDOM % 3) + 3 ))s"
        done
        sleep "$(( (RANDOM % 5) + 5 ))s"
    fi

    while [[ "$(docker ps \
      --filter "name=haproxy" \
      --filter "expose=1936/tcp" \
      --filter "status=running" \
      --filter "network=${network}" \
      --format "{{.ID}}")" == '' ]]; do
        sleep "$(( (RANDOM % 3) + 3 ))s"
    done

    haproxy="$(docker ps \
      --filter "name=haproxy" \
      --filter "expose=1936/tcp" \
      --filter "status=running" \
      --filter "network=${network}" \
      --format "{{.ID}}")"

    if ! [[ $restarted == "${haproxy}" ]]; then
        docker network disconnect "${network}" "${haproxy}"

        # shellcheck disable=SC2086
        docker network connect --alias haproxy ${aliases} "${network}" "${haproxy}"

        docker restart "${haproxy}"

        restarted="${haproxy}"
    fi

    sleep "$(( (RANDOM % 15) + 15 ))s"
done
