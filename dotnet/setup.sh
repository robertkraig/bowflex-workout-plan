#!/bin/bash

# .NET PDF Page Extractor Setup Script
# This script sets up the .NET development environment and dependencies

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
            echo "This script sets up the .NET development environment."
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
    echo ".NET setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running .NET setup..."
fi

echo "Starting .NET PDF Page Extractor setup..."

# Install .NET Core SDK
echo "Installing .NET Core SDK..."
if ! command -v dotnet &> /dev/null; then
    # Download Microsoft package repository configuration
    wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    # Install .NET SDK
    sudo apt update
    sudo apt install -y dotnet-sdk-8.0
    echo ".NET Core SDK installation completed"
else
    echo ".NET Core SDK is already installed ($(dotnet --version 2>/dev/null || echo 'version detection failed'))"
fi

# Set up environment variables
echo "Setting up .NET environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure .NET environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq '.NET Core configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_DOTNET'

# .NET Core configuration
export DOTNET_ROOT="/usr/share/dotnet"
export PATH="$DOTNET_ROOT:$PATH"

ZSHRC_DOTNET
   fi
else
   # BASH Configuration
   if ! grep -Fq '.NET Core configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_DOTNET'

# .NET Core configuration
export DOTNET_ROOT="/usr/share/dotnet"
export PATH="$DOTNET_ROOT:$PATH"

BASHRC_DOTNET
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install .NET dependencies
echo "Installing .NET dependencies..."
if [ -f "*.csproj" ] || [ -f "*.sln" ]; then
    dotnet restore
fi

# Create setup completion marker
echo "Creating .NET setup completion marker..."
touch "$SETUP_MARKER"

echo ".NET setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ .NET Core SDK 8.0"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install .NET dependencies"
echo "  make run        # Run .NET implementation"
echo "  make lint       # Run .NET linting"
echo "  make format     # Format .NET code"
