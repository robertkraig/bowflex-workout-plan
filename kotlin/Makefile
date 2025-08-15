# Kotlin PDF Extractor Makefile

.PHONY: install run clean lint format build

# Install dependencies
install:
	@echo "Installing Kotlin dependencies..."
	gradle build

# Run the application
run:
	@echo "Running Kotlin PDF extractor..."
	gradle run

# Clean build artifacts
clean:
	@echo "Cleaning Kotlin build artifacts..."
	gradle clean

# Lint (static analysis)
lint:
	@echo "Running Kotlin static analysis..."
	gradle check

# Format code (using ktlint if available)
format:
	@echo "Formatting Kotlin code..."
	@if command -v ktlint >/dev/null 2>&1; then \
		ktlint --format src/**/*.kt; \
	else \
		echo "ktlint not found - install with 'sdk install ktlint' for code formatting"; \
	fi

# Build the application
build:
	@echo "Building Kotlin application..."
	gradle build
