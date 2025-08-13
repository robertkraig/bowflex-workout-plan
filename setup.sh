#!/bin/bash

# PDF Page Extractor Setup Script
# This script sets up the development environment and dependencies
# It uses a dirty-bit mechanism to avoid running setup multiple times

set -e  # Exit on any error

SETUP_MARKER=".setup_complete"

# Check if setup has already been completed
if [ -f "$SETUP_MARKER" ]; then
    echo "Setup has already been completed. If you need to re-run setup, delete the '$SETUP_MARKER' file."
    exit 0
fi

echo "Starting PDF Page Extractor setup..."

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

# Install Chrome dependencies for Puppeteer
echo "Installing Chrome dependencies for Puppeteer..."
sudo apt install -y libasound2t64 libatk-bridge2.0-0t64 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxss1 libgtk-3-0t64 \
    libx11-xcb1 libxcb-dri3-0 libxcursor1 libxi6 libxtst6 libnss3

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

# Install Python dependencies with Poetry
echo "Installing Python dependencies with Poetry..."
make install

# Create setup completion marker
echo "Creating setup completion marker..."
touch "$SETUP_MARKER"

echo "Setup completed successfully!"
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "To reset and re-run setup in the future, delete the '$SETUP_MARKER' file and run this script again."
