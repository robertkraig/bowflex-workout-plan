# Multi-language PDF Page Extractor Makefile

.PHONY: help install-python install-rust install-golang install-julia install-all
.PHONY: run-python run-rust run-golang run-julia clean-all format-all lint-all

# Default target
help:
	@echo "Multi-language PDF Page Extractor"
	@echo ""
	@echo "Available targets:"
	@echo "  install-python   - Install Python dependencies"
	@echo "  install-rust     - Install Rust dependencies"
	@echo "  install-golang   - Install Go dependencies"
	@echo "  install-julia    - Install Julia dependencies"
	@echo "  install-all      - Install all language dependencies"
	@echo ""
	@echo "  run-python       - Run Python implementation"
	@echo "  run-rust         - Run Rust implementation"
	@echo "  run-golang       - Run Go implementation"
	@echo "  run-julia        - Run Julia implementation"
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

install-all: install-python install-rust install-golang install-julia
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

# Maintenance targets
clean-all:
	cd python && $(MAKE) clean
	cd rust && $(MAKE) clean
	cd golang && $(MAKE) clean
	cd julia && $(MAKE) clean
	rm -rf output/*.pdf

format-all:
	cd python && $(MAKE) format
	cd rust && $(MAKE) format
	cd golang && $(MAKE) format
	cd julia && $(MAKE) format

lint-all:
	cd python && $(MAKE) lint
	cd rust && $(MAKE) lint
	cd golang && $(MAKE) lint
	cd julia && $(MAKE) lint
