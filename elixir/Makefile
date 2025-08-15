# Elixir PDF Extractor Makefile

.PHONY: install run clean lint format test help

# Default target
help:
	@echo "Available targets:"
	@echo "  install  - Install dependencies"
	@echo "  run      - Run the PDF extractor with default config"
	@echo "  clean    - Clean build artifacts"
	@echo "  lint     - Run code linting"
	@echo "  format   - Format code"
	@echo "  test     - Run tests"
	@echo "  help     - Show this help message"

# Install dependencies
install:
	mix deps.get
	mix compile

# Run with default configuration
run:
	mkdir -p ../output
	mix escript.build
	./pdf_extractor --yaml ../resources/config.yaml

# Clean build artifacts
clean:
	mix clean
	rm -f pdf_extractor
	rm -f mix.lock

# Lint code
lint:
	mix credo --strict

# Format code
format:
	mix format

# Run tests
test:
	mix test

# Development dependencies (optional)
install-dev:
	mix archive.install hex credo --force
