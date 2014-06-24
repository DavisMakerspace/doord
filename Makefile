.PHONY: all
all: install

.PHONY: install
install: /etc/systemd/system/doord-export.service /etc/systemd/system/doord.service

/etc/systemd/system/%: install/%.template
	sed 's|/PATH/TO|'"$$(readlink -f .)"'|g' $< >$@
