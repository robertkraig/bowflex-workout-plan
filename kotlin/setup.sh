#!/bin/bash

# Kotlin PDF Page Extractor Setup Script
# This script sets up the Kotlin development environment and dependencies

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
            echo "This script sets up the Kotlin development environment."
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
    echo "Kotlin setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Kotlin setup..."
fi

echo "Starting Kotlin PDF Page Extractor setup..."

# Install Kotlin and Gradle via SDKMAN!
echo "Installing Kotlin and Gradle via SDKMAN!..."
if ! command -v kotlin &> /dev/null || ! command -v gradle &> /dev/null; then
    # Install SDKMAN! for Kotlin and Gradle installation
    if [ ! -d "$HOME/.sdkman" ]; then
        echo "Installing SDKMAN!..."
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    else
        echo "SDKMAN! is already installed"
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi

    # Install Kotlin if not present
    if ! command -v kotlin &> /dev/null; then
        echo "Installing Kotlin..."
        sdk install kotlin
    else
        echo "Kotlin is already installed"
    fi

    # Install Gradle if not present
    if ! command -v gradle &> /dev/null; then
        echo "Installing Gradle..."
        sdk install gradle
    else
        echo "Gradle is already installed"
    fi

    echo "Kotlin and Gradle installation completed"
else
    echo "Kotlin and Gradle are already installed"
    echo "  Kotlin: $(kotlin -version 2>&1 | head -n1)"
    echo "  Gradle: $(gradle --version 2>&1 | head -n1)"
fi

# Set up environment variables
echo "Setting up Kotlin environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Kotlin environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq 'SDKMAN configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_KOTLIN'

# SDKMAN configuration
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

ZSHRC_KOTLIN
   fi
else
   # BASH Configuration
   if ! grep -Fq 'SDKMAN configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_KOTLIN'

# SDKMAN configuration
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

BASHRC_KOTLIN
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Kotlin dependencies
echo "Installing Kotlin dependencies..."
if [ -f "build.gradle.kts" ] || [ -f "build.gradle" ]; then
    gradle build
fi

# Create setup completion marker
echo "Creating Kotlin setup completion marker..."
touch "$SETUP_MARKER"

echo "Kotlin setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Kotlin and Gradle via SDKMAN!"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Kotlin dependencies"
echo "  make run        # Run Kotlin implementation"
echo "  make lint       # Run Kotlin linting"
echo "  make format     # Format Kotlin code"
