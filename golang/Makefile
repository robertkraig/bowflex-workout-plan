# Makefile for Go pdf-page-extractor

# Try to find Go binary, fallback to system PATH
GO := $(shell which go 2>/dev/null || echo /usr/local/go/bin/go)

.PHONY: build run run-md clean format lint install tidy

install:
	$(GO) mod download

tidy:
	$(GO) mod tidy

build:
	$(GO) build -o pdf-extractor .

run:
	mkdir -p ../output
	$(GO) run . --yaml ../resources/config.yaml

run-md:
	mkdir -p ../output
	$(GO) run . --yaml ../resources/config.yaml

format:
	$(GO) fmt ./...

lint:
	$(GO) vet ./...

clean:
	rm -f pdf-extractor
	rm -f ../output/*.pdf
