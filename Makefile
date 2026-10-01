SRC_DIR := .github/scripts

format:
	shfmt -l -w .

ci:
	shfmt -d .
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
