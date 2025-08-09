# Start from Ubuntu base
FROM ubuntu/python:3.13-25.04_stable

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install pyenv
ENV PYENV_ROOT="/root/.pyenv"
ENV PATH="$PYENV_ROOT/bin:$PATH"
RUN apt update && apt install -y curl bash sh
RUN curl https://pyenv.run | bash && \
    echo 'eval "$(pyenv init --path)"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /root/.local/bin/poetry /usr/local/bin/poetry

# Fix Node version if needed (or leave system-installed)
RUN apt-get update && apt-get install -y --no-install-recommends curl gnupg ca-certificates &&  \
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && apt-get install -y nodejs

# Set working directory
WORKDIR /workspace
