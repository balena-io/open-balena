# How to run your own service side by side with open balena

If you are running your own service, it will likely listen on port 443. Open Balena also wants to listen here and it is virtually impossible to configure this differently. Too many components of the system assume port 443.

This document assumes that you are running air-gapped and will build a self signed certificate that is valid for both open balena and your own project.

The solution to running both your own service and open balena on the same machine is 
1. Create a CA and a certificate
2. Configure your own service to forward all for the openbalena subdomain to open balena. 
3 Configure open balena to run on a subdomain e.g. openbalena.yourservice.lan
4. Configure the open balena docker-compose.yml to either not use port 443 or disable the docker port forwarding.
5. Configure DNS resolution for both on the network or in a public DNS service


## Create certificate

### Create a self-signed cert

See ./self-signed-certs/README.md

### Use ACMS/let's encrypt
**TBD**

## Configure your own service

We will spin up haproxy and attach it to a named docker network. We will use the same network on open-balena and we have aliases for the open-balena haproxy and vpn services configured in the `open-balena/docker-compose.yml`

1. `cd open-balena/example-sibling-docker-compose`
2. Examine the `docker-compose.yml` and note the `openbalena` network. This network will be shared with the open-balena docker compose project.
3. Configure `example-sibling-docker-compose/haproxy/haproxy.cfg` for your services
3. docker compose up -d

## Configure open balena

1. `cd open-balena`
2. Clear the .env and export the config envs
```bash
echo "" > .env
export DNS_TLD=yourdomain.com
export ROOT_CA=$(cat ./self-signed-certs/certs/rootCA.pem | openssl base64 -A)
export HAPROXY_KEY=$(cat ./self-signed-certs/keys/cert-key.pem | openssl base64 -A)
export HAPROXY_CRT=$(cat ./self-signed-certs/certs/cert.pem | openssl base64 -A)
```
3. In the `docker-compose.yml` file, remove external port 443 from the `haproxy`. Note that `ag-haproxy` extends `haproxy`. When using `airgapped=true` you need to change it in `haproxy`.

## Start open balena

1. `cd open-balena`
2. `make up airgapped=true`


> ignore `WARN[0000] a network with name openbalena exists but was not created for project ...`