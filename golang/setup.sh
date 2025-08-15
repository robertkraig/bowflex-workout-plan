#!/bin/bash

# Go PDF Page Extractor Setup Script
# This script sets up the Go development environment and dependencies

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
            echo "This script sets up the Go development environment."
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
    echo "Go setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Go setup..."
fi

echo "Starting Go PDF Page Extractor setup..."

# Install Go
echo "Installing Go..."
if [ ! -d "/usr/local/go" ] && ! command -v go &> /dev/null; then
    GO_VERSION="1.21.5"
    wget -O go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go.tar.gz
    rm go.tar.gz
else
    echo "Go is already installed"
fi

# Set up environment variables
echo "Setting up Go environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Go environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq '/usr/local/go/bin' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_GO'

# Go configuration
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

ZSHRC_GO
   fi
else
   # BASH Configuration
   if ! grep -Fq '/usr/local/go/bin' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_GO'

# Go configuration
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

BASHRC_GO
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Go dependencies
echo "Installing Go dependencies..."
export PATH="/usr/local/go/bin:$PATH"
if [ -f "go.mod" ]; then
    go mod download
fi

# Create setup completion marker
echo "Creating Go setup completion marker..."
touch "$SETUP_MARKER"

echo "Go setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Go 1.21.5"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Go dependencies"
echo "  make run        # Run Go implementation"
echo "  make lint       # Run Go linting"
echo "  make format     # Format Go code"
