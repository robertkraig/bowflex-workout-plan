#!/bin/bash

# Multi-Language PDF Page Extractor Setup Script
# This script sets up the development environment and dependencies for Python, Rust, Go, Julia, PHP, and Node.js
# It uses a dirty-bit mechanism to avoid running setup multiple times

set -e  # Exit on any error

SETUP_MARKER=".setup_complete"

# Check if setup has already been completed
if [ -f "$SETUP_MARKER" ]; then
    echo "Setup has already been completed. If you need to re-run setup, delete the '$SETUP_MARKER' file."
    exit 0
fi

echo "Starting Multi-Language PDF Page Extractor setup..."

# Install system dependencies
echo "Installing system dependencies..."
sudo apt install --no-install-recommends make build-essential \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev \
    libxmlsec1-dev libffi-dev liblzma-dev git

# Install pyenv
echo "Installing pyenv..."
if ! command -v pyenv &> /dev/null; then
    curl -fsSL https://pyenv.run | bash
else
    echo "pyenv is already installed"
fi

# Install Poetry
echo "Installing Poetry..."
if ! command -v poetry &> /dev/null; then
    curl -sSL https://install.python-poetry.org | python -
else
    echo "Poetry is already installed"
fi

# Install Rust toolchain
echo "Installing Rust toolchain..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed"
fi

# Install Go
echo "Installing Go..."
if ! command -v go &> /dev/null; then
    GO_VERSION="1.21.5"
    wget -O go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go.tar.gz
    rm go.tar.gz
else
    echo "Go is already installed"
fi

# Install Julia
echo "Installing Julia..."
if ! command -v julia &> /dev/null; then
    JULIA_VERSION="1.10.0"
    wget -O julia.tar.gz "https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-${JULIA_VERSION}-linux-x86_64.tar.gz"
    sudo tar -C /opt -xzf julia.tar.gz
    sudo ln -sf /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia
    rm julia.tar.gz
else
    echo "Julia is already installed"
fi

# Install PHP
echo "Installing PHP..."
if ! command -v php &> /dev/null; then
    sudo apt update
    sudo apt install -y php php-cli php-mbstring php-xml php-zip php-curl php-json php-common php-bcmath php-gd

    # Install Composer
    echo "Installing Composer..."
    if ! command -v composer &> /dev/null; then
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
        sudo chmod +x /usr/local/bin/composer
    else
        echo "Composer is already installed"
    fi
else
    echo "PHP is already installed"

    # Still check for Composer
    if ! command -v composer &> /dev/null; then
        echo "Installing Composer..."
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
        sudo chmod +x /usr/local/bin/composer
    else
        echo "Composer is already installed"
    fi
fi

# Install Node.js and npm
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

# Set up environment variables
echo "Setting up environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure pyenv for zsh and bash appropriately
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # Ensure pyenv is initialized in zshrc (interactive shells)
   if ! grep -Fq 'eval "$(pyenv init -)"' "$SHELL_RC" && ! grep -Fq 'eval "$(pyenv init -)"' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_PYENV'

# pyenv configuration (zsh)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export PATH="$HOME/.local/bin:$PATH"

# Rust configuration
export PATH="$HOME/.cargo/bin:$PATH"

# Go configuration
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Julia configuration
export PATH="/usr/local/bin:$PATH"

# PHP configuration
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Node.js configuration
export PATH="$HOME/.local/lib/nodejs/bin:$PATH"

ZSHRC_PYENV
   fi

   # For zsh login shells, ensure pyenv --path is in .zprofile
   ZPROFILE="$HOME/.zprofile"
   [ -f "$ZPROFILE" ] || touch "$ZPROFILE"
   if ! grep -Fq 'eval "$(pyenv init --path)"' "$ZPROFILE"; then
cat >> "$ZPROFILE" <<'ZPROFILE_PYENV'

# pyenv in PATH for zsh login shells
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

ZPROFILE_PYENV
   fi
else
   # Bash fallback: add pyenv init to bashrc
   if ! grep -Fq 'export PYENV_ROOT="$HOME/.pyenv"' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_PYENV'

# pyenv configuration (bash)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export PATH="$HOME/.local/bin:$PATH"

# Rust configuration
export PATH="$HOME/.cargo/bin:$PATH"

# Go configuration
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Julia configuration
export PATH="/usr/local/bin:$PATH"

# PHP configuration
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Node.js configuration
export PATH="$HOME/.local/lib/nodejs/bin:$PATH"

BASHRC_PYENV
   fi
fi

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

# Install Chrome dependencies for Puppeteer and PDF tools
echo "Installing Chrome dependencies for Puppeteer and PDF tools..."
sudo apt install -y libasound2t64 libatk-bridge2.0-0t64 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxss1 libgtk-3-0t64 \
    libx11-xcb1 libxcb-dri3-0 libxcursor1 libxi6 libxtst6 libnss3 \
    pdftk-java

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

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install dependencies for all languages
echo "Installing dependencies for all languages..."
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
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
echo ""
echo "To reset and re-run setup in the future, delete the '$SETUP_MARKER' file and run this script again."
