# Multi-language PDF Page Extractor Makefile

.PHONY: help install-python install-rust install-golang install-julia install-php install-nodejs install-ruby install-elixir install-all
.PHONY: run-python run-rust run-golang run-julia run-php run-nodejs run-ruby run-elixir clean-all format-all lint-all

# Default target
help:
	@echo "Multi-language PDF Page Extractor"
	@echo ""
	@echo "Available targets:"
	@echo "  install-python   - Install Python dependencies"
	@echo "  install-rust     - Install Rust dependencies"
	@echo "  install-golang   - Install Go dependencies"
	@echo "  install-julia    - Install Julia dependencies"
	@echo "  install-php      - Install PHP dependencies"
	@echo "  install-nodejs   - Install Node.js dependencies"
	@echo "  install-ruby     - Install Ruby dependencies"
	@echo "  install-elixir   - Install Elixir dependencies"
	@echo "  install-all      - Install all language dependencies"
	@echo ""
	@echo "  run-python       - Run Python implementation"
	@echo "  run-rust         - Run Rust implementation"
	@echo "  run-golang       - Run Go implementation"
	@echo "  run-julia        - Run Julia implementation"
	@echo "  run-php          - Run PHP implementation"
	@echo "  run-nodejs       - Run Node.js implementation"
	@echo "  run-ruby         - Run Ruby implementation"
	@echo "  run-elixir       - Run Elixir implementation"
	@echo ""
	@echo "  clean-all        - Clean all build artifacts"
	@echo "  format-all       - Format code in all languages"
	@echo "  lint-all         - Lint code in all languages"

# Installation targets
install-python:
	cd python && $(MAKE) install

install-rust:
	cd rust && $(MAKE) install

install-golang:
	cd golang && $(MAKE) install

install-julia:
	cd julia && $(MAKE) install

install-php:
	@if command -v php >/dev/null 2>&1 && command -v composer >/dev/null 2>&1; then \
		cd php && $(MAKE) install; \
	else \
		echo "Skipping PHP installation - PHP or Composer not found"; \
	fi

install-nodejs:
	@if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then \
		cd nodejs && $(MAKE) install; \
	else \
		echo "Skipping Node.js installation - Node.js or npm not found"; \
	fi

install-ruby:
	@if command -v ruby >/dev/null 2>&1 && command -v bundle >/dev/null 2>&1; then \
		cd ruby && $(MAKE) install; \
	else \
		echo "Skipping Ruby installation - Ruby or Bundler not found"; \
	fi

install-elixir:
	@if command -v mix >/dev/null 2>&1; then \
		cd elixir && $(MAKE) install; \
	else \
		echo "Skipping Elixir installation - Elixir or Mix not found"; \
	fi

install-all: install-python install-rust install-golang install-julia install-php install-nodejs install-ruby install-elixir
	npm ci

# Run targets
run-python:
	cd python && $(MAKE) run

run-rust:
	cd rust && $(MAKE) run

run-golang:
	cd golang && $(MAKE) run

run-julia:
	cd julia && $(MAKE) run

run-php:
	@if command -v php >/dev/null 2>&1; then \
		cd php && $(MAKE) run; \
	else \
		echo "PHP not found - cannot run PHP implementation"; \
	fi

run-nodejs:
	@if command -v node >/dev/null 2>&1; then \
		cd nodejs && $(MAKE) run; \
	else \
		echo "Node.js not found - cannot run Node.js implementation"; \
	fi

run-ruby:
	@if command -v ruby >/dev/null 2>&1; then \
		cd ruby && $(MAKE) run; \
	else \
		echo "Ruby not found - cannot run Ruby implementation"; \
	fi

run-elixir:
	@if command -v mix >/dev/null 2>&1; then \
		cd elixir && $(MAKE) run; \
	else \
		echo "Elixir not found - cannot run Elixir implementation"; \
	fi

# Maintenance targets
clean-all:
	cd python && $(MAKE) clean
	cd rust && $(MAKE) clean
	cd golang && $(MAKE) clean
	cd julia && $(MAKE) clean
	@if [ -d php ]; then cd php && $(MAKE) clean; fi
	@if [ -d nodejs ]; then cd nodejs && $(MAKE) clean; fi
	@if [ -d ruby ]; then cd ruby && $(MAKE) clean; fi
	@if [ -d elixir ]; then cd elixir && $(MAKE) clean; fi
	rm -rf output/*.pdf

format-all:
	cd python && $(MAKE) format
	cd rust && $(MAKE) format
	cd golang && $(MAKE) format
	cd julia && $(MAKE) format
	@if command -v php >/dev/null 2>&1 && [ -d php ]; then cd php && $(MAKE) format; fi
	@if command -v node >/dev/null 2>&1 && [ -d nodejs ]; then cd nodejs && $(MAKE) format; fi
	@if command -v ruby >/dev/null 2>&1 && [ -d ruby ]; then cd ruby && $(MAKE) format; fi
	@if command -v mix >/dev/null 2>&1 && [ -d elixir ]; then cd elixir && $(MAKE) format; fi

lint-all:
	cd python && $(MAKE) lint
	cd rust && $(MAKE) lint
	cd golang && $(MAKE) lint
	cd julia && $(MAKE) lint
	@if command -v php >/dev/null 2>&1 && [ -d php ]; then cd php && $(MAKE) lint; fi
	@if command -v node >/dev/null 2>&1 && [ -d nodejs ]; then cd nodejs && $(MAKE) lint; fi
	@if command -v ruby >/dev/null 2>&1 && [ -d ruby ]; then cd ruby && $(MAKE) lint; fi
	@if command -v mix >/dev/null 2>&1 && [ -d elixir ]; then cd elixir && $(MAKE) lint; fi
