#!/bin/bash

# Multi-Language PDF Extractor Docker Helper Script
# This script provides convenient commands for Docker operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if docker-compose is available
check_docker_compose() {
    if ! command -v docker-compose > /dev/null 2>&1; then
        print_error "docker-compose is not installed. Please install docker-compose and try again."
        exit 1
    fi
}

# Build the Docker image
build() {
    print_info "Building Docker image..."
    check_docker

    docker build -t multi-lang-pdf-extractor .
    print_success "Docker image built successfully!"
}

# Start the development environment
start() {
    print_info "Starting development environment..."
    check_docker
    check_docker_compose

    docker-compose up -d
    print_success "Development environment started!"
    print_info "Access with: ./docker-run.sh shell"
    print_info "Or run commands with: ./docker-run.sh exec <command>"
}

# Stop the development environment
stop() {
    print_info "Stopping development environment..."
    check_docker_compose

    docker-compose down
    print_success "Development environment stopped!"
}

# Access container shell
shell() {
    print_info "Accessing container shell..."
    check_docker_compose

    if ! docker-compose ps | grep -q pdf-extractor; then
        print_warning "Container not running. Starting it first..."
        start
        sleep 2
    fi

    docker-compose exec pdf-extractor bash
}

# Execute command in container
exec_cmd() {
    if [ $# -eq 0 ]; then
        print_error "No command provided. Usage: ./docker-run.sh exec <command>"
        exit 1
    fi

    print_info "Executing: $*"
    check_docker_compose

    if ! docker-compose ps | grep -q pdf-extractor; then
        print_warning "Container not running. Starting it first..."
        start
        sleep 2
    fi

    docker-compose exec pdf-extractor "$@"
}

# Run all language implementations
run_all() {
    print_info "Running all language implementations..."
    exec_cmd make run-all
    print_success "All implementations completed! Check output/ directory for PDFs."
}

# Run specific language
run_language() {
    if [ $# -eq 0 ]; then
        print_error "No language provided. Usage: ./docker-run.sh run <language>"
        print_info "Available languages: python, rust, golang, julia, php, nodejs, ruby, elixir, scala, java"
        exit 1
    fi

    language=$1
    print_info "Running $language implementation..."
    exec_cmd make "run-$language"
    print_success "$language implementation completed!"
}

# Install dependencies for all languages
install_all() {
    print_info "Installing dependencies for all languages..."
    exec_cmd make install-all
    print_success "All dependencies installed!"
}

# Clean build artifacts
clean() {
    print_info "Cleaning build artifacts..."
    exec_cmd make clean-all
    print_success "Clean completed!"
}

# Show logs
logs() {
    check_docker_compose
    docker-compose logs -f
}

# Show status
status() {
    check_docker_compose
    print_info "Container status:"
    docker-compose ps

    print_info "Docker images:"
    docker images | grep multi-lang-pdf-extractor || echo "No images found"
}

# Health check
health() {
    print_info "Running health check..."
    exec_cmd python3 --version
    exec_cmd rustc --version
    exec_cmd go version
    exec_cmd julia --version
    exec_cmd php --version
    exec_cmd node --version
    exec_cmd ruby --version
    exec_cmd elixir --version
    exec_cmd sbt --version
    exec_cmd java --version
    exec_cmd mvn --version
    print_success "All languages are working!"
}

# Reset environment (rebuild everything)
reset() {
    print_warning "This will remove containers and rebuild everything. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_info "Resetting environment..."
        docker-compose down -v
        docker image rm multi-lang-pdf-extractor 2>/dev/null || true
        build
        start
        install_all
        print_success "Environment reset complete!"
    else
        print_info "Reset cancelled."
    fi
}

# Show help
show_help() {
    echo "Multi-Language PDF Extractor Docker Helper"
    echo
    echo "Usage: ./docker-run.sh <command> [args]"
    echo
    echo "Commands:"
    echo "  build           Build Docker image"
    echo "  start           Start development environment"
    echo "  stop            Stop development environment"
    echo "  shell           Access container shell"
    echo "  exec <cmd>      Execute command in container"
    echo "  run-all         Run all language implementations"
    echo "  run <lang>      Run specific language (python, rust, golang, etc.)"
    echo "  install-all     Install dependencies for all languages"
    echo "  clean           Clean build artifacts"
    echo "  logs            Show container logs"
    echo "  status          Show container and image status"
    echo "  health          Run health check for all languages"
    echo "  reset           Reset entire environment (rebuild)"
    echo "  help            Show this help message"
    echo
    echo "Examples:"
    echo "  ./docker-run.sh start"
    echo "  ./docker-run.sh run-all"
    echo "  ./docker-run.sh run python"
    echo "  ./docker-run.sh exec make run-java"
    echo "  ./docker-run.sh shell"
}

# Main command dispatcher
case "${1:-help}" in
    build)
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    shell)
        shell
        ;;
    exec)
        shift
        exec_cmd "$@"
        ;;
    run-all)
        run_all
        ;;
    run)
        shift
        run_language "$@"
        ;;
    install-all)
        install_all
        ;;
    clean)
        clean
        ;;
    logs)
        logs
        ;;
    status)
        status
        ;;
    health)
        health
        ;;
    reset)
        reset
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac
