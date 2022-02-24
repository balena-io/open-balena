.PHONY: lint

lint:
	find . -type f -name *.sh | xargs shellcheck
