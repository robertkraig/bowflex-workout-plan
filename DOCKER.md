# Docker Usage Guide

This document provides comprehensive instructions for running the Multi-Language PDF Page Extractor in Docker containers.

## Quick Start

### Build and Run with Docker

```bash
# Build the Docker image
docker build -t multi-lang-pdf-extractor .

# Run interactively
docker run -it --rm \
  -v $(pwd)/output:/app/output \
  multi-lang-pdf-extractor

# Inside the container, run any language implementation
make run-python
make run-golang
make run-java
# ... or any other supported language
```

### Using Docker Compose (Recommended)

```bash
# Start the development environment
docker-compose up -d

# Execute commands in the running container
docker-compose exec pdf-extractor make run-all

# Access the container shell
docker-compose exec pdf-extractor bash

# Stop and remove containers
docker-compose down
```

## Docker Image Details

### Base Image
- **Ubuntu 24.04**: Matches the development environment
- **Multi-architecture support**: Works on x86_64 and ARM64

### Installed Languages and Tools

| Language | Version | Package Manager | Status |
|----------|---------|----------------|---------|
| Python   | 3.11.7  | pip, Poetry    | ✅ Ready |
| Rust     | Latest  | Cargo          | ✅ Ready |
| Go       | 1.21.5  | go mod         | ✅ Ready |
| Julia    | 1.10.0  | Pkg            | ✅ Ready |
| PHP      | 8.3     | Composer       | ✅ Ready |
| Node.js  | 20.x LTS| npm            | ✅ Ready |
| Ruby     | 3.3.9   | Bundler        | ✅ Ready |
| Elixir   | Latest  | Mix            | ✅ Ready |
| Scala    | Latest  | SBT            | ✅ Ready |
| Java     | 21      | Maven          | ✅ Ready |

### Additional Tools
- **pdftk-java**: PDF manipulation toolkit
- **Puppeteer dependencies**: Chrome headless browser support
- **Git**: Version control
- **Delta**: Enhanced git diffs
- **Pre-commit**: Code quality hooks

## Development Workflow

### 1. Interactive Development

```bash
# Start development environment
docker-compose up -d

# Access container shell
docker-compose exec pdf-extractor bash

# Make changes to code (mounted as volume)
# Run tests for specific language
make run-python
make run-golang
make run-java

# Run all implementations
make run-all
```

### 2. One-off Commands

```bash
# Run specific language without entering container
docker-compose exec pdf-extractor make run-python

# Run all languages and generate PDFs
docker-compose exec pdf-extractor make run-all

# Check installed versions
docker-compose exec pdf-extractor make --version
docker-compose exec pdf-extractor python3 --version
docker-compose exec pdf-extractor java --version
```

### 3. Build and Test Cycle

```bash
# Install dependencies for all languages
docker-compose exec pdf-extractor make install-all

# Format all code
docker-compose exec pdf-extractor make format-all

# Lint all code
docker-compose exec pdf-extractor make lint-all

# Clean build artifacts
docker-compose exec pdf-extractor make clean-all
```

## Volume Mounts

### Default Mounts (docker-compose.yml)

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `.` | `/app` | Source code (live editing) |
| `./output` | `/app/output` | Generated PDF files |
| `pdf-extractor-node-modules` | `/app/node_modules` | Node.js dependencies cache |
| `pdf-extractor-cargo` | `/root/.cargo` | Rust dependencies cache |
| `pdf-extractor-go` | `/root/go` | Go dependencies cache |

### Custom Volume Mounts

```bash
# Mount custom resources directory
docker run -it --rm \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/custom-resources:/app/resources \
  multi-lang-pdf-extractor

# Mount custom configuration
docker run -it --rm \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/custom-config.yaml:/app/resources/config.yaml \
  multi-lang-pdf-extractor
```

## Environment Variables

### Available Variables

```bash
# Set Java version (if needed)
JAVA_HOME=/usr/lib/jvm/default-java

# Set Go workspace
GOPATH=/root/go

# Set Python environment
PYENV_ROOT=/root/.pyenv

# Set Ruby environment
RBENV_ROOT=/root/.rbenv
```

### Custom Environment

```bash
# Run with custom environment
docker run -it --rm \
  -e CUSTOM_VAR=value \
  -v $(pwd)/output:/app/output \
  multi-lang-pdf-extractor
```

## Troubleshooting

### Common Issues

#### 1. Permission Issues
```bash
# Fix file permissions
docker-compose exec pdf-extractor chown -R appuser:appuser /app/output
```

#### 2. Dependencies Not Found
```bash
# Reinstall all dependencies
docker-compose exec pdf-extractor make install-all

# Or rebuild image
docker-compose build --no-cache
```

#### 3. Out of Space
```bash
# Clean up Docker system
docker system prune -a

# Remove unused volumes
docker volume prune
```

#### 4. Language-Specific Issues

**Python Issues:**
```bash
docker-compose exec pdf-extractor pyenv versions
docker-compose exec pdf-extractor poetry env info
```

**Node.js Issues:**
```bash
docker-compose exec pdf-extractor npm ls
docker-compose exec pdf-extractor node --version
```

**Java Issues:**
```bash
docker-compose exec pdf-extractor java -version
docker-compose exec pdf-extractor mvn --version
docker-compose exec pdf-extractor echo $JAVA_HOME
```

### Health Check

The Docker image includes a health check that verifies all languages:

```bash
# Check container health
docker inspect multi-lang-pdf-extractor | grep Health -A 10

# Manual health check
docker-compose exec pdf-extractor python3 --version
docker-compose exec pdf-extractor rustc --version
docker-compose exec pdf-extractor go version
docker-compose exec pdf-extractor julia --version
# ... etc for all languages
```

## Production Usage

### Optimized Production Build

```bash
# Build production image
docker build -t multi-lang-pdf-extractor:prod \
  --target production \
  .

# Run production container
docker run --rm \
  -v $(pwd)/input:/app/resources \
  -v $(pwd)/output:/app/output \
  multi-lang-pdf-extractor:prod \
  make run-all
```

### CI/CD Integration

```yaml
# Example GitHub Actions workflow
- name: Build and Test
  run: |
    docker build -t pdf-extractor .
    docker run --rm pdf-extractor make run-all

- name: Extract Artifacts
  run: |
    docker create --name extract pdf-extractor
    docker cp extract:/app/output ./artifacts
    docker rm extract
```

## Performance Optimization

### Build Cache Optimization

```bash
# Use BuildKit for faster builds
DOCKER_BUILDKIT=1 docker build -t multi-lang-pdf-extractor .

# Use multi-stage builds (already implemented)
docker build --target development -t pdf-extractor:dev .
```

### Runtime Optimization

```bash
# Limit container resources
docker run --rm \
  --memory=2g \
  --cpus=2.0 \
  multi-lang-pdf-extractor
```

## Security Considerations

### Running as Non-Root

The container runs as `appuser` (non-root) by default for security.

### Network Isolation

```bash
# Run with no network access (if external dependencies not needed)
docker run --rm --network=none multi-lang-pdf-extractor
```

### Read-Only Root Filesystem

```bash
# Run with read-only root filesystem
docker run --rm --read-only \
  --tmpfs /tmp \
  --tmpfs /var/tmp \
  multi-lang-pdf-extractor
```

## Support

For Docker-specific issues:
1. Check container logs: `docker-compose logs`
2. Verify health check: `docker-compose ps`
3. Test individual languages: `docker-compose exec pdf-extractor <command>`
4. Rebuild if needed: `docker-compose build --no-cache`

For application issues, refer to the main README.md and CLAUDE.md documentation.
