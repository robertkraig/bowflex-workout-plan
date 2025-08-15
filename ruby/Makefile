.PHONY: install run clean lint format check-deps bundle-check

check-deps:
	@which ruby > /dev/null 2>&1 || (echo "Ruby is not installed. Please install Ruby first." && exit 1)
	@which bundle > /dev/null 2>&1 || (echo "Bundler is not installed. Please install with 'gem install bundler'." && exit 1)

install: check-deps
	bundle install

bundle-check:
	bundle check || bundle install

run: bundle-check
	bundle exec ruby main.rb

clean:
	rm -rf vendor/ .bundle/ Gemfile.lock coverage/

lint:
	bundle exec rubocop

format:
	bundle exec rubocop --autocorrect-all

# Ruby-specific quality checks
audit:
	bundle audit

outdated:
	bundle outdated

# RSpec tests (when implemented)
test:
	bundle exec rspec

# Generate documentation
doc:
	bundle exec yard doc
