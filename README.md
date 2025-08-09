# PDF Page Extractor

This project allows you to extract selected pages from a PDF document and optionally prepend a Markdown file as an introduction using a simple Makefile and Poetry for dependency management.

## Setup

0. **Install system dependencies:**
  ```sh
  sudo apt install --no-install-recommends make build-essential \
      libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
      wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev \
      libxmlsec1-dev libffi-dev liblzma-dev git
  curl -fsSL https://pyenv.run | bash
  curl -sSL https://install.python-poetry.org | python -

  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  export PATH="$HOME/.local/bin:$PATH"

  # Install Delta for enhanced Git diffs with syntax highlighting
  curl -fsSL https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-x86_64-unknown-linux-gnu.tar.gz | sudo tar -xzC /usr/local/bin --strip-components=1 delta-0.17.0-x86_64-unknown-linux-gnu/delta

  # Install bat for syntax highlighting (required by delta)
  sudo apt update && sudo apt install -y bat
  sudo ln -sf /usr/bin/batcat /usr/local/bin/bat

  # Install Chrome dependencies for Puppeteer (especially needed in WSL)
  sudo apt install -y libasound2t64 libatk-bridge2.0-0t64 libdrm2 libxkbcommon0 \
      libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxss1 libgtk-3-0t64 \
      libx11-xcb1 libxcb-dri3-0 libxcursor1 libxi6 libxtst6 libnss3

  # Configure Delta globally for all Git repositories
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.light false
  git config --global delta.side-by-side true
  git config --global delta.line-numbers true
  git config --global delta.syntax-theme "GitHub"
  git config --global delta.features "line-numbers decorations"
  git config --global delta.decorations.commit-decoration-style "blue ol"
  git config --global delta.decorations.file-style "omit"
  git config --global delta.decorations.hunk-header-decoration-style "blue box"
  git config --global merge.conflictstyle diff3
  git config --global diff.colorMoved default
  ```

1. **Install dependencies with Poetry:**
   ```sh
   make install
   ```

## Usage

### 1. Prepare your files
- Place your input PDF (e.g., `manual.pdf`) and optional Markdown file (e.g., `intro.md`) in the `resources/` directory.
- Configure your `config.yaml` in the `resources/` directory to specify which pages to extract.

### 2. Extract pages from PDF

- To extract the PDF pages specified in `config.yaml`:
  ```sh
  make run
  ```
  This will create `extracted_pages.pdf` in the `output/` directory.

- To extract pages with a Markdown intro at the front:
  ```sh
  make run-md
  ```
  This expects a file called `first_page.md` in the `resources/` directory. You can change the file name by editing the config or running the extractor manually.

- To remove generated PDFs:
  ```sh
  make clean
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
  poetry run python -m pdf_extractor --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>
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

---

If you have any issues or want to further customize the workflow, see the code in `pdf_extractor/__main__.py` or reach out for help!
