SHELL := bash

DNS_TLD ?= $(error DNS_TLD not set)
TMPKI := $(shell mktemp)
STAGING_PKI ?= /usr/local/share/ca-certificates
PRODUCTION_MODE ?= true
ORG_UNIT ?= openBalena

.PHONY: lint

lint:
	find . -type f -name *.sh | xargs shellcheck

verify:
	curl --fail --retry 3 https://api.$(DNS_TLD)/ping
	@printf '\n'

up:
	@touch .env
	@sed -i '/DNS_TLD=/d' .env
	@sed -i '/ORG_UNIT=/d' .env
	@sed -i '/SUPERUSER_EMAIL=/d' .env
	@sed -i '/PRODUCTION_MODE=/d' .env
	@echo "DNS_TLD=$(DNS_TLD)" > .env
	@echo "ORG_UNIT=$(ORG_UNIT)" >> .env
	@echo "SUPERUSER_EMAIL=admin@$(DNS_TLD)" >> .env
	@echo "PRODUCTION_MODE=$(PRODUCTION_MODE)" >> .env
	@docker compose up -d
	@until [[ $$(docker compose ps api --format json | jq -r '.Health') =~ healthy ]]; do printf '.'; sleep 3; done
	@printf '\n'
	@cat <.env
	@docker compose exec api cat config/env | grep SUPERUSER_PASSWORD

down:
	@docker compose stop

restart:
	@docker compose restart

update:
	@docker compose down
	@git pull
	@docker compose up --build -d
	@until [[ $$(docker compose ps api --format json \
	  | jq -r '.Health') =~ healthy ]]; do printf '.'; sleep 3; done
	@printf '\n'

destroy:
	@docker compose down --volumes --remove-orphans

self-signed:
	@sudo mkdir -p .balena $(STAGING_PKI)

	@true | openssl s_client -showcerts -connect api.$(DNS_TLD):443 \
	  | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' > $(TMPKI).ca

	@cat <$(TMPKI).ca | openssl x509 -text \
	  | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' > $(TMPKI).srv

	@diff --suppress-common-lines --unchanged-line-format= \
	  $(TMPKI).srv \
	  $(TMPKI).ca | sudo tee $(STAGING_PKI)/ca-$(DNS_TLD).crt || true

	@sudo update-ca-certificates
	@cat <$(STAGING_PKI)/ca-$(DNS_TLD).crt | sudo tee .balena/ca-$(DNS_TLD).pem

auto-pki:
	@if [[ -z "$$GANDI_API_TOKEN" && -z "$$CLOUDFLARE_API_TOKEN" ]]; then false; fi
	@if [[ -n "$$GANDI_API_TOKEN" && -n "$$CLOUDFLARE_API_TOKEN" ]]; then false; fi
	@sed -i '/GANDI_API_TOKEN=/d' .env
	@sed -i '/CLOUDFLARE_API_TOKEN=/d' .env
	@sed -i '/ACME_EMAIL=/d' .env
	@if [[ -n "$$GANDI_API_TOKEN" ]]; then echo "GANDI_API_TOKEN=$(GANDI_API_TOKEN)" >> .env; fi
	@if [[ -n "$$CLOUDFLARE_API_TOKEN" ]]; then echo "CLOUDFLARE_API_TOKEN=$(CLOUDFLARE_API_TOKEN)" >> .env; fi
	@echo "ACME_EMAIL=$(ACME_EMAIL)" >> .env
	@docker compose exec cert-manager rm -f /certs/export/chain.pem
	@docker compose up -d
	@until docker compose logs cert-manager | grep -Eq "/certs/export/chain.pem Certificate will not expire in [0-9] days"; do printf '.'; sleep 3; done
	@until docker compose logs cert-manager | grep -q "subject=CN = ${DNS_TLD}"; do printf '.'; sleep 3; done
	@until docker compose logs cert-manager | grep -q "issuer=C = US, O = Let's Encrypt, CN = R3"; do printf '.'; sleep 3; done
	@until [[ $$(docker compose ps haproxy --format json | jq -r '.Health') =~ healthy ]]; do printf '.'; sleep 3; done
	@printf '\n'

pki-custom:
	@sed -i '/HAPROXY_CRT=/d' .env
	@sed -i '/HAPROXY_KEY=/d' .env
	@sed -i '/ROOT_CA=/d' .env
	@echo "HAPROXY_CRT=$(HAPROXY_CRT)" >> .env
	@echo "HAPROXY_KEY=$(HAPROXY_KEY)" >> .env
	@echo "ROOT_CA=$(ROOT_CA)" >> .env
	@docker compose up -d
	@until [[ $$(docker compose ps haproxy --format json | jq -r '.Health') =~ healthy ]]; do printf '.'; sleep 3; done
	@printf '\n'
