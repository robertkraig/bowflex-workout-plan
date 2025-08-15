#!/bin/bash

# Java PDF Page Extractor Setup Script
# This script sets up the Java development environment and dependencies

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
            echo "This script sets up the Java development environment."
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
    echo "Java setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running Java setup..."
fi

echo "Starting Java PDF Page Extractor setup..."

# Install Java and Maven
echo "Installing Java and Maven..."
if ! command -v java &> /dev/null || ! command -v javac &> /dev/null; then
    sudo apt update
    sudo apt install -y default-jdk openjdk-21-jdk
    echo "Java installation completed"
else
    echo "Java is already installed ($(java -version 2>&1 | head -n1))"
    # Check if javac is missing and install JDK if needed
    if ! command -v javac &> /dev/null; then
        echo "Java compiler (javac) not found - installing JDK..."
        sudo apt update
        sudo apt install -y default-jdk openjdk-21-jdk
    fi
fi

if ! command -v mvn &> /dev/null; then
    sudo apt install -y maven
    echo "Maven installation completed"
else
    echo "Maven is already installed"
fi

# Set up environment variables
echo "Setting up Java environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure Java environment
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration
   if ! grep -Fq 'Java configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_JAVA'

# Java configuration
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))) 2>/dev/null || echo "/usr/lib/jvm/default-java")
export PATH="$JAVA_HOME/bin:$PATH"

ZSHRC_JAVA
   fi
else
   # BASH Configuration
   if ! grep -Fq 'Java configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_JAVA'

# Java configuration
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))) 2>/dev/null || echo "/usr/lib/jvm/default-java")
export PATH="$JAVA_HOME/bin:$PATH"

BASHRC_JAVA
   fi
fi

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install Java dependencies
echo "Installing Java dependencies..."
if [ -f "pom.xml" ]; then
    mvn compile
fi

# Create setup completion marker
echo "Creating Java setup completion marker..."
touch "$SETUP_MARKER"

echo "Java setup completed successfully!"
echo ""
echo "Installed:"
echo "  ✅ Java with Maven (auto-detected version)"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make install    # Install Java dependencies"
echo "  make run        # Run Java implementation"
echo "  make lint       # Run Java linting"
echo "  make format     # Format Java code"
