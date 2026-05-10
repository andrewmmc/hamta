PREFIX ?= /usr/local

.PHONY: install uninstall

install:
	install -d "$(PREFIX)/bin"
	install -m 755 bin/hamta "$(PREFIX)/bin/hamta"
	install -d "$(PREFIX)/share/hamta"
	install -m 644 share/hamta/config.json "$(PREFIX)/share/hamta/config.json"
	@echo "hamta installed to $(PREFIX)/bin/hamta"
	@echo "Run 'hamta init' to create your config."

uninstall:
	rm -f "$(PREFIX)/bin/hamta"
	rm -rf "$(PREFIX)/share/hamta"
	@echo "hamta uninstalled."
