# openBalena on balena
> https://www.balena.io/open/docs/getting-started/

## ToC
* [deploy](#deploy)
* [operate](#operate)


## deploy
> push composition to a suitable x86-64 device in local mode (e.g. Intel NUC)

```sh
DNS_TLD=openbalena.local

balena push ${uuid}.local \
  --env COMMON_REGION=us-east-1 \
  --env DNS_TLD=${DNS_TLD} \
  --env mdns:MDNS_TLD=${DNS_TLD} \
  --env ORG_UNIT=openBalena \
  --env SUPERUSER_EMAIL=admin@${DNS_TLD}
```


## operate
> (e.g.) extract credentials and show connected devices from a macOS client

```sh
set -a

mkdir .balena

tmpenv=$(mktemp)

DOCKER_HOST=${uuid}.local

BALENARC_BALENA_URL=${balena_device_uuid}.${DNS_TLD}

cert_manager=$(docker ps --filter "name=cert-manager" --format "{{.ID}}")
docker cp ${cert_manager}:/certs/private/ca-bundle.${balena_device_uuid}.${DNS_TLD}.pem .balena/
NODE_EXTRA_CA_CERTS="$(pwd)/.balena/ca-bundle.${balena_device_uuid}.${DNS_TLD}.pem"

api=$(docker ps --filter "name=api" --format "{{.ID}}")
docker cp ${api}:/etc/docker.env .balena/
grep -E '^SUPERUSER_|^DNS_TLD=' .balena/docker.env > ${tmpenv}
source ${tmpenv}

# (e.g.) macOS
sudo security add-trusted-cert -d \
  -r trustAsRoot \
  -k /Library/Keychains/System.keychain \
  ${NODE_EXTRA_CA_CERTS}

balena login --credentials \
  --email "${SUPERUSER_EMAIL}" \
  --password "${SUPERUSER_PASSWORD}"

balena devices


unset BALENARC_BALENA_URL
unset NODE_EXTRA_CA_CERTS
unset DOCKER_HOST

rm -rf ${tmpenv} .balena
```
