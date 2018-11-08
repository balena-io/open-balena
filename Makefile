.PHONY: lint build install uninstall

lint:
	shellcheck scripts/*

build:
	docker build -t open-balena-installer -f installer/Dockerfile .

install:
	docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock open-balena-installer balena-install up -d --build

uninstall:
	docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock open-balena-installer balena-install down
