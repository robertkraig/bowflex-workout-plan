# Makefile for pdf-page-extractor project using Poetry

.PHONY: install run clean format lint fix-line-endings setup-hooks

init:
	pyenv install -s 3.11.9
	pyenv local 3.11.9
	poetry env use 3.11.9
	poetry install
	npm ci
	$(MAKE) setup-hooks

install:
	poetry install

run:
	mkdir -p output
	poetry run python -m pdf_extractor --yaml resources/config.yaml

run-md:
	mkdir -p output
	poetry run python -m pdf_extractor --yaml resources/config.yaml

# Code formatting and linting
format:
	poetry run black .
	poetry run isort .

lint:
	poetry run flake8 .
	poetry run black --check .
	poetry run isort --check-only .

# Setup pre-commit hooks
setup-hooks:
	poetry run pre-commit install
	poetry run pre-commit autoupdate

# Fix line endings to Unix format (LF)
fix-line-endings:
	@echo "Converting line endings to Unix format (LF)..."
	find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.txt" -o -name "*.toml" \) -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./.*cache*" -exec dos2unix {} \; 2>/dev/null || true
	@echo "Line endings conversion complete."

# Run pre-commit on all files
check-all:
	poetry run pre-commit run --all-files

clean:
	rm -f output/*.pdf
