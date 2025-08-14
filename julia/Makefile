# Makefile for Julia pdf-page-extractor

.PHONY: install instantiate run run-md clean format lint test

install:
	julia --project=. -e 'using Pkg; Pkg.instantiate()'

instantiate: install

run:
	mkdir -p ../output
	julia --project=. main.jl --yaml ../resources/config.yaml

run-md:
	mkdir -p ../output
	julia --project=. main.jl --yaml ../resources/config.yaml

format:
	julia --project=. -e 'using JuliaFormatter; format(".")'

lint:
	julia --project=. -e 'using Pkg; Pkg.add("Lint"); using Lint; lintdir(".")'

test:
	julia --project=. -e 'using Pkg; Pkg.test()'

clean:
	rm -f ../output/*.pdf
	julia --project=. -e 'using Pkg; Pkg.gc()'
