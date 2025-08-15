# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a multi-language PDF page extractor that implements the same functionality across 8 programming languages: Python, Rust, Go, Julia, PHP, Node.js, Ruby, and Elixir. All implementations extract specified pages from PDF documents and optionally prepend Markdown files as styled introductions.

## Key Architecture Components

**Shared Resources Architecture:**
- All language implementations share the same `resources/` directory for input files and configuration
- All implementations output to the same `output/` directory with language-specific suffixes
- Markdown-to-PDF conversion is centralized through a shared Node.js Puppeteer script (`puppeteer_render.js`)

**Configuration-Driven Extraction:**
- `resources/config.yaml` defines pages to extract using 1-based `pageIndex` values
- Each implementation reads this YAML to determine which pages to process
- Pages are extracted using external tools (pdftk, PDF libraries) then merged with optional Markdown introductions

**Language Implementation Pattern:**
Each language directory (`python/`, `php/`, `rust/`, `ruby/`, `elixir/`, etc.) follows the same structure:
- `Makefile` with consistent targets: `install`, `run`, `clean`, `lint`, `format`
- Main executable that accepts CLI args: `--input`, `--output`, `--yaml`, `--markdown`
- Package manager configuration (composer.json, package.json, Cargo.toml, etc.)
- Language-specific tooling for linting and formatting

## Development Commands

**Installation and Setup:**
```bash
./setup.sh              # Install system dependencies and Python environment
make install-all         # Install dependencies for all languages
make install-<lang>      # Install for specific language (python, php, rust, ruby, elixir, etc.)
```

**Running Implementations:**
```bash
make run-<lang>          # Run specific language implementation
# Available: run-python, run-php, run-rust, run-golang, run-julia, run-nodejs, run-ruby, run-elixir
```

**Code Quality and Maintenance:**
```bash
make format-all          # Format code in all languages
make lint-all           # Lint code in all languages
make clean-all          # Remove all build artifacts and generated PDFs
```

**Language-Specific Quality Tools:**

PHP (located in `php/` directory):
```bash
make lint               # PHP_CodeSniffer PSR-12 linting
make format            # PHP_CodeSniffer PSR-12 auto-fixing
make format-check      # PHP-CS-Fixer dry-run with diff
make format-fix        # PHP-CS-Fixer advanced formatting
make stan              # PHPStan static analysis at max level
```

Node.js (located in `nodejs/` directory):
```bash
make lint              # ESLint
make format            # Prettier
npm start              # Run main script
```

Ruby (located in `ruby/` directory):
```bash
make lint              # RuboCop linting
make format            # RuboCop auto-correction
make test              # RSpec tests
make audit             # Bundle audit for security
bundle exec ruby main.rb # Run main script
```

Elixir (located in `elixir/` directory):
```bash
make lint              # Credo linting
make format            # Mix format
make deps              # Mix deps.get
mix escript.build      # Build escript
./pdf_extractor        # Run escript
```

## PHP Implementation Details

The PHP implementation uses a unique architecture with proper PSR-4 autoloading:

**Class Structure:**
- `PdfExtractor\PdfExtractor` class in `src/PdfExtractor/PdfExtractor.php`
- PSR-4 autoload mapping: `"PdfExtractor\\": "src/PdfExtractor/"`
- Composer autoload: `require_once __DIR__ . '/../vendor/autoload.php'`

**External Tool Integration:**
- Uses `pdftk` for PDF page extraction via `proc_open()` with proper stdout/stderr capture
- Custom `executeCommand()` method returns `array{stdout: string, stderr: string, exit_code: int}`
- Comprehensive error reporting includes command, exit code, and both output streams

**Quality Tooling:**
- PHP-CS-Fixer with advanced formatting rules (strict types, trailing commas, single quotes)
- PHPStan at maximum level with proper type annotations
- Pre-commit hooks enforce JSON formatting and code standards

## Ruby Implementation Details

The Ruby implementation follows idiomatic Ruby patterns and conventions:

**Module Structure:**
- `PdfExtractor` module in `lib/pdf_extractor.rb` with proper autoloading
- Modular design: `Extractor`, `CommandRunner`, `MarkdownConverter`, `CLI` classes
- Ruby naming conventions: snake_case for files/methods, PascalCase for classes/modules

