#!/bin/bash

# Python PDF Page Extractor Setup Script
# This script sets up the Python development environment and dependencies

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
            echo "This script sets up the Python development environment."
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
    echo "Python setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Python setup..."
fi

echo "Starting Python PDF Page Extractor setup..."

# Install pyenv if not present
echo "Installing pyenv..."
if ! command -v pyenv &> /dev/null; then
    curl -fsSL https://pyenv.run | bash
else
    echo "pyenv is already installed"
fi

# Install Poetry if not present
echo "Installing Poetry..."
if ! command -v poetry &> /dev/null; then
    curl -sSL https://install.python-poetry.org | python -
else
    echo "Poetry is already installed"
fi

# Set up environment variables
echo "Setting up Python environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Python environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq 'pyenv init -' "$HOME/.zshrc"; then
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
   if ! grep -Fq 'pyenv init --path' "$ZPROFILE"; then
cat >> "$ZPROFILE" <<'ZPROFILE_PYENV'

# pyenv in PATH for zsh login shells
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

ZPROFILE_PYENV
   fi
else
   # BASH Configuration
   if ! grep -Fq 'pyenv init -' "$SHELL_RC"; then
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

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Python dependencies
echo "Installing Python dependencies..."
if [ -f "pyproject.toml" ]; then
    poetry install
elif [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

# Create setup completion marker
echo "Creating Python setup completion marker..."
touch "$SETUP_MARKER"

echo "Python setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Python with pyenv and Poetry"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Python dependencies"
echo "  make run        # Run Python implementation"
echo "  make lint       # Run Python linting"
echo "  make format     # Format Python code"
