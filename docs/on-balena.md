# openBalena on balena
> https://www.balena.io/open/docs/getting-started/

## deploy
> push composition to a suitable x86-64 device in local mode (e.g. Intel NUC)

```sh
uuid=$(printf "results:\n$(sudo balena scan)" \
  | yq e '.results[] | select(.osVariant=="development").host' - \
  | awk -F'.' '{print $1}' | head -n 1) \
  && balena_device_uuid=$(balena device ${uuid:0:7} | grep UUID | cut -c24-)

balena push ${uuid}.local
```


## test
> mDNS not supported, set custom DNS_TLD domain, ensure DNS propagation and push

```sh
# https://github.com/pdcastro/ssh-uuid
ssh-uuid -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  --service balena-tests \
  ${balena_device_uuid}.balena \
  ./run-tests.sh
```


## operate
> (e.g.) extract credentials and show connected devices

```sh
mkdir .balena

echo "cat /etc/docker.env; exit" \
  | balena ssh ${uuid}.local api \
  | grep -E '^SUPERUSER_|^DNS_TLD=' > .balena/env

source .balena/env

cert_manager=$(DOCKER_HOST=${uuid}.local docker ps \
  --filter "name=cert-manager" \
  --format "{{.ID}}")

DOCKER_HOST=${uuid}.local docker cp \
  ${cert_manager}:/certs/private/ca-bundle.${balena_device_uuid}.${DNS_TLD}.pem .balena/

export NODE_EXTRA_CA_CERTS="$(pwd)/.balena/ca-bundle.${balena_device_uuid}.${DNS_TLD}.pem"

# (e.g.) macOS
sudo security add-trusted-cert -d \
  -r trustAsRoot \
  -k /Library/Keychains/System.keychain \
  ${NODE_EXTRA_CA_CERTS}

BALENARC_BALENA_URL=${balena_device_uuid}.${DNS_TLD}

balena login --credentials \
  --email "${SUPERUSER_EMAIL}" \
  --password "${SUPERUSER_PASSWORD}"

balena devices

unset BALENARC_BALENA_URL
```
