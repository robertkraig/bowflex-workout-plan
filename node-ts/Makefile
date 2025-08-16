.PHONY: install run clean lint format typecheck build check-deps

check-deps:
	@which node > /dev/null 2>&1 || (echo "Node.js is not installed. Please install Node.js first." && exit 1)
	@which npm > /dev/null 2>&1 || (echo "npm is not installed. Please install npm first." && exit 1)

install: check-deps
	npm install

run: build
	node dist/main.js

build:
	npm run build

typecheck:
	npm run typecheck

clean:
	rm -rf node_modules/ package-lock.json dist/

lint:
	npm run lint

format:
	npm run format
