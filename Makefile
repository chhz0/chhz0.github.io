.PHONY: update-theme
update-theme:
	@echo "Updating theme..."
	@git submodule update --remote --merge
	@echo "Theme updated."