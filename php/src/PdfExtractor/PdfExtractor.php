<?php

declare(strict_types=1);

namespace PdfExtractor;

use Symfony\Component\Yaml\Yaml;

class PdfExtractor
{
    /**
     * @return array{stdout: string, stderr: string, exit_code: int}
     */
    private function executeCommand(string $command): array
    {
        $descriptorSpec = [
            0 => ['pipe', 'r'],  // stdin
            1 => ['pipe', 'w'],  // stdout
            2 => ['pipe', 'w'],   // stderr
        ];

        $process = proc_open($command, $descriptorSpec, $pipes);

        if (!is_resource($process)) {
            throw new \RuntimeException("Failed to execute command: $command");
        }

        // Close stdin
        fclose($pipes[0]);

        // Read stdout and stderr
        $stdout = stream_get_contents($pipes[1]);
        $stderr = stream_get_contents($pipes[2]);

        fclose($pipes[1]);
        fclose($pipes[2]);

        $exitCode = proc_close($process);

        return [
            'stdout' => $stdout !== false ? $stdout : '',
            'stderr' => $stderr !== false ? $stderr : '',
            'exit_code' => $exitCode,
        ];
    }

    public function markdownToPdf(string $mdPath, string $outputPdf): string
    {
        $mdContent = file_get_contents($mdPath);
        if ($mdContent === false) {
            throw new \RuntimeException("Failed to read markdown file: {$mdPath}");
        }

        $parsedown = new \Parsedown();
        $htmlContent = $parsedown->text($mdContent);

        $htmlTemplate = "
        <html>
        <head>
            <style>
                body { font-family: Helvetica, Arial, sans-serif; margin: 2em; }
                h1, h2, h3, h4 { color: #2a4d7c; }
                table { border-collapse: collapse; width: 100%; margin-bottom: 1em; }
                th, td { border: 1px solid #888; padding: 0.5em; text-align: left; }
                th { background: #d5e4f3; }
                code { background: #eee; padding: 2px 4px; border-radius: 4px; }
                pre { background: #f4f4f4; padding: 1em; border-radius: 4px; }
                ul { margin: 1em 0; padding-left: 2em; }
                li { margin: 0.5em 0; }
            </style>
        </head>
        <body>{$htmlContent}</body>
        </html>
        ";

        $htmlFile = tempnam(sys_get_temp_dir(), 'html');
        if ($htmlFile === false) {
            throw new \RuntimeException('Failed to create temporary HTML file');
        }
        $htmlFile .= '.html';

        $writeResult = file_put_contents($htmlFile, $htmlTemplate);
        if ($writeResult === false) {
            throw new \RuntimeException('Failed to write HTML template to temporary file');
        }

        $command = 'node ../puppeteer_render.js ' . escapeshellarg($htmlFile) . ' ' . escapeshellarg($outputPdf);
        $result = $this->executeCommand($command);

        unlink($htmlFile);

        if (!file_exists($outputPdf)) {
            $message = "Failed to convert markdown to PDF. Command: $command. " .
                      "Exit code: {$result['exit_code']}. Stdout: {$result['stdout']}. " .
                      "Stderr: {$result['stderr']}";

            throw new \RuntimeException($message);
        }

        return $outputPdf;
    }

    public function extractPages(
        string $inputPdf,
        string $outputPdf,
        string $yamlPath = '../resources/config.yaml',
        ?string $mdPath = null,
    ): void {
        // Check if pdftk is available
        $whichResult = $this->executeCommand('which pdftk');
        if ($whichResult['exit_code'] !== 0 || trim($whichResult['stdout']) === '') {
            throw new \RuntimeException('pdftk is required but not installed. Please install pdftk.');
        }

        $config = Yaml::parseFile($yamlPath);
        if (!is_array($config)) {
            throw new \RuntimeException('Invalid YAML configuration file: expected array, got ' . gettype($config));
        }

        $pages = $config['pages'] ?? [];
        if (!is_array($pages)) {
            throw new \RuntimeException("Invalid YAML configuration: 'pages' must be an array");
        }

        $appendFirstPage = $config['appendFirstPage'] ?? null;

        $seen = [];
        $selectedPages = [];

        foreach ($pages as $pageConfig) {
            if (!is_array($pageConfig)) {
                continue; // Skip invalid page configurations
            }

            $idx = $pageConfig['pageIndex'] ?? $pageConfig['page'] ?? null;
            if ($idx !== null && (is_int($idx) || is_numeric($idx)) && !in_array($idx, $seen, true)) {
                $selectedPages[] = (int) $idx; // Keep 1-based index for pdftk
                $seen[] = $idx;
            }
        }

        $tempFiles = [];
        $filesToMerge = [];

        // If a markdown file is provided, prepend its pages
        if ($mdPath === null && $appendFirstPage) {
            $mdPath = dirname($yamlPath) . DIRECTORY_SEPARATOR . $appendFirstPage;
        }

        if ($mdPath && file_exists($mdPath)) {
            $mdPdfFile = tempnam(sys_get_temp_dir(), 'mdpdf') . '.pdf';
            $this->markdownToPdf($mdPath, $mdPdfFile);
            $filesToMerge[] = $mdPdfFile;
            $tempFiles[] = $mdPdfFile;
        }

        // Extract selected pages using pdftk
        if (!empty($selectedPages)) {
            $pageRange = implode(' ', $selectedPages);
            $extractedFile = tempnam(sys_get_temp_dir(), 'extracted');
            if ($extractedFile === false) {
                throw new \RuntimeException('Failed to create temporary file for page extraction');
            }
            $extractedFile .= '.pdf';

            $command = 'pdftk ' . escapeshellarg($inputPdf) . " cat $pageRange output " .
                      escapeshellarg($extractedFile);
            echo "Debug: Running command: $command\n";
            $result = $this->executeCommand($command);
            echo "Debug: Exit code: {$result['exit_code']}\n";
            echo "Debug: Stdout: {$result['stdout']}\n";
            echo "Debug: Stderr: {$result['stderr']}\n";

            if (!file_exists($extractedFile)) {
                // Clean up temp files
                foreach ($tempFiles as $file) {
                    if (file_exists($file)) {
                        unlink($file);
                    }
                }
                $message = 'Failed to extract pages using pdftk. ' .
                          "Exit code: {$result['exit_code']}. Stdout: {$result['stdout']}. " .
                          "Stderr: {$result['stderr']}";

                throw new \RuntimeException($message);
            }

            $filesToMerge[] = $extractedFile;
            $tempFiles[] = $extractedFile;
        }

        // Merge files if we have multiple PDFs
        if (count($filesToMerge) > 1) {
            $mergeCommand = 'pdftk ' . implode(' ', array_map('escapeshellarg', $filesToMerge)) .
                           ' cat output ' . escapeshellarg($outputPdf);
            $mergeResult = $this->executeCommand($mergeCommand);

            if ($mergeResult['exit_code'] !== 0 || !file_exists($outputPdf)) {
                // Clean up temp files
                foreach ($tempFiles as $file) {
                    if (file_exists($file)) {
                        unlink($file);
                    }
                }
                $message = 'Failed to merge PDFs using pdftk. ' .
                          "Exit code: {$mergeResult['exit_code']}. Stdout: {$mergeResult['stdout']}. " .
                          "Stderr: {$mergeResult['stderr']}";

                throw new \RuntimeException($message);
            }
        } elseif (count($filesToMerge) === 1) {
            // Just copy the single file
            $copyResult = copy($filesToMerge[0], $outputPdf);
            if (!$copyResult) {
                throw new \RuntimeException('Failed to copy PDF file to output location');
            }
        } else {
            throw new \RuntimeException('No pages to extract');
        }

        // Clean up temp files
        foreach ($tempFiles as $file) {
            if (file_exists($file)) {
                unlink($file);
            }
        }

        echo "Saved to: $outputPdf\n";
    }
}
