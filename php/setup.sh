#!/bin/bash

# PHP PDF Page Extractor Setup Script
# This script sets up the PHP development environment and dependencies

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
            echo "This script sets up the PHP development environment."
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
    echo "PHP setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running PHP setup..."
fi

echo "Starting PHP PDF Page Extractor setup..."

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

# Set up environment variables
echo "Setting up PHP environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure PHP environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq '.composer/vendor/bin' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_PHP'

# PHP configuration
export PATH="$HOME/.composer/vendor/bin:$PATH"

ZSHRC_PHP
   fi
else
   # BASH Configuration
   if ! grep -Fq '.composer/vendor/bin' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_PHP'

# PHP configuration
export PATH="$HOME/.composer/vendor/bin:$PATH"

BASHRC_PHP
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install PHP dependencies
echo "Installing PHP dependencies..."
if [ -f "composer.json" ]; then
    composer install
fi

# Create setup completion marker
echo "Creating PHP setup completion marker..."
touch "$SETUP_MARKER"

echo "PHP setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ PHP with Composer"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install PHP dependencies"
echo "  make run        # Run PHP implementation"
echo "  make lint       # Run PHP linting"
echo "  make format     # Format PHP code"
