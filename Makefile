# Multi-language PDF Page Extractor Makefile

.PHONY: help install-python install-rust install-golang install-julia install-php install-nodejs install-ruby install-elixir install-scala install-java install-all
.PHONY: run-python run-rust run-golang run-julia run-php run-nodejs run-ruby run-elixir run-scala run-java run-all clean-all format-all lint-all precommit-format

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
	@echo "  install-scala    - Install Scala dependencies"
	@echo "  install-java     - Install Java dependencies"
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
	@echo "  run-scala        - Run Scala implementation"
	@echo "  run-java         - Run Java implementation"
	@echo "  run-all          - Run all language implementations in sequence"
	@echo ""
	@echo "  clean-all        - Clean all build artifacts"
	@echo "  format-all       - Format code in all languages"
	@echo "  lint-all         - Lint code in all languages"
	@echo "  precommit-format - Run pre-commit hooks to auto-format files"

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

install-scala:
	@if command -v sbt >/dev/null 2>&1; then \
		cd scala && $(MAKE) install; \
	else \
		echo "Skipping Scala installation - SBT not found"; \
	fi

install-java:
	@if command -v mvn >/dev/null 2>&1; then \
		if command -v java >/dev/null 2>&1; then \
			cd java && $(MAKE) install; \
		else \
			echo "Skipping Java installation - Java not found"; \
		fi; \
	else \
		echo "Skipping Java installation - Maven not found"; \
	fi

install-all: install-python install-rust install-golang install-julia install-php install-nodejs install-ruby install-elixir install-scala install-java
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

run-scala:
	@if command -v sbt >/dev/null 2>&1; then \
		cd scala && $(MAKE) run; \
	else \
		echo "SBT not found - cannot run Scala implementation"; \
	fi

run-java:
	@if command -v mvn >/dev/null 2>&1; then \
		if command -v java >/dev/null 2>&1; then \
			cd java && $(MAKE) run; \
		else \
			echo "Java not found - cannot run Java implementation"; \
		fi; \
	else \
		echo "Maven not found - cannot run Java implementation"; \
	fi

run-all:
	@echo "🚀 Running all language implementations in sequence..."
	@echo "=================================================="
	@echo "1/10 - Running Python implementation..."
	@$(MAKE) run-python || echo "❌ Python implementation failed"
	@echo ""
	@echo "2/10 - Running Rust implementation..."
	@$(MAKE) run-rust || echo "❌ Rust implementation failed"
	@echo ""
	@echo "3/10 - Running Go implementation..."
	@$(MAKE) run-golang || echo "❌ Go implementation failed"
	@echo ""
	@echo "4/10 - Running Julia implementation..."
	@$(MAKE) run-julia || echo "❌ Julia implementation failed"
	@echo ""
	@echo "5/10 - Running PHP implementation..."
	@$(MAKE) run-php || echo "❌ PHP implementation failed"
	@echo ""
	@echo "6/10 - Running Node.js implementation..."
	@$(MAKE) run-nodejs || echo "❌ Node.js implementation failed"
	@echo ""
	@echo "7/10 - Running Ruby implementation..."
	@$(MAKE) run-ruby || echo "❌ Ruby implementation failed"
	@echo ""
	@echo "8/10 - Running Elixir implementation..."
	@$(MAKE) run-elixir || echo "❌ Elixir implementation failed"
	@echo ""
	@echo "9/10 - Running Scala implementation..."
	@$(MAKE) run-scala || echo "❌ Scala implementation failed"
	@echo ""
	@echo "10/10 - Running Java implementation..."
	@$(MAKE) run-java || echo "❌ Java implementation failed"
	@echo ""
	@echo "✅ All language implementations completed!"
	@echo "=================================================="
	@echo "Check the output/ directory for generated PDFs with language-specific suffixes"

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
	@if [ -d scala ]; then cd scala && $(MAKE) clean; fi
	@if [ -d java ]; then cd java && $(MAKE) clean; fi
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
	@if command -v sbt >/dev/null 2>&1 && [ -d scala ]; then cd scala && $(MAKE) format; fi
	@if command -v mvn >/dev/null 2>&1 && [ -d java ]; then cd java && $(MAKE) format; fi

lint-all:
	cd python && $(MAKE) lint
	cd rust && $(MAKE) lint
	cd golang && $(MAKE) lint
	cd julia && $(MAKE) lint
	@if command -v php >/dev/null 2>&1 && [ -d php ]; then cd php && $(MAKE) lint; fi
	@if command -v node >/dev/null 2>&1 && [ -d nodejs ]; then cd nodejs && $(MAKE) lint; fi
	@if command -v ruby >/dev/null 2>&1 && [ -d ruby ]; then cd ruby && $(MAKE) lint; fi
	@if command -v mix >/dev/null 2>&1 && [ -d elixir ]; then cd elixir && $(MAKE) lint; fi
	@if command -v sbt >/dev/null 2>&1 && [ -d scala ]; then cd scala && $(MAKE) lint; fi
	@if command -v mvn >/dev/null 2>&1 && [ -d java ]; then cd java && $(MAKE) lint; fi

# Pre-commit formatting target
precommit-format:
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "pre-commit not found - install with 'pip install pre-commit'"; \
	fi
