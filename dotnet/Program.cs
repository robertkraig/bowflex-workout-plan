using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using CommandLine;
using Markdig;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace PdfExtractor
{
    public class Config
    {
        public string File { get; set; } = string.Empty;
        public string Output { get; set; } = string.Empty;
        public string AppendFirstPage { get; set; } = string.Empty;
        public List<PageConfig> Pages { get; set; } = new();
    }

    public class PageConfig
    {
        public string Name { get; set; } = string.Empty;
        public int? PageIndex { get; set; }
        public int? Page { get; set; }
        public int? PageNumber { get; set; }
    }

    public class Options
    {
        [Option('y', "yaml", Default = "../resources/config.yaml", HelpText = "YAML file with page configuration")]
        public string YamlFile { get; set; } = string.Empty;

        [Option('i', "input", HelpText = "Input PDF file")]
        public string? InputFile { get; set; }

        [Option('o', "output", HelpText = "Output PDF file")]
        public string? OutputFile { get; set; }

        [Option('m', "markdown", HelpText = "Markdown file to prepend")]
        public string? MarkdownFile { get; set; }
    }

    public class Program
    {
        public static int Main(string[] args)
        {
            return Parser.Default.ParseArguments<Options>(args)
                .MapResult(
                    opts => RunExtraction(opts),
                    errs => 1);
        }

        private static int RunExtraction(Options opts)
        {
            try
            {
                var configContent = File.ReadAllText(opts.YamlFile);
                var deserializer = new DeserializerBuilder()
                    .WithNamingConvention(CamelCaseNamingConvention.Instance)
                    .Build();

                var config = deserializer.Deserialize<Config>(configContent);

                // Get project root (parent of yaml directory)
                var yamlParent = Path.GetDirectoryName(Path.GetDirectoryName(opts.YamlFile)) ?? string.Empty;

                var inputFile = opts.InputFile ?? config.File;
                if (!string.IsNullOrEmpty(inputFile) && !Path.IsPathFullyQualified(inputFile))
                {
                    // Try standard path resolution first (relative to project root)
                    var standardPath = Path.Combine(yamlParent, inputFile);
                    if (File.Exists(standardPath))
                    {
                        inputFile = standardPath;
                    }
                    else
                    {
                        // Fallback: try looking in resources directory for backward compatibility
                        var fallbackPath = Path.Combine(Path.GetDirectoryName(opts.YamlFile) ?? string.Empty, inputFile);
                        if (File.Exists(fallbackPath))
                        {
                            inputFile = fallbackPath;
                        }
                        else
                        {
                            inputFile = standardPath;
                        }
                    }
                }

                var outputFile = opts.OutputFile ?? config.Output;
                if (!string.IsNullOrEmpty(outputFile) && !Path.IsPathFullyQualified(outputFile))
                {
                    outputFile = Path.Combine(yamlParent, outputFile);
                }

                // Add _dotnet suffix to filename
                if (!string.IsNullOrEmpty(outputFile))
                {
                    var dir = Path.GetDirectoryName(outputFile) ?? string.Empty;
                    var name = Path.GetFileNameWithoutExtension(outputFile);
                    var ext = Path.GetExtension(outputFile);
                    outputFile = Path.Combine(dir, $"{name}_dotnet{ext}");
                }

                string? mdFile = null;
                if (!string.IsNullOrEmpty(opts.MarkdownFile))
                {
                    mdFile = opts.MarkdownFile;
                }
                else if (!string.IsNullOrEmpty(config.AppendFirstPage))
                {
                    var yamlDir = Path.GetDirectoryName(opts.YamlFile) ?? string.Empty;
                    mdFile = Path.Combine(yamlDir, config.AppendFirstPage);
                }

                if (!File.Exists(inputFile))
                {
                    Console.WriteLine($"Error: '{inputFile}' not found.");
                    return 1;
                }

                ExtractPages(inputFile, outputFile, opts.YamlFile, mdFile);
                return 0;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error: {ex.Message}");
                return 1;
            }
        }

        private static byte[] MarkdownToPdfBytes(string mdPath)
        {
            var mdContent = File.ReadAllText(mdPath);
            var htmlContent = Markdown.ToHtml(mdContent);

            var htmlTemplate = $@"
                <html>
                <head>
                    <style>
                        body {{ font-family: Helvetica, Arial, sans-serif; margin: 2em; }}
                        h1, h2, h3, h4 {{ color: #2a4d7c; }}
                        table {{ border-collapse: collapse; width: 100%; margin-bottom: 1em; }}
                        th, td {{ border: 1px solid #888; padding: 0.5em; text-align: left; }}
                        th {{ background: #d5e4f3; }}
                        code {{ background: #eee; padding: 2px 4px; border-radius: 4px; }}
                        pre {{ background: #f4f4f4; padding: 1em; border-radius: 4px; }}
                        ul {{ margin: 1em 0; padding-left: 2em; }}
                        li {{ margin: 0.5em 0; }}
                    </style>
                </head>
                <body>{htmlContent}</body>
                </html>";

            var htmlFile = Path.GetTempFileName() + ".html";
            var pdfFile = Path.GetTempFileName() + ".pdf";

            try
            {
                File.WriteAllText(htmlFile, htmlTemplate);

                var process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "node",
                        Arguments = $"../puppeteer_render.js \"{htmlFile}\" \"{pdfFile}\"",
                        UseShellExecute = false,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true
                    }
                };

                process.Start();
                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    throw new Exception($"Failed to convert markdown to PDF. Exit code: {process.ExitCode}");
                }

                return File.ReadAllBytes(pdfFile);
            }
            finally
            {
                if (File.Exists(htmlFile)) File.Delete(htmlFile);
                if (File.Exists(pdfFile)) File.Delete(pdfFile);
            }
        }

        private static void ExtractPages(string inputPdf, string outputPdf, string yamlPath, string? mdPath)
        {
            var configContent = File.ReadAllText(yamlPath);
            var deserializer = new DeserializerBuilder()
                .WithNamingConvention(CamelCaseNamingConvention.Instance)
                .Build();

            var config = deserializer.Deserialize<Config>(configContent);

            var selectedPages = new List<int>();
            var seen = new HashSet<int>();

            foreach (var pageConfig in config.Pages)
            {
                int? idx = pageConfig.PageIndex ?? pageConfig.Page;
                if (idx.HasValue && !seen.Contains(idx.Value))
                {
                    selectedPages.Add(idx.Value);
                    seen.Add(idx.Value);
                }
            }

            // Create temporary directory
            var tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
            Directory.CreateDirectory(tempDir);

            try
            {
                var filesToMerge = new List<string>();

                // Add markdown PDF if provided
                if (!string.IsNullOrEmpty(mdPath))
                {
                    var mdPdfBytes = MarkdownToPdfBytes(mdPath);
                    var mdPdfPath = Path.Combine(tempDir, "markdown.pdf");
                    File.WriteAllBytes(mdPdfPath, mdPdfBytes);
                    filesToMerge.Add(mdPdfPath);
                }

                // Extract specified pages using pdftk
                if (selectedPages.Count > 0)
                {
                    var extractedPdf = Path.Combine(tempDir, "extracted.pdf");
                    var pagesStr = string.Join(" ", selectedPages);

                    var process = new Process
                    {
                        StartInfo = new ProcessStartInfo
                        {
                            FileName = "pdftk",
                            Arguments = $"\"{inputPdf}\" cat {pagesStr} output \"{extractedPdf}\"",
                            UseShellExecute = false,
                            RedirectStandardOutput = true,
                            RedirectStandardError = true
                        }
                    };

                    process.Start();
                    process.WaitForExit();

                    if (process.ExitCode != 0)
                    {
                        throw new Exception($"Failed to extract pages. Exit code: {process.ExitCode}");
                    }

                    filesToMerge.Add(extractedPdf);
                }

                // Merge all PDFs
                if (filesToMerge.Count == 1)
                {
                    // Just copy the single file
                    File.Copy(filesToMerge[0], outputPdf, true);
                }
                else if (filesToMerge.Count > 1)
                {
                    // Merge multiple files
                    var filesArg = string.Join(" ", filesToMerge.Select(f => $"\"{f}\""));

                    var process = new Process
                    {
                        StartInfo = new ProcessStartInfo
                        {
                            FileName = "pdftk",
                            Arguments = $"{filesArg} cat output \"{outputPdf}\"",
                            UseShellExecute = false,
                            RedirectStandardOutput = true,
                            RedirectStandardError = true
                        }
                    };

                    process.Start();
                    process.WaitForExit();

                    if (process.ExitCode != 0)
                    {
                        throw new Exception($"Failed to merge PDFs. Exit code: {process.ExitCode}");
                    }
                }

                Console.WriteLine($"Saved to: {outputPdf}");
            }
            finally
            {
                if (Directory.Exists(tempDir))
                {
                    Directory.Delete(tempDir, true);
                }
            }
        }
    }
}
