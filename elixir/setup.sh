#!/bin/bash

# Elixir PDF Page Extractor Setup Script
# This script sets up the Elixir development environment and dependencies

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
            echo "This script sets up the Elixir development environment."
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
    echo "Elixir setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Elixir setup..."
fi

echo "Starting Elixir PDF Page Extractor setup..."

# Install optional wxWidgets packages for Erlang Observer (GUI tools)
echo "Installing optional wxWidgets packages for Erlang..."
sudo apt install --no-install-recommends libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev 2>/dev/null || \
sudo apt install --no-install-recommends libwxgtk3.2-dev 2>/dev/null || \
sudo apt install --no-install-recommends libwxbase3.0-dev libwxgtk3.0-dev 2>/dev/null || \
echo "Warning: wxWidgets packages not found - Erlang Observer GUI will not be available"

# Install Elixir using Ubuntu packages (faster and more reliable)
echo "Installing Elixir..."
if ! command -v elixir &> /dev/null; then
    # Install Erlang and Elixir from Ubuntu repositories
    echo "Installing Erlang and Elixir packages from Ubuntu repositories..."
    sudo apt update
    sudo apt install -y erlang elixir

    # Install Hex package manager
    echo "Installing Hex package manager..."
    mix local.hex --force

    # Install Rebar3 build tool
    echo "Installing Rebar3..."
    mix local.rebar --force

    echo "Elixir installation completed"
else
    echo "Elixir is already installed"

    # Ensure Hex and Rebar3 are installed
    if ! mix help hex &> /dev/null; then
        echo "Installing Hex package manager..."
        mix local.hex --force
    fi

    if ! mix help rebar &> /dev/null; then
        echo "Installing Rebar3..."
        mix local.rebar --force
    fi
fi

# Set up environment variables
echo "Setting up Elixir environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Elixir environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq 'Elixir is installed via system packages' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_ELIXIR'

# Elixir configuration (installed via system packages)
# Elixir is installed via system packages and should be in PATH

ZSHRC_ELIXIR
   fi
else
   # BASH Configuration
   if ! grep -Fq 'Elixir is installed via system packages' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_ELIXIR'

# Elixir configuration (installed via system packages)
# Elixir is installed via system packages and should be in PATH

BASHRC_ELIXIR
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Elixir dependencies
echo "Installing Elixir dependencies..."
if [ -f "mix.exs" ]; then
    mix deps.get
fi

# Create setup completion marker
echo "Creating Elixir setup completion marker..."
touch "$SETUP_MARKER"

echo "Elixir setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Elixir with hex and rebar3"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Elixir dependencies"
echo "  make run        # Run Elixir implementation"
echo "  make lint       # Run Elixir linting"
echo "  make format     # Format Elixir code"
