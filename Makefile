# Makefile for pdf-page-extractor project using Poetry

.PHONY: install run clean

init:
	pyenv install -s 3.11.9
	pyenv local 3.11.9
	poetry env use 3.11.9
	poetry install
	npm ci

install:
	poetry install

run:
	mkdir -p output
	poetry run python -m pdf_extractor --yaml resources/config.yaml

run-md:
	mkdir -p output
	poetry run python -m pdf_extractor --yaml resources/config.yaml

clean:
	rm -f output/*.pdf
