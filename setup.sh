#!/bin/bash

# Multi-Language PDF Page Extractor Setup Script
# This script sets up system dependencies, Node.js, and runs language-specific setup scripts
# It uses a dirty-bit mechanism to avoid running setup multiple times

set -e  # Exit on any error

SETUP_MARKER=".setup_complete"
FORCE_SETUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_SETUP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --force    Force re-run setup even if already completed"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "This script sets up the development environment for all supported languages."
            echo "By default, it will skip setup if the '$SETUP_MARKER' file exists."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information."
            exit 1
            ;;
    esac
done

# Check if setup has already been completed (unless force flag is used)
if [ -f "$SETUP_MARKER" ] && [ "$FORCE_SETUP" = false ]; then
    echo "Setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running setup..."
fi

echo "Starting Multi-Language PDF Page Extractor setup..."

# Install system dependencies
echo "Installing system dependencies..."
sudo apt install --no-install-recommends make build-essential \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev \
    libxmlsec1-dev libffi-dev liblzma-dev git libyaml-dev ruby-dev \
    autoconf libncurses-dev libgl1-mesa-dev libglu1-mesa-dev \
    libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils

# Install Node.js and npm (required for Puppeteer)
echo "Installing Node.js..."
if ! command -v node &> /dev/null; then
    # Install Node.js using NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "Node.js is already installed"
fi

# Ensure npm is installed
if ! command -v npm &> /dev/null; then
    echo "Installing npm..."
    sudo apt install -y npm
else
    echo "npm is already installed"
fi

# Install Chrome dependencies for Puppeteer and PDF tools
echo "Installing Chrome dependencies for Puppeteer and PDF tools..."
sudo apt install -y libasound2t64 libatk-bridge2.0-0t64 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxss1 libgtk-3-0t64 \
    libx11-xcb1 libxcb-dri3-0 libxcursor1 libxi6 libxtst6 libnss3 \
    pdftk-java

# Install Delta for enhanced Git diffs
echo "Installing Delta for enhanced Git diffs..."
if ! command -v delta &> /dev/null; then
    curl -fsSL https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-x86_64-unknown-linux-gnu.tar.gz | sudo tar -xzC /usr/local/bin --strip-components=1 delta-0.17.0-x86_64-unknown-linux-gnu/delta
else
    echo "Delta is already installed"
fi

# Install bat for syntax highlighting
echo "Installing bat for syntax highlighting..."
if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
    sudo apt update && sudo apt install -y bat
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
else
    echo "bat is already installed"
fi

# Configure Delta globally for all Git repositories
echo "Configuring Delta globally..."
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

# Install pre-commit for code quality hooks
echo "Installing pre-commit for code quality hooks..."
pip install pre-commit
pre-commit install

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
if [ -f "nodejs/package.json" ]; then
    cd nodejs && npm install && cd ..
fi

# Run language-specific setup scripts
echo "Running language-specific setup scripts..."

# Pass force flag to language setups if provided
LANG_SETUP_ARGS=""
if [ "$FORCE_SETUP" = true ]; then
    LANG_SETUP_ARGS="--force"
fi

LANGUAGES=(
    "python"
    "php"
    "rust"
    "golang"
    "julia"
    "ruby"
    "elixir"
    "scala"
    "java"
    "dotnet"
    "kotlin"
)

for lang in "${LANGUAGES[@]}"; do
    if [ -d "$lang" ] && [ -f "$lang/setup.sh" ]; then
        echo "Setting up $lang..."
        cd "$lang"
        ./setup.sh $LANG_SETUP_ARGS
        cd ..
    else
        echo "Warning: $lang directory or setup.sh not found, skipping..."
    fi
done

# Install dependencies for all languages
echo "Installing dependencies for all languages..."
make install-all

# Create setup completion marker
echo "Creating setup completion marker..."
touch "$SETUP_MARKER"

echo "Multi-language setup completed successfully!"
echo ""
echo "Installed toolchains:"
echo "  ✅ Python with pyenv and Poetry"
echo "  ✅ Rust with rustup and Cargo"
echo "  ✅ Go 1.21.5"
echo "  ✅ Julia 1.10.0"
echo "  ✅ PHP with Composer"
echo "  ✅ Node.js with npm and Puppeteer dependencies"
echo "  ✅ Ruby with rbenv"
echo "  ✅ Elixir with hex and rebar3"
echo "  ✅ Scala with SBT"
echo "  ✅ Java with Maven (auto-detected version)"
echo "  ✅ .NET Core SDK 8.0"
echo "  ✅ Kotlin and Gradle via SDKMAN!"
echo "  ✅ Pre-commit hooks for code quality"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make run-python    # Run Python implementation"
echo "  make run-rust      # Run Rust implementation"
echo "  make run-golang    # Run Go implementation"
echo "  make run-julia     # Run Julia implementation"
echo "  make run-php       # Run PHP implementation"
echo "  make run-nodejs    # Run Node.js implementation"
echo "  make run-ruby      # Run Ruby implementation"
echo "  make run-elixir    # Run Elixir implementation"
echo "  make run-scala     # Run Scala implementation"
echo "  make run-java      # Run Java implementation"
echo "  make run-dotnet    # Run .NET Core implementation"
echo "  make run-kotlin    # Run Kotlin implementation"
echo ""
echo "To re-run setup in the future:"
echo "  ./setup.sh -f      # Force re-run without deleting marker file"
echo "  ./setup.sh --help  # Show help message"
echo ""
echo "Alternatively, delete the '$SETUP_MARKER' file and run this script again."
