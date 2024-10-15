.SHELLFLAGS += -e -u -o pipefail

.DEFAULT_GOAL := data/site.html

data/nicks.txt: data/form.json
	cat $< | jq '.blocks[0].c[1]|map(.c[1][0].c[1][0].c[0][2][5][1]).[]' -r > $@

# form.html comes from exctracting part of the Google form.
data/form.json: data/form.html ; pandoc -f html -t json $< > $@

data/images-for-nicks.mk: data/nicks.txt
	cat $< | while read -r nick; do ./scripts/make-image-for-nick-make "$$nick"; done > $@

include data/images-for-nicks.mk

data/nicks-variable.mk: data/nicks.txt ; ./scripts/make-nicks-variable-make > $@

include data/nicks-variable.mk

data/site.html: $(nicks)
	./scripts/make-site > $@

.PHONY: clean
clean: ; rm -f $(addprefix data/, nicks.txt form.json images-for-nicks.mk nicks-variable.mk site.html)
