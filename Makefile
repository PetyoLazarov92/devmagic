# Dev Magic Build and Installation Makefile

.PHONY: help install uninstall deb clean test lint dev-setup build

# Package information
PACKAGE_NAME = devmagic
VERSION := $(shell cat VERSION)
DEB_PACKAGE = $(PACKAGE_NAME)_$(VERSION).deb

# Default target
help:
	@echo "Dev Magic Build System"
	@echo "======================"
	@echo ""
	@echo "Available targets:"
	@echo "  install     - Install Dev Magic system-wide"
	@echo "  uninstall   - Remove Dev Magic from system"
	@echo "  deb         - Create Debian package"
	@echo "  clean       - Remove build artifacts"
	@echo "  test        - Run basic tests"
	@echo "  lint        - Run shellcheck on scripts"
	@echo "  dev-setup   - Setup development environment"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make install    # Install Dev Magic"
	@echo "  make deb        # Create DEB package"
	@echo "  make clean      # Clean build files"

# Install Dev Magic system-wide
install:
	@echo "Installing Dev Magic..."
	@bash install.sh

# Uninstall Dev Magic
uninstall:
	@echo "Uninstalling Dev Magic..."
	@bash uninstall.sh

# Create Debian package
deb: clean build
	@echo "Creating Debian package..."
	@cd build && bash create-deb-package.sh
	@mv build/$(DEB_PACKAGE) .
	@echo "Package created: $(DEB_PACKAGE)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/$(PACKAGE_NAME)_*
	@rm -f $(DEB_PACKAGE)
	@rm -f *.deb
	@echo "Clean completed"

# Run basic tests
test:
	@echo "Running basic tests..."
	@bash -n mklocalenv.sh
	@echo "✓ Main script syntax check passed"
	@for script in includes/*.sh; do \
		bash -n "$$script" && echo "✓ $$script syntax check passed"; \
	done
	@for script in tools/*.sh; do \
		bash -n "$$script" && echo "✓ $$script syntax check passed"; \
	done
	@for script in utilities/*.sh; do \
		bash -n "$$script" && echo "✓ $$script syntax check passed"; \
	done

# Run shellcheck linting
lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck mklocalenv.sh install.sh uninstall.sh; \
		shellcheck includes/*.sh tools/*.sh utilities/*.sh; \
		echo "✓ Shellcheck completed"; \
	else \
		echo "⚠ Shellcheck not installed. Install with: sudo apt install shellcheck"; \
	fi

# Development targets
dev-setup:
	@echo "Setting up development environment..."
	@chmod +x mklocalenv.sh install.sh uninstall.sh
	@chmod +x build/create-deb-package.sh
	@echo "✓ Development setup completed"

# Create build directory if it doesn't exist
build:
	@mkdir -p build
