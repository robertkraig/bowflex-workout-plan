#!/bin/bash

# Multi-Language PDF Page Extractor Setup Script
# This script sets up the development environment and dependencies for Python, Rust, Go, Julia, PHP, Node.js, Ruby, Elixir, and Scala
# It uses a dirty-bit mechanism to avoid running setup multiple times

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
            echo "This script sets up the development environment for all supported languages."
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
    echo "Setup has already been completed. Use -f or --force flag to re-run setup."
    exit 0
fi

if [ "$FORCE_SETUP" = true ]; then
    echo "Force flag detected - re-running setup..."
fi

echo "Starting Multi-Language PDF Page Extractor setup..."

# Install system dependencies
echo "Installing system dependencies..."
sudo apt install --no-install-recommends make build-essential \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev \
    libxmlsec1-dev libffi-dev liblzma-dev git libyaml-dev ruby-dev \
    autoconf libncurses-dev libgl1-mesa-dev libglu1-mesa-dev \
    libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils

# Install optional wxWidgets packages for Erlang Observer (GUI tools)
echo "Installing optional wxWidgets packages for Erlang..."
sudo apt install --no-install-recommends libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev 2>/dev/null || \
sudo apt install --no-install-recommends libwxgtk3.2-dev 2>/dev/null || \
sudo apt install --no-install-recommends libwxbase3.0-dev libwxgtk3.0-dev 2>/dev/null || \
echo "Warning: wxWidgets packages not found - Erlang Observer GUI will not be available"

# Install pyenv
echo "Installing pyenv..."
if ! command -v pyenv &> /dev/null; then
    curl -fsSL https://pyenv.run | bash
else
    echo "pyenv is already installed"
fi

# Install Poetry
echo "Installing Poetry..."
if ! command -v poetry &> /dev/null; then
    curl -sSL https://install.python-poetry.org | python -
else
    echo "Poetry is already installed"
fi

# Install Rust toolchain
echo "Installing Rust toolchain..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed"
fi

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

# Install Node.js and npm
echo "Installing Node.js..."
if ! command -v node &> /dev/null; then
    # Install Node.js using NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "Node.js is already installed"
fi

# Ensure npm is installed
if ! command -v npm &> /dev/null; then
    echo "Installing npm..."
    sudo apt install -y npm
else
    echo "npm is already installed"
fi

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
echo "Setting up environment variables..."

# Choose appropriate shell rc
if [ -f "$HOME/.zshrc" ]; then
   SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
   SHELL_RC="$HOME/.bashrc"
else
   SHELL_RC="$HOME/.bashrc"
   touch "$SHELL_RC"
fi

# Configure each environment independently for both zsh and bash
if [ "$SHELL_RC" = "$HOME/.zshrc" ]; then
   # ZSH Configuration - check each environment separately

   # Python/pyenv configuration
   if ! grep -Fq 'pyenv init -' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_PYENV'

# pyenv configuration (zsh)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
export PATH="$HOME/.local/bin:$PATH"

ZSHRC_PYENV
   fi

   # For zsh login shells, ensure pyenv --path is in .zprofile
   ZPROFILE="$HOME/.zprofile"
   [ -f "$ZPROFILE" ] || touch "$ZPROFILE"
   if ! grep -Fq 'pyenv init --path' "$ZPROFILE"; then
cat >> "$ZPROFILE" <<'ZPROFILE_PYENV'

# pyenv in PATH for zsh login shells
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"

ZPROFILE_PYENV
   fi

   # Rust configuration
   if ! grep -Fq '.cargo/bin' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_RUST'

# Rust configuration
export PATH="$HOME/.cargo/bin:$PATH"

ZSHRC_RUST
   fi

   # Go configuration
   if ! grep -Fq '/usr/local/go/bin' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_GO'

# Go configuration
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

ZSHRC_GO
   fi

   # Julia configuration
   if ! grep -Fq 'Julia configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_JULIA'

# Julia configuration
export PATH="/usr/local/bin:$PATH"

ZSHRC_JULIA
   fi

   # PHP configuration
   if ! grep -Fq '.composer/vendor/bin' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_PHP'

