# Multi-Language PDF Page Extractor

This project allows you to extract selected pages from a PDF document and optionally prepend a Markdown file as an introduction. The same functionality is implemented in **12 programming languages**: Python, Rust, Go, Julia, PHP, Node.js, Ruby, Elixir, Scala, Java, .NET Core, and Kotlin.

## Language Implementations

- **`python/`** - Python implementation using PyPDF2 and Poetry
- **`rust/`** - Rust implementation using lopdf and Cargo
- **`golang/`** - Go implementation using unipdf and Go modules
- **`julia/`** - Julia implementation using Poppler and native package manager
- **`php/`** - PHP implementation using FPDI and Composer
- **`nodejs/`** - Node.js implementation using pdf-lib and npm
- **`ruby/`** - Ruby implementation using pdftk and Bundler
- **`elixir/`** - Elixir implementation using pdftk and Mix
- **`scala/`** - Scala implementation using pdftk and SBT
- **`java/`** - Java implementation using pdftk and Maven
- **`dotnet/`** - .NET Core implementation using pdftk and dotnet CLI
- **`kotlin/`** - Kotlin implementation using pdftk and Gradle

All implementations share the same resources and output directories, and use the same Node.js Puppeteer script for Markdown-to-PDF conversion.

## Setup

### Quick Setup for All Languages

```sh
./setup.sh          # Install system dependencies and all language toolchains
```

This will automatically:
- Install system dependencies (build tools, libraries, etc.)
- Install Node.js and npm (required for Puppeteer)
- Run language-specific setup scripts for all 12 languages
- Install dependencies for all languages

### Language-Specific Setup

Each language has its own setup script that can be run independently:

```sh
# Individual language setup
cd python && ./setup.sh
cd rust && ./setup.sh
cd golang && ./setup.sh
cd julia && ./setup.sh
cd php && ./setup.sh
cd ruby && ./setup.sh
cd elixir && ./setup.sh
cd scala && ./setup.sh
cd java && ./setup.sh
cd dotnet && ./setup.sh
cd kotlin && ./setup.sh
```

**Language-Specific Installation via Makefile:**
```sh
make install-python    # Python with pyenv and Poetry
make install-rust      # Rust with rustup and Cargo
make install-golang    # Go 1.21.5
make install-julia     # Julia 1.10.0
make install-php       # PHP with Composer
make install-nodejs    # Node.js with npm
make install-ruby      # Ruby with rbenv
make install-elixir    # Elixir with hex and rebar3
make install-scala     # Scala with SBT
make install-java      # Java with Maven
make install-dotnet    # .NET Core SDK 8.0
make install-kotlin    # Kotlin and Gradle via SDKMAN!
make install-all       # Install all languages
```

## Usage

### 1. Prepare your files
- Place your input PDF (e.g., `manual.pdf`) and optional Markdown file (e.g., `intro.md`) in the `resources/` directory.
- Configure your `config.yaml` in the `resources/` directory to specify which pages to extract.

### 2. Extract pages from PDF

**Choose your preferred language implementation:**

```sh
# Python implementation
make run-python

# Rust implementation
make run-rust

# Go implementation
make run-golang

# Julia implementation
make run-julia

# PHP implementation
make run-php

# Node.js implementation
make run-nodejs

# Ruby implementation
make run-ruby

# Elixir implementation
make run-elixir

# Scala implementation
make run-scala

# Java implementation
make run-java

# .NET Core implementation
make run-dotnet

# Kotlin implementation
make run-kotlin
```

All implementations:
- Extract PDF pages specified in `config.yaml`
- Create `extracted_pages.pdf` in the `output/` directory
- Support Markdown intro files as configured in the YAML

**Clean up:**
```sh
make clean-all    # Remove all generated PDFs and build artifacts
```

## Configuration

### YAML Configuration Structure

The `config.yaml` file controls the extraction process:

```yaml
file: resources/example_manual.pdf
output: output/extracted_pages.pdf
appendFirstPage: first_page.md
pages:
  - name: Introduction
    pageIndex: 5
    pageNumber: 3
  - name: Chapter 1 - Getting Started
    pageIndex: 10
    pageNumber: 8
```

### Page Configuration Fields

- **`name`**: Descriptive name for the page (for documentation)
- **`pageIndex`**: 1-based index of the page in the source PDF
- **`pageNumber`**: Optional display page number (for reference)

## Customization

- **Change pages to extract:** Edit `config.yaml` to add, remove, or reorder pages.
- **Change input/output files:** Edit the config file or run the extractor manually with custom arguments:

  ```sh
  # Python
  cd python && poetry run python -m pdf_extractor --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Rust
  cd rust && cargo run -- --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Go
  cd golang && go run . --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Julia
  cd julia && julia --project=. main.jl --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # PHP
  cd php && php src/main.php --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Node.js
  cd nodejs && npm start -- --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Ruby
  cd ruby && bundle exec ruby main.rb --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Elixir
  cd elixir && ./pdf_extractor --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Scala
  cd scala && sbt "run --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>"

  # Java
  cd java && mvn exec:java -Dexec.args="--input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>"

  # .NET Core
  cd dotnet && dotnet run -- --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>

  # Kotlin
  cd kotlin && gradle run --args="--input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>"
  ```

## File Locations

- **PDF and Markdown files** should be placed in the `resources/` directory.
- **Output PDFs** will be written to the `output/` directory.
- **Configuration file** (`config.yaml`) should be in the `resources/` directory.

## Features

- ✅ Extract specific pages from large PDF documents
- ✅ Add custom markdown introductions with professional styling
- ✅ Configurable via YAML
- ✅ Automatic duplicate page detection
- ✅ Support for tables and formatting in markdown
- ✅ Command-line interface for automation
- ✅ **12 language implementations** (Python, Rust, Go, Julia, PHP, Node.js, Ruby, Elixir, Scala, Java, .NET Core, Kotlin)
- ✅ Shared resources and consistent output across all languages
- ✅ Modular setup with individual language setup scripts
- ✅ Cross-platform support (Linux, macOS, Windows)

## Development

**Code formatting and linting:**
```sh
make format-all    # Format code in all languages
make lint-all      # Lint code in all languages
```

**Language-specific development tools:**
- **Python**: Poetry, Black, isort, flake8
- **Rust**: Cargo, rustfmt, clippy
- **Go**: go fmt, go vet
- **Julia**: Pkg, JuliaFormatter, Lint
- **PHP**: Composer, PHP CodeSniffer, PHPStan, PHP-CS-Fixer
- **Node.js**: npm, ESLint, Prettier
- **Ruby**: Bundler, RuboCop, RSpec
- **Elixir**: Mix, ExDoc, Credo
- **Scala**: SBT, ScalaStyle, Assembly plugin
- **Java**: Maven, exec plugin
- **Dotnet**: dotnet CLI, EditorConfig
- **Kotlin**: Gradle, SDKMAN!

## Architecture

### Modular Setup System
Each language has its own `setup.sh` script in its directory, allowing for:
- Independent language setup and maintenance
- Isolated dependency management
- Easier troubleshooting and development
- Parallel development across languages

### Shared Resources Architecture
- All language implementations share the same `resources/` directory for input files
- All implementations output to the same `output/` directory with language-specific suffixes
- Markdown-to-PDF conversion is centralized through a shared Node.js Puppeteer script
- Configuration is unified through YAML files

### Reference Implementation
The Go implementation (`golang/main.go`) serves as the simplest and most straightforward reference for creating new language implementations.

---

Choose your preferred language implementation or use this project to compare PDF processing approaches across **12 different programming languages**!
