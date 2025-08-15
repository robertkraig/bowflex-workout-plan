# Makefile for Scala pdf-page-extractor

# Try to find SBT binary, fallback to system PATH
SBT := $(shell which sbt 2>/dev/null || echo sbt)

.PHONY: build run run-md clean format lint install compile assembly

install:
	$(SBT) compile

compile:
	$(SBT) compile

build:
	$(SBT) assembly

assembly:
	$(SBT) assembly

run:
	mkdir -p ../output
	$(SBT) "runMain PdfExtractor --yaml ../resources/config.yaml"

run-md:
	mkdir -p ../output
	$(SBT) "runMain PdfExtractor --yaml ../resources/config.yaml"

format:
	$(SBT) scalafmt

lint:
	$(SBT) scalastyle

clean:
	$(SBT) clean
	rm -f target/scala-*/pdf-extractor-assembly-*.jar
	rm -f ../output/*_scala.pdf
