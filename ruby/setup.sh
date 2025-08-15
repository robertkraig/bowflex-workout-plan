#!/bin/bash

# Ruby PDF Page Extractor Setup Script
# This script sets up the Ruby development environment and dependencies

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
            echo "This script sets up the Ruby development environment."
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
    echo "Ruby setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Ruby setup..."
fi

echo "Starting Ruby PDF Page Extractor setup..."

# Install rbenv and Ruby
echo "Installing rbenv and Ruby..."
if [ ! -d "$HOME/.rbenv" ] && ! command -v rbenv &> /dev/null; then
    # Install rbenv
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv

    # Install ruby-build plugin
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

    echo "rbenv installed"
else
    echo "rbenv is already installed"
fi

# Install Ruby 3.1.0 and bundler
if [ -d "$HOME/.rbenv" ]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"

    # Install Ruby 3.3.9 if not already installed
    if ! rbenv versions | grep -q "3.3.9"; then
        echo "Installing Ruby 3.3.9..."
        rbenv install 3.3.9
    else
        echo "Ruby 3.3.9 is already installed"
    fi

    # Set global Ruby version
    rbenv global 3.3.9
    rbenv rehash

    # Install bundler
    if ! gem list bundler -i &> /dev/null; then
        echo "Installing bundler..."
        gem install bundler
        rbenv rehash
    else
        echo "bundler is already installed"
    fi
fi

# Set up environment variables
echo "Setting up Ruby environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Ruby environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq 'rbenv init' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_RUBY'

# Ruby configuration
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"

ZSHRC_RUBY
   fi
else
   # BASH Configuration
   if ! grep -Fq 'rbenv init' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_RUBY'

# Ruby configuration
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"

BASHRC_RUBY
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Ruby dependencies
echo "Installing Ruby dependencies..."
if [ -f "Gemfile" ]; then
    bundle install
fi

# Create setup completion marker
echo "Creating Ruby setup completion marker..."
touch "$SETUP_MARKER"

echo "Ruby setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Ruby with rbenv"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Ruby dependencies"
echo "  make run        # Run Ruby implementation"
echo "  make lint       # Run Ruby linting"
echo "  make format     # Format Ruby code"
