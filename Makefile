SHELL := bash

# export all variables to child processes by default
export

# include the .env file
-include .env

DNS_TLD ?= $(error DNS_TLD not set)
TMPKI := $(shell mktemp)
STAGING_PKI ?= /usr/local/share/ca-certificates
PRODUCTION_MODE ?= true
ORG_UNIT ?= openBalena
SUPERUSER_EMAIL ?= admin@$(DNS_TLD)

.NOTPARALLEL: $(DOCKERCOMPOSE)

.PHONY: help
help: ## Print help message
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"

.PHONY: lint
lint: ## Lint shell scripts with shellcheck
	find . -type f -name *.sh | xargs shellcheck

.PHONY: verify
verify: ## Ping the public API endpoint
	curl --fail --retry 3 https://api.$(DNS_TLD)/ping
	@printf '\n'

# Write all supported variables to .env, whether they have been provided or not.
# If they already exist in the .env they will be retained.
# The existing .env takes priority over envs provided from the command line.
.PHONY: config
config: ## Rewrite the .env config from current context (env vars + env args + existing .env)
ifneq ($(CLOUDFLARE_API_TOKEN),)
ifneq ($(GANDI_API_TOKEN),)
	$(error "CLOUDFLARE_API_TOKEN and GANDI_API_TOKEN cannot both be set")
endif
endif
	@rm -f .env
	@echo "DNS_TLD=$(DNS_TLD)" >> .env
	@echo "ORG_UNIT=$(ORG_UNIT)" >> .env
	@echo "SUPERUSER_EMAIL=$(SUPERUSER_EMAIL)" >> .env
	@echo "PRODUCTION_MODE=$(PRODUCTION_MODE)" >> .env
	@echo "GANDI_API_TOKEN=$(GANDI_API_TOKEN)" >> .env
	@echo "CLOUDFLARE_API_TOKEN=$(CLOUDFLARE_API_TOKEN)" >> .env
	@echo "ACME_EMAIL=$(ACME_EMAIL)" >> .env
	@echo "HAPROXY_CRT=$(HAPROXY_CRT)" >> .env
	@echo "HAPROXY_KEY=$(HAPROXY_KEY)" >> .env
	@echo "ROOT_CA=$(ROOT_CA)" >> .env
	@$(MAKE) showenv

.PHONY: up
up: config ## Start all services
	@docker compose up --build -d
	@until [[ $$(docker compose ps api --format json | jq -r '.Health') =~ healthy ]]; do printf '.'; sleep 3; done
	@printf '\n'
	@$(MAKE) showenv
	@$(MAKE) showpass

.PHONY: showenv
showenv: ## Print the current contents of the .env config
	@cat <.env
	@printf '\n'

.PHONY: printenv
printenv: ## Print the current environment variables
	@printenv

.PHONY: showpass
showpass: ## Print the superuser password
	@docker compose exec api cat config/env | grep SUPERUSER_PASSWORD
	@printf '\n'

.PHONY: down
down: ## Stop all services
	@docker compose stop

.PHONY: stop
stop: down ## Alias for 'make down'

.PHONY: restart
restart: ## Restart all services
	@docker compose restart

.PHONY: update
update: # Pull and deploy latest changes from git
	@git pull
	@$(MAKE) up

.PHONY: destroy ## Stop and remove any existing containers and volumes
destroy:
	@docker compose down --volumes --remove-orphans

.PHONY: clean
clean: destroy ## Alias for 'make destroy'

.PHONY: self-signed
self-signed: ## Install self-signed CA certificates
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

# FIXME: refactor this function to use 'make up'
.PHONY: auto-pki
auto-pki: config # Start all services using LetsEncrypt and ACME
	@docker compose exec cert-manager rm -f /certs/export/chain.pem
	@docker compose up -d
	@until docker compose logs cert-manager | grep -Eq "/certs/export/chain.pem Certificate will not expire in [0-9] days"; do printf '.'; sleep 3; done
	@until docker compose logs cert-manager | grep -q "subject=CN = ${DNS_TLD}"; do printf '.'; sleep 3; done
	@until docker compose logs cert-manager | grep -q "issuer=C = US, O = Let's Encrypt, CN = R3"; do printf '.'; sleep 3; done
	@until [[ $$(docker compose ps haproxy --format json | jq -r '.Health') =~ healthy ]]; do printf '.'; sleep 3; done
	@printf '\n'
	@$(MAKE) showenv
	@$(MAKE) showpass

.PHONY: pki-custom
pki-custom: up ## Alias for 'make up'

.PHONY: deploy
deploy: up ## Alias for 'make up'

.DEFAULT_GOAL = help
