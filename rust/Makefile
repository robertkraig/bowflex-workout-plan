# Makefile for Rust pdf-page-extractor

.PHONY: build run run-md clean format lint install

install:
	cargo build

build:
	cargo build --release

run:
	mkdir -p ../output
	cargo run -- --yaml ../resources/config.yaml

run-md:
	mkdir -p ../output
	cargo run -- --yaml ../resources/config.yaml

format:
	cargo fmt

lint:
	cargo clippy

clean:
	cargo clean
	rm -f ../output/*.pdf
