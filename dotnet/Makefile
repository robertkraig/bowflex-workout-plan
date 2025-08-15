# .NET Core PDF Extractor Makefile

.PHONY: install run clean lint format

# Install dependencies
install:
	@echo "Installing .NET dependencies..."
	dotnet restore

# Run the application
run:
	@echo "Running .NET PDF extractor..."
	dotnet run

# Clean build artifacts
clean:
	@echo "Cleaning .NET build artifacts..."
	dotnet clean
	rm -rf bin/ obj/

# Lint (static analysis)
lint:
	@echo "Running .NET static analysis..."
	dotnet build --verbosity normal --configuration Release

# Format code
format:
	@echo "Formatting .NET code..."
	dotnet format

# Build the application
build:
	@echo "Building .NET application..."
	dotnet build --configuration Release

# Publish the application
publish:
	@echo "Publishing .NET application..."
	dotnet publish --configuration Release --output publish/