# PHP configuration
export PATH="$HOME/.composer/vendor/bin:$PATH"

ZSHRC_PHP
   fi

   # Node.js configuration
   if ! grep -Fq '.local/lib/nodejs/bin' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_NODEJS'

# Node.js configuration
export PATH="$HOME/.local/lib/nodejs/bin:$PATH"

ZSHRC_NODEJS
   fi

   # Ruby configuration
   if ! grep -Fq 'rbenv init' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_RUBY'

# Ruby configuration
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"

ZSHRC_RUBY
   fi

   # Elixir configuration (installed via system packages)
   if ! grep -Fq 'Elixir is installed via system packages' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_ELIXIR'

# Elixir configuration (installed via system packages)
# Elixir is installed via system packages and should be in PATH

ZSHRC_ELIXIR
   fi

   # Scala/SBT configuration
   if ! grep -Fq 'SBT configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_SCALA'

# SBT configuration
export PATH="$HOME/.sbt/1.0/bin:$PATH"

ZSHRC_SCALA
   fi

   # Java/Maven configuration
   if ! grep -Fq 'Java configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_JAVA'

# Java configuration
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))) 2>/dev/null || echo "/usr/lib/jvm/default-java")
export PATH="$JAVA_HOME/bin:$PATH"

ZSHRC_JAVA
   fi

   # .NET Core configuration
   if ! grep -Fq '.NET Core configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_DOTNET'

# .NET Core configuration
export DOTNET_ROOT="/usr/share/dotnet"
export PATH="$DOTNET_ROOT:$PATH"

ZSHRC_DOTNET
   fi

   # Kotlin configuration
   if ! grep -Fq 'SDKMAN configuration' "$HOME/.zshrc"; then
cat >> "$HOME/.zshrc" <<'ZSHRC_KOTLIN'

# SDKMAN configuration
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

ZSHRC_KOTLIN
   fi

else
   # BASH Configuration - check each environment separately

   # Python/pyenv configuration
   if ! grep -Fq 'pyenv init -' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_PYENV'

# pyenv configuration (bash)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
export PATH="$HOME/.local/bin:$PATH"

BASHRC_PYENV
   fi

   # Rust configuration
   if ! grep -Fq '.cargo/bin' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_RUST'

# Rust configuration
export PATH="$HOME/.cargo/bin:$PATH"

BASHRC_RUST
   fi

   # Go configuration
   if ! grep -Fq '/usr/local/go/bin' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_GO'

# Go configuration
export PATH="/usr/local/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

BASHRC_GO
   fi

   # Julia configuration
   if ! grep -Fq 'Julia configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_JULIA'

# Julia configuration
export PATH="/usr/local/bin:$PATH"

BASHRC_JULIA
   fi

   # PHP configuration
   if ! grep -Fq '.composer/vendor/bin' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_PHP'

# PHP configuration
export PATH="$HOME/.composer/vendor/bin:$PATH"

BASHRC_PHP
   fi

   # Node.js configuration
   if ! grep -Fq '.local/lib/nodejs/bin' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_NODEJS'

# Node.js configuration
export PATH="$HOME/.local/lib/nodejs/bin:$PATH"

BASHRC_NODEJS
   fi

   # Ruby configuration
   if ! grep -Fq 'rbenv init' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_RUBY'

# Ruby configuration
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"

BASHRC_RUBY
   fi

   # Elixir configuration (installed via system packages)
   if ! grep -Fq 'Elixir is installed via system packages' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_ELIXIR'

# Elixir configuration (installed via system packages)
# Elixir is installed via system packages and should be in PATH

BASHRC_ELIXIR
   fi

   # Scala/SBT configuration
   if ! grep -Fq 'SBT configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_SCALA'

# SBT configuration
export PATH="$HOME/.sbt/1.0/bin:$PATH"

BASHRC_SCALA
   fi

   # Java/Maven configuration
   if ! grep -Fq 'Java configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_JAVA'

# Java configuration
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))) 2>/dev/null || echo "/usr/lib/jvm/default-java")
export PATH="$JAVA_HOME/bin:$PATH"

BASHRC_JAVA
   fi

   # .NET Core configuration
   if ! grep -Fq '.NET Core configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_DOTNET'

