# PDF Extractor - Elixir Implementation

This is the Elixir implementation of the PDF page extractor tool.

## Dependencies

- Elixir 1.16.0+ with OTP 26
- Erlang/OTP 26
- `pdftk` for PDF manipulation
- Node.js (for Puppeteer-based Markdown to PDF conversion)

## Installation

```bash
# Install dependencies
make install

# Or manually:
mix deps.get
mix compile
```

## Usage

```bash
# Run with default configuration
make run

# Or manually:
mix escript.build
./pdf_extractor --yaml ../resources/config.yaml

# Show help
./pdf_extractor --help
```

## Development

```bash
# Format code
make format

# Run linter
make lint

# Run tests
make test

# Clean build artifacts
make clean
```

## Architecture

The Elixir implementation follows the same patterns as other language implementations:

- **PdfExtractor.CLI**: Command-line interface and argument parsing
- **PdfExtractor.Core**: Main extraction logic and orchestration
- **PdfExtractor.MarkdownConverter**: Markdown to PDF conversion using Puppeteer
- **PdfExtractor**: Main module with delegation

The implementation uses:
- **YamlElixir** for YAML configuration parsing
- **Earmark** for Markdown to HTML conversion
- **pdftk** via system commands for PDF manipulation
- **Puppeteer** (via Node.js) for HTML to PDF conversion
