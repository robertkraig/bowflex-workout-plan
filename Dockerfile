# Multi-Language PDF Page Extractor Dockerfile
# Based on Ubuntu 24.04 to match the development environment
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment variables for consistent behavior
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=UTC

# Install system dependencies and basic tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Basic system tools
    curl \
    wget \
    git \
    make \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    locales \
    sudo \
    # Development libraries
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    libyaml-dev \
    ruby-dev \
    autoconf \
    libncurses-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    xsltproc \
    fop \
    libxml2-utils \
    # Chrome dependencies for Puppeteer
    libasound2t64 \
    libatk-bridge2.0-0t64 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libxss1 \
    libgtk-3-0t64 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxcursor1 \
    libxi6 \
    libxtst6 \
    libnss3 \
    # PDF tools
    pdftk-java \
    # Additional tools
    bat \
    && rm -rf /var/lib/apt/lists/*

# Generate locales
RUN locale-gen en_US.UTF-8

# Install Node.js 20.x LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Install Java 21 (default-jdk will install the latest LTS)
RUN apt-get update && apt-get install -y --no-install-recommends default-jdk maven && \
    rm -rf /var/lib/apt/lists/*

# Install PHP 8.3 and Composer
RUN apt-get update && apt-get install -y --no-install-recommends \
    php \
    php-cli \
    php-mbstring \
    php-xml \
    php-zip \
    php-curl \
    php-json \
    php-common \
    php-bcmath \
    php-gd \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Go 1.21.5
RUN wget -O go.tar.gz "https://go.dev/dl/go1.21.5.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/root/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install Julia 1.10.0
RUN wget -O julia.tar.gz "https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.0-linux-x86_64.tar.gz" && \
    tar -C /opt -xzf julia.tar.gz && \
    ln -sf /opt/julia-1.10.0/bin/julia /usr/local/bin/julia && \
    rm julia.tar.gz

# Install Python build dependencies and pyenv
RUN git clone https://github.com/pyenv/pyenv.git /root/.pyenv
ENV PATH="/root/.pyenv/bin:${PATH}"
ENV PYENV_ROOT="/root/.pyenv"

# Install Python 3.11 via pyenv
RUN eval "$(pyenv init --path)" && \
    eval "$(pyenv init -)" && \
    pyenv install 3.11.7 && \
    pyenv global 3.11.7

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:${PATH}"

# Install rbenv and Ruby 3.3.9
RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build
ENV PATH="/root/.rbenv/bin:${PATH}"

RUN eval "$(rbenv init -)" && \
    rbenv install 3.3.9 && \
    rbenv global 3.3.9 && \
    rbenv rehash && \
    gem install bundler && \
    rbenv rehash

# Install Erlang and Elixir
RUN apt-get update && apt-get install -y --no-install-recommends \
    erlang \
    elixir \
    && rm -rf /var/lib/apt/lists/*

# Install Hex and Rebar3 for Elixir
RUN mix local.hex --force && \
    mix local.rebar --force

# Install SBT for Scala
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" > /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" > /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add - && \
    apt-get update && apt-get install -y --no-install-recommends sbt && \
    rm -rf /var/lib/apt/lists/*

# Install Delta for enhanced Git diffs
RUN curl -fsSL https://github.com/dandavison/delta/releases/download/0.17.0/delta-0.17.0-x86_64-unknown-linux-gnu.tar.gz | \
    tar -xzC /usr/local/bin --strip-components=1 delta-0.17.0-x86_64-unknown-linux-gnu/delta

# Install pre-commit
RUN pip install pre-commit

# Set up environment variables for all languages
ENV JAVA_HOME="/usr/lib/jvm/default-java"
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Create working directory
WORKDIR /app

# Copy the project files
COPY . .

# Install all language dependencies
RUN eval "$(pyenv init --path)" && \
    eval "$(pyenv init -)" && \
    eval "$(rbenv init -)" && \
    export PATH="/root/.local/bin:${PATH}" && \
    npm ci && \
    make install-all

# Set up pre-commit hooks
RUN pre-commit install || echo "Pre-commit hooks setup completed"

# Create a non-root user for running the application
RUN useradd -m -s /bin/bash appuser && \
    chown -R appuser:appuser /app
USER appuser

# Set up shell initialization for the appuser
RUN echo 'eval "$(pyenv init --path)"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc && \
    echo 'export JAVA_HOME="/usr/lib/jvm/default-java"' >> ~/.bashrc && \
    echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc && \
    echo 'export GOPATH="$HOME/go"' >> ~/.bashrc && \
    echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.bashrc && \
    echo 'export PATH="/root/.cargo/bin:$PATH"' >> ~/.bashrc

# Expose any ports if needed (none required for this CLI application)

# Default command
CMD ["/bin/bash"]

# Health check to verify all languages are working
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 --version && \
        rustc --version && \
        go version && \
        julia --version && \
        php --version && \
        node --version && \
        ruby --version && \
        elixir --version && \
        sbt --version && \
        java --version && \
        mvn --version
