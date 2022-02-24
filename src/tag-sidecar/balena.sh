#!/usr/bin/env bash

set -eua

[[ $VERBOSE =~ on|On|Yes|yes|true|True ]] && set -x

[[ $ENABLED == 'true' ]] || exit

curl_with_opts() {
    curl --fail --silent --retry 3 --connect-timeout 3 --compressed "$@"
}

get_aws_meta() {
    if [[ $1 =~ ^.*/$ ]]; then
        for key in $(curl_with_opts "$1"); do
            get_aws_meta "$1${key}"
        done
    else
        echo "$(echo "$1" | cut -c41-);$(curl_with_opts "$1" | tr '\n' ',')"
    fi
}

which curl || apk add curl --no-cache
which jq || apk add jq --no-cache

device_id="$(curl_with_opts \
  "${BALENA_API_URL}/v6/device?\$filter=uuid%20eq%20'${BALENA_DEVICE_UUID}'" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${BALENA_API_KEY}" | jq -r .d[].id)"

for key in $(curl_with_opts http://169.254.169.254/latest/meta-data \
  | grep -Ev 'iam|metrics|identity-credentials|network|events'); do
    for kv in $(get_aws_meta "http://169.254.169.254/latest/meta-data/${key}"); do
        tag_key="$(echo "${kv}" | awk -F';' '{print $1}')"
        value="$(echo "${kv}" | awk -F';' '{print $2}')"

        curl_with_opts "${BALENA_API_URL}/v6/device_tag" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer ${BALENA_API_KEY}" \
          --data "{\"device\":\"${device_id}\",\"tag_key\":\"${tag_key}\",\"value\":\"${value}\"}"
    done
done
