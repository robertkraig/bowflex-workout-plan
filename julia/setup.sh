#!/bin/bash

# Julia PDF Page Extractor Setup Script
# This script sets up the Julia development environment and dependencies

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
            echo "This script sets up the Julia development environment."
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
    echo "Julia setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Julia setup..."
fi

echo "Starting Julia PDF Page Extractor setup..."

# Install Julia
echo "Installing Julia..."
if ! command -v julia &> /dev/null; then
    JULIA_VERSION="1.10.0"
    wget -O julia.tar.gz "https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-${JULIA_VERSION}-linux-x86_64.tar.gz"
    sudo tar -C /opt -xzf julia.tar.gz
    sudo ln -sf /opt/julia-${JULIA_VERSION}/bin/julia /usr/local/bin/julia
    rm julia.tar.gz
else
    echo "Julia is already installed"
fi

# Set up environment variables
echo "Setting up Julia environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Julia environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq 'Julia configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_JULIA'

# Julia configuration
export PATH="/usr/local/bin:$PATH"

ZSHRC_JULIA
   fi
else
   # BASH Configuration
   if ! grep -Fq 'Julia configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_JULIA'

# Julia configuration
export PATH="/usr/local/bin:$PATH"

BASHRC_JULIA
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Julia dependencies
echo "Installing Julia dependencies..."
if [ -f "Project.toml" ]; then
    julia --project=. -e 'using Pkg; Pkg.instantiate()'
fi

# Create setup completion marker
echo "Creating Julia setup completion marker..."
touch "$SETUP_MARKER"

echo "Julia setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Julia 1.10.0"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Julia dependencies"
echo "  make run        # Run Julia implementation"
echo "  make lint       # Run Julia linting"
echo "  make format     # Format Julia code"
