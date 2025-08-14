# Multi-Language PDF Page Extractor

This project allows you to extract selected pages from a PDF document and optionally prepend a Markdown file as an introduction. The same functionality is implemented in multiple programming languages: **Python**, **Rust**, **Go**, and **Julia**.

## Language Implementations

- **`python/`** - Original Python implementation using PyPDF2 and Poetry
- **`rust/`** - Rust implementation using lopdf and Cargo
- **`golang/`** - Go implementation using unipdf and Go modules
- **`julia/`** - Julia implementation using Poppler and native package manager

All implementations share the same resources and output directories, and use the same Node.js Puppeteer script for Markdown-to-PDF conversion.

## Setup

**Quick Setup for All Languages:**
```sh
./setup.sh          # Install system dependencies and Python environment
make install-all    # Install dependencies for all languages
```

**Language-Specific Setup:**
```sh
# Python only
make install-python

# Rust only
make install-rust

# Go only
make install-golang

# Julia only
make install-julia
```

The setup script installs system dependencies, Python environment, and Node.js dependencies needed for Puppeteer PDF generation.

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
- ✅ **Multi-language implementations** (Python, Rust, Go, Julia)
- ✅ Shared resources and consistent output across all languages

## Development

**Code formatting and linting:**
```sh
make format-all    # Format code in all languages
make lint-all      # Lint code in all languages
```

**Language-specific development:**
- **Python**: Uses Poetry, Black, isort, flake8
- **Rust**: Uses Cargo, rustfmt, clippy
- **Go**: Uses go fmt, go vet
- **Julia**: Uses Pkg, JuliaFormatter, Lint

---

Choose your preferred language implementation or use this project to compare PDF processing approaches across Python, Rust, Go, and Julia!
