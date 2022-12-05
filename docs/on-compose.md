# openBalena on docker/compose
> https://www.balena.io/open/docs/getting-started/

## ToC
* [configure](#configure)
* [deploy](#deploy)
* [operate](#operate)
* [footnotes](#footnotes)


## configure
> create an `.env` file containing various operational parameters[fn1](#fn1)

```sh
DNS_TLD=openbalena.local

cat << EOF > .env
COMMON_REGION=us-east-1
DNS_TLD=${DNS_TLD}
MDNS_TLD=${DNS_TLD}
ORG_UNIT=openBalena
SUPERUSER_EMAIL=admin@${DNS_TLD}
EOF
```


## deploy

```sh
docker-compose up --build

docker-compose restart
```


## operate
> (e.g.) extract credentials and show connected devices from a macOS client

```sh
set -a

mkdir .balena

tmpenv=$(mktemp)

BALENARC_BALENA_URL=${DNS_TLD}

cert_manager=$(docker ps --filter "name=cert-manager" --format "{{.ID}}")
docker cp ${cert_manager}:/certs/private/ca-bundle.${DNS_TLD}.pem .balena/
NODE_EXTRA_CA_CERTS="$(pwd)/.balena/ca-bundle.${DNS_TLD}.pem"
CURL_CA_BUNDLE=${NODE_EXTRA_CA_CERTS}

api=$(docker ps --filter "name=api" --format "{{.ID}}")
docker cp ${api}:/etc/docker.env .balena/
grep -E '^SUPERUSER_|^DNS_TLD=' .balena/docker.env > ${tmpenv}
source ${tmpenv}

# (e.g.) macOS
sudo security add-trusted-cert -d \
  -r trustAsRoot \
  -k /Library/Keychains/System.keychain \
  ${NODE_EXTRA_CA_CERTS}

curl http://api.${DNS_TLD}/health

curl https://api.${DNS_TLD}/ping

balena login --credentials \
  --email "${SUPERUSER_EMAIL}" \
  --password "${SUPERUSER_PASSWORD}"

balena devices


unset NODE_EXTRA_CA_CERTS
unset BALENARC_BALENA_URL
unset CURL_CA_BUNDLE

rm -rf ${tmpenv} .balena
```


## footnotes

### fn1

  > while mDNS is usually fine for local development and evaluating the product, but it is
  unsuitable for production deployments

  To use a non mDNS domain:
  * specify `DNS_TLD` (e.g. `openbalena.foo.com`)
  * unset `MDNS_TLD`
  * set `ACME_EMAIL` to be notified about SSL certificate renewal issues; and
  * specify either `GANDI_API_TOKEN` or `CLOUDFLARE_API_TOKEN` scoped to create DNS
    entries under `DNS_TLD`; or
  * manually obtain a wildcard SSL certificate covering `*.dns_tld` and place into
    `/certs/export/chain.pem` (e.g. mounted on `cert-manager`, `haproxy` containers, etc.)
