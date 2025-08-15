#!/bin/bash

# Rust PDF Page Extractor Setup Script
# This script sets up the Rust development environment and dependencies

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
            echo "This script sets up the Rust development environment."
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
    echo "Rust setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Rust setup..."
fi

echo "Starting Rust PDF Page Extractor setup..."

# Install Rust toolchain
echo "Installing Rust toolchain..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed"
fi

# Set up environment variables
echo "Setting up Rust environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Rust environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq '.cargo/bin' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_RUST'

# Rust configuration
export PATH="$HOME/.cargo/bin:$PATH"

ZSHRC_RUST
   fi
else
   # BASH Configuration
   if ! grep -Fq '.cargo/bin' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_RUST'

# Rust configuration
export PATH="$HOME/.cargo/bin:$PATH"

BASHRC_RUST
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Rust dependencies
echo "Installing Rust dependencies..."
if [ -f "Cargo.toml" ]; then
    cargo build
fi

# Create setup completion marker
echo "Creating Rust setup completion marker..."
touch "$SETUP_MARKER"

echo "Rust setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Rust with rustup and Cargo"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Rust dependencies"
echo "  make run        # Run Rust implementation"
echo "  make lint       # Run Rust linting"
echo "  make format     # Format Rust code"
