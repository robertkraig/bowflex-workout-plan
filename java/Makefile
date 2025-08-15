# Makefile for Java pdf-page-extractor

# Try to find Maven binary, fallback to system PATH
MVN := $(shell which mvn 2>/dev/null || echo mvn)

# Auto-detect JAVA_HOME if not set
JAVA_HOME ?= $(shell if [ -d "/usr/lib/jvm/default-java" ]; then echo "/usr/lib/jvm/default-java"; elif [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then echo "/usr/lib/jvm/java-21-openjdk-amd64"; elif [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then echo "/usr/lib/jvm/java-11-openjdk-amd64"; else dirname $$(dirname $$(readlink -f $$(which java))) 2>/dev/null || echo "/usr/lib/jvm/default-java"; fi)

.PHONY: install compile run run-md clean format lint

install:
	JAVA_HOME=$(JAVA_HOME) $(MVN) dependency:resolve

compile:
	JAVA_HOME=$(JAVA_HOME) $(MVN) compile

run:
	mkdir -p ../output
	JAVA_HOME=$(JAVA_HOME) $(MVN) exec:java -Dexec.args="--yaml ../resources/config.yaml"

run-md:
	mkdir -p ../output
	JAVA_HOME=$(JAVA_HOME) $(MVN) exec:java -Dexec.args="--yaml ../resources/config.yaml"

format:
	@echo "Java formatting not configured (use IDE or add spotless plugin)"

lint:
	JAVA_HOME=$(JAVA_HOME) $(MVN) compile

clean:
	JAVA_HOME=$(JAVA_HOME) $(MVN) clean
	rm -f ../output/*_java.pdf
