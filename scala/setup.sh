#!/bin/bash

# Scala PDF Page Extractor Setup Script
# This script sets up the Scala development environment and dependencies

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
            echo "This script sets up the Scala development environment."
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
    echo "Scala setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Scala setup..."
fi

echo "Starting Scala PDF Page Extractor setup..."

# Install Scala and SBT
echo "Installing Scala and SBT..."
if ! command -v sbt &> /dev/null; then
    # Install SBT from official repository
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add -
    sudo apt update
    sudo apt install -y sbt

    echo "SBT installation completed"
else
    echo "SBT is already installed"
fi

# Set up environment variables
echo "Setting up Scala environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Scala environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq 'SBT configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_SCALA'

# SBT configuration
export PATH="$HOME/.sbt/1.0/bin:$PATH"

ZSHRC_SCALA
   fi
else
   # BASH Configuration
   if ! grep -Fq 'SBT configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_SCALA'

# SBT configuration
export PATH="$HOME/.sbt/1.0/bin:$PATH"

BASHRC_SCALA
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Scala dependencies
echo "Installing Scala dependencies..."
if [ -f "build.sbt" ]; then
    sbt compile
fi

# Create setup completion marker
echo "Creating Scala setup completion marker..."
touch "$SETUP_MARKER"

echo "Scala setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Scala with SBT"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Scala dependencies"
echo "  make run        # Run Scala implementation"
echo "  make lint       # Run Scala linting"
echo "  make format     # Format Scala code"
