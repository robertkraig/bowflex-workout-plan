.PHONY: install run clean lint format format-fix format-check check-deps

check-deps:
	@which php > /dev/null 2>&1 || (echo "PHP is not installed. Please install PHP first." && exit 1)
	@which composer > /dev/null 2>&1 || (echo "Composer is not installed. Please install Composer first." && exit 1)

install: check-deps
	composer install

run:
	php src/main.php

clean:
	rm -rf vendor/ composer.lock .php-cs-fixer.cache

# Original PSR-12 linting with PHP_CodeSniffer
lint:
	./vendor/bin/phpcs src/ --standard=PSR12

# Original PSR-12 formatting with PHP_CodeSniffer
format:
	./vendor/bin/phpcbf src/ --standard=PSR12

# Advanced formatting with PHP-CS-Fixer (dry-run to check what would change)
format-check:
	./vendor/bin/php-cs-fixer fix --dry-run --diff

# Advanced formatting with PHP-CS-Fixer (actually apply changes)
format-fix:
	./vendor/bin/php-cs-fixer fix

# PHPStan static analysis
stan:
	./vendor/bin/phpstan analyse
