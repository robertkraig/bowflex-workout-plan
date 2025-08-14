<?php

declare(strict_types=1);

$config = new PhpCsFixer\Config();

return $config
    ->setRiskyAllowed(true)
    ->setRules([
        '@PSR12' => true,
        '@PSR12:risky' => true,
        '@PHP80Migration' => true,
        '@PHP80Migration:risky' => true,

        // Array formatting
        'array_syntax' => ['syntax' => 'short'],
        'trailing_comma_in_multiline' => [
            'elements' => ['arrays', 'arguments', 'parameters'],
        ],
        'array_indentation' => true,

        // Blank line rules for double spacing effect
        'blank_line_before_statement' => [
            'statements' => [
                'break',
                'case',
                'continue',
                'declare',
                'default',
                'exit',
                'goto',
                'include',
                'include_once',
                'phpdoc',
                'require',
                'require_once',
                'return',
                'switch',
                'throw',
                'try',
                'yield',
                'yield_from',
            ],
        ],
        'blank_line_after_opening_tag' => true,
        'blank_line_after_namespace' => true,

        // Method and function spacing
        'method_chaining_indentation' => true,
        'no_spaces_around_offset' => true,
        'spaces_inside_parentheses' => false,

        // Import ordering and grouping
        'ordered_imports' => [
            'imports_order' => ['class', 'function', 'const'],
            'sort_algorithm' => 'alpha',
        ],
        'global_namespace_import' => [
            'import_classes' => false,
            'import_constants' => false,
            'import_functions' => false,
        ],

        // Docblock improvements
        'phpdoc_align' => [
            'align' => 'vertical',
        ],
        'phpdoc_separation' => true,
        'phpdoc_summary' => false,
        'phpdoc_to_comment' => false,

        // Strict comparisons and type improvements
        'strict_comparison' => true,
        'strict_param' => true,
        'declare_strict_types' => true,

        // Code style improvements
        'concat_space' => ['spacing' => 'one'],
        'operator_linebreak' => ['only_booleans' => true],
        'multiline_whitespace_before_semicolons' => ['strategy' => 'no_multi_line'],

        // Additional spacing and readability rules
        'binary_operator_spaces' => [
            'default' => 'single_space',
            'operators' => [
                '=>' => 'single_space',
                '=' => 'single_space',
            ],
        ],
        'unary_operator_spaces' => true,
        'ternary_operator_spaces' => true,

        // Class and method organization
        'class_attributes_separation' => [
            'elements' => [
                'const' => 'one',
                'method' => 'one',
                'property' => 'one',
                'trait_import' => 'none',
            ],
        ],
        'single_class_element_per_statement' => [
            'elements' => ['const', 'property'],
        ],

        // String and quote normalization
        'single_quote' => true,
        'escape_implicit_backslashes' => true,

        // Additional modern PHP features
        'nullable_type_declaration_for_default_null_value' => true,
        'return_type_declaration' => ['space_before' => 'none'],
    ])
    ->setFinder(
        PhpCsFixer\Finder::create()
            ->exclude('vendor')
            ->in(__DIR__ . '/src')
    )
    ->setCacheFile(__DIR__ . '/.php-cs-fixer.cache');
