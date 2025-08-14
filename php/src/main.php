<?php

declare(strict_types=1);

require_once __DIR__ . '/../vendor/autoload.php';

use PdfExtractor\PdfExtractor;
use Symfony\Component\Yaml\Yaml;

// CLI handling
$options = getopt('', ['input:', 'output:', 'yaml:', 'markdown:']);

$configPath = '../resources/config.yaml';
$config = [];

if (file_exists($configPath)) {
    $config = Yaml::parseFile($configPath);
    if (!is_array($config)) {
        throw new \RuntimeException('Invalid YAML configuration file');
    }
}

$defaultInput = $config['file'] ?? null;
$defaultOutput = $config['output'] ?? null;
$appendFirstPage = $config['appendFirstPage'] ?? null;
$defaultMarkdown = $appendFirstPage ? dirname($configPath) . DIRECTORY_SEPARATOR . $appendFirstPage : null;

$inputFile = $options['input'] ?? $defaultInput;
$outputFile = $options['output'] ?? $defaultOutput;
$yamlFile = $options['yaml'] ?? $configPath;
$markdownFile = $options['markdown'] ?? $defaultMarkdown;

// Handle relative paths
if ($inputFile && is_string($inputFile) && !is_dir(dirname($inputFile))) {
    $yamlFileStr = is_string($yamlFile) ? $yamlFile : $configPath;
    $yamlParent = dirname($yamlFileStr, 2);
    if (!str_starts_with($inputFile, '/')) {
        $inputFile = $yamlParent . DIRECTORY_SEPARATOR . $inputFile;
    }
}

if ($outputFile && is_string($outputFile) && !is_dir(dirname($outputFile))) {
    $yamlFileStr = is_string($yamlFile) ? $yamlFile : $configPath;
    $yamlParent = dirname($yamlFileStr, 2);
    if (!str_starts_with($outputFile, '/')) {
        $outputFile = $yamlParent . DIRECTORY_SEPARATOR . $outputFile;
    }

    // Add _php suffix to filename
    $dirPart = dirname($outputFile);
    $filePart = basename($outputFile);
    $namePart = pathinfo($filePart, PATHINFO_FILENAME);
    $outputFile = $dirPart . DIRECTORY_SEPARATOR . $namePart . '_php.pdf';
}

if (!$inputFile || !$outputFile || !is_string($inputFile) || !is_string($outputFile)) {
    echo "Error: Input and output files must be specified as strings.\n";

    exit(1);
}

if (!file_exists($inputFile)) {
    echo "Error: '$inputFile' not found.\n";

    exit(1);
}

// Ensure yamlFile and markdownFile are strings or null
$yamlFileStr = is_string($yamlFile) ? $yamlFile : $configPath;
$markdownFileStr = is_string($markdownFile) ? $markdownFile : null;

try {
    $extractor = new PdfExtractor();
    $extractor->extractPages($inputFile, $outputFile, $yamlFileStr, $markdownFileStr);
} catch (\Throwable $e) {
    echo 'Error: ' . $e->getMessage() . "\n";

    exit(1);
}
