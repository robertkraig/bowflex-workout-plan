.PHONY: install run clean lint format check-deps

check-deps:
	@which node > /dev/null 2>&1 || (echo "Node.js is not installed. Please install Node.js first." && exit 1)
	@which npm > /dev/null 2>&1 || (echo "npm is not installed. Please install npm first." && exit 1)

install: check-deps
	npm install

run:
	npm start

clean:
	rm -rf node_modules/ package-lock.json

lint:
	npm run lint

format:
	npm run format