**Command Execution:**
- Uses `Open3.capture3` for proper stdout/stderr capture with timeout support
- `CommandRunner` class with structured `CommandResult` using Ruby Struct
- Comprehensive error handling with custom exception hierarchy

**Ruby Idioms:**
- `frozen_string_literal: true` for performance and immutability
- Method chaining with `then` for readable transformations
- Proper use of `attr_reader` for encapsulation
- Block usage with `Tempfile.create` for automatic cleanup
- `case/when` statements for readable control flow

**Quality Tooling:**
- RuboCop with performance and RSpec extensions
- Bundler for dependency management with proper Gemfile.lock commitment
- RSpec for testing (configured but tests not yet implemented)
- Bundle audit for security vulnerability scanning

## Elixir Implementation Details

The Elixir implementation follows functional programming principles and OTP conventions:

**Module Structure:**
- `PdfExtractor` main module with `CLI` and `Core` submodules
- `PdfExtractor.CLI` for command-line interface and argument parsing
- `PdfExtractor.Core` for PDF extraction logic
- `PdfExtractor.MarkdownConverter` for Markdown-to-PDF conversion

**Escript Build:**
- Builds standalone executable using Mix escript functionality
- No external Elixir runtime required for execution after build
- Uses `OptionParser` for CLI argument handling with aliases

**External Tool Integration:**
- Uses `pdftk` for PDF page extraction via `System.cmd/3`
- Proper error handling with pattern matching on command results
- Shell command escaping for secure file path handling

**Elixir Idioms:**
- Pattern matching for error handling and control flow
- Pipe operator for data transformation chains
- `with` statements for happy path processing
- Immutable data structures throughout
- Supervisor tree ready (though not used in this CLI application)

**Quality Tooling:**
- Mix for dependency management and build automation
- Credo for static analysis and code consistency
- ExDoc for documentation generation
- Mix format for automatic code formatting

## Pre-commit Hooks

The repository uses pre-commit hooks (`.pre-commit-config.yaml`) that automatically:
- Fix trailing whitespace and line endings
- Validate YAML, JSON, and TOML files
- Format JSON with 2-space indentation (`pretty-format-json`)
- Run Black, isort, and flake8 on Python files
- Check for merge conflicts and case conflicts

**Important:** JSON files use 2-space indentation (not 4) to pass `pretty-format-json` hook.

## Lock File Management

All package manager lock files are committed for reproducible builds:
- `composer.lock` (PHP)
- `package-lock.json` (Node.js)
- `yarn.lock`, `pnpm-lock.yaml` (when using alternative Node.js package managers)
- `Cargo.lock` (Rust)
- `go.sum` (Go)
- `Manifest.toml` (Julia)
- `poetry.lock` (Python)
- `Gemfile.lock` (Ruby)
- `mix.lock` (Elixir)

## Configuration Files

**Core Configuration:**
- `resources/config.yaml` - Defines input PDF, output location, pages to extract, and optional Markdown file
- Each language reads this file to determine extraction parameters
- Page indices are 1-based (not 0-based) for consistency with PDF viewer numbering

**Language-Specific Configurations:**
- `php/phpstan.neon` - PHPStan configuration with `level: max` and proper bootstrap
- `php/.php-cs-fixer.php` - Advanced PHP formatting rules with strict types and modern PHP features
- `ruby/.rubocop.yml` - Ruby style guide enforcement with performance and RSpec extensions
- `.pre-commit-config.yaml` - Repository-wide code quality enforcement
- `elixir/.formatter.exs` - Elixir code formatting configuration with custom rules

## Common Issues and Solutions

**PHP Autoloading:**
If you see "Class PdfExtractor\PdfExtractor not found", run `composer dump-autoload` in the `php/` directory.

**Pre-commit Hook Failures:**
JSON formatting failures typically mean files use 4-space instead of 2-space indentation. The hook auto-fixes this, then re-commit.

**Ruby Dependencies:**
If you see bundle-related errors, run `bundle install` in the `ruby/` directory. Use `bundle check` to verify all gems are installed.

**pdftk Integration:**
PHP, Ruby, and Elixir implementations demonstrate proper external tool integration with comprehensive error capture. Other implementations may use different PDF libraries but follow similar error handling patterns.

**Elixir Dependencies:**
If you see Mix-related errors, run `mix deps.get` in the `elixir/` directory. Use `mix deps` to check dependency status.