# .NET Core configuration
export DOTNET_ROOT="/usr/share/dotnet"
export PATH="$DOTNET_ROOT:$PATH"

BASHRC_DOTNET
   fi

   # Kotlin configuration
   if ! grep -Fq 'SDKMAN configuration' "$SHELL_RC"; then
cat >> "$SHELL_RC" <<'BASHRC_KOTLIN'

# SDKMAN configuration
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

BASHRC_KOTLIN
   fi

fi

# Install Delta for enhanced Git diffs
echo "Installing Delta for enhanced Git diffs..."
if ! command -v delta &> /dev/null; then
    curl -fsSL https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-x86_64-unknown-linux-gnu.tar.gz | sudo tar -xzC /usr/local/bin --strip-components=1 delta-0.17.0-x86_64-unknown-linux-gnu/delta
else
    echo "Delta is already installed"
fi

# Install bat for syntax highlighting
echo "Installing bat for syntax highlighting..."
if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
    sudo apt update && sudo apt install -y bat
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
else
    echo "bat is already installed"
fi

# Install Chrome dependencies for Puppeteer and PDF tools
echo "Installing Chrome dependencies for Puppeteer and PDF tools..."
sudo apt install -y libasound2t64 libatk-bridge2.0-0t64 libdrm2 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxrandr2 libgbm1 libxss1 libgtk-3-0t64 \
    libx11-xcb1 libxcb-dri3-0 libxcursor1 libxi6 libxtst6 libnss3 \
    pdftk-java

# Configure Delta globally for all Git repositories
echo "Configuring Delta globally..."
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.syntax-theme "GitHub"
git config --global delta.features "line-numbers decorations"
git config --global delta.decorations.commit-decoration-style "blue ol"
git config --global delta.decorations.file-style "omit"
git config --global delta.decorations.hunk-header-decoration-style "blue box"
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default

# Source environment to make sure new tools are available
source "$SHELL_RC" 2>/dev/null || true

# Install pre-commit for code quality hooks
echo "Installing pre-commit for code quality hooks..."
pip install pre-commit
pre-commit install

# Install dependencies for all languages
echo "Installing dependencies for all languages..."
export PATH="/usr/local/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
make install-all

# Create setup completion marker
echo "Creating setup completion marker..."
touch "$SETUP_MARKER"

echo "Multi-language setup completed successfully!"
echo ""
echo "Installed toolchains:"
echo "  ✅ Python with pyenv and Poetry"
echo "  ✅ Rust with rustup and Cargo"
echo "  ✅ Go 1.21.5"
echo "  ✅ Julia 1.10.0"
echo "  ✅ PHP with Composer"
echo "  ✅ Node.js with npm and Puppeteer dependencies"
echo "  ✅ Ruby with rbenv"
echo "  ✅ Elixir with hex and rebar3"
echo "  ✅ Scala with SBT"
echo "  ✅ Java with Maven (auto-detected version)"
echo "  ✅ .NET Core SDK 8.0"
echo "  ✅ Kotlin and Gradle via SDKMAN!"
echo "  ✅ Pre-commit hooks for code quality"
echo ""
echo "You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to ensure all environment variables are loaded."
echo ""
echo "Quick start:"
echo "  make run-python    # Run Python implementation"
echo "  make run-rust      # Run Rust implementation"
echo "  make run-golang    # Run Go implementation"
echo "  make run-julia     # Run Julia implementation"
echo "  make run-php       # Run PHP implementation"
echo "  make run-nodejs    # Run Node.js implementation"
echo "  make run-ruby      # Run Ruby implementation"
echo "  make run-elixir    # Run Elixir implementation"
echo "  make run-scala     # Run Scala implementation"
echo "  make run-java      # Run Java implementation"
echo "  make run-dotnet    # Run .NET Core implementation"
echo "  make run-kotlin    # Run Kotlin implementation"
echo ""
echo "To re-run setup in the future:"
echo "  ./setup.sh -f      # Force re-run without deleting marker file"
echo "  ./setup.sh --help  # Show help message"
echo ""
echo "Alternatively, delete the '$SETUP_MARKER' file and run this script again."
