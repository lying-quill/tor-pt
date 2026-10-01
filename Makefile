SRC_DIR := .github/scripts

format:
	shfmt -l -w $(SRC_DIR)

	find . -type f -name '*.json' -exec sh -c \
		'jq . "$$1" > "$$1.tmp" && mv "$$1.tmp" "$$1"' _ {} \;

ci:
	shfmt -d $(SRC_DIR)

	find . -type f -name '*.json' -exec sh -c '\
		for file do \
			formatted=$$(mktemp) || exit 1; \
			if ! jq . "$$file" > "$$formatted"; then \
				echo "Invalid JSON: $$file" >&2; \
				rm -f "$$formatted"; \
				exit 1; \
			fi; \
			if ! diff -u "$$file" "$$formatted"; then \
				echo "JSON is not formatted: $$file" >&2; \
				rm -f "$$formatted"; \
				exit 1; \
			fi; \
			rm -f "$$formatted"; \
		done \
	' _ {} +

	find $(SRC_DIR) -type f -exec sh -c 'head -n 1 "$$1" | \
		grep -qE "^#!/bin/(ba)?sh$$" && echo "$$1"' _ {} \; | xargs shellcheck

dev:
	shellcheck --version
	shfmt --version
	@for hook in git-hooks/*; do \
		chmod +x $$hook; \
		ln -sf ../../"$$hook" .git/hooks/; \
	done

.PHONY: format ci dev
