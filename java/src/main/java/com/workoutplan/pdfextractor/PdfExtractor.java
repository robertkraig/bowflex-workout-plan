package com.workoutplan.pdfextractor;

import org.apache.commons.cli.*;
import org.yaml.snakeyaml.Yaml;
import com.vladsch.flexmark.html.HtmlRenderer;
import com.vladsch.flexmark.parser.Parser;
import com.vladsch.flexmark.util.ast.Node;
import com.vladsch.flexmark.util.data.MutableDataSet;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Collectors;

public class PdfExtractor {

    public static class Config {
        public String file;
        public String output;
        public String appendFirstPage;
        public List<PageConfig> pages;

        public Config() {
            this.pages = new ArrayList<>();
        }
    }

    public static class PageConfig {
        public String name;
        public Integer pageIndex;
        public Integer page;
        public Integer pageNumber;
    }

    public static void main(String[] args) {
        Options options = new Options();
        options.addOption("y", "yaml", true, "YAML file with page configuration");
        options.addOption("i", "input", true, "Input PDF file");
        options.addOption("o", "output", true, "Output PDF file");
        options.addOption("m", "markdown", true, "Markdown file to prepend");

        CommandLineParser parser = new DefaultParser();
        HelpFormatter formatter = new HelpFormatter();
        CommandLine cmd = null;

        try {
            cmd = parser.parse(options, args);
        } catch (ParseException e) {
            System.err.println("Error parsing command line: " + e.getMessage());
            formatter.printHelp("pdf-extractor", options);
            System.exit(1);
        }

        try {
            String yamlPath = cmd.getOptionValue("yaml", "../resources/config.yaml");
            String inputFile = cmd.getOptionValue("input");
            String outputFile = cmd.getOptionValue("output");
            String markdownFile = cmd.getOptionValue("markdown");

            extractPages(inputFile, outputFile, yamlPath, markdownFile);
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static byte[] markdownToPDFBytes(String mdPath) throws IOException, InterruptedException {
        String mdContent = new String(Files.readAllBytes(Paths.get(mdPath)));

        MutableDataSet options = new MutableDataSet();
        Parser parser = Parser.builder(options).build();
        HtmlRenderer renderer = HtmlRenderer.builder(options).build();

        Node document = parser.parse(mdContent);
        String htmlContent = renderer.render(document);

        String htmlTemplate = String.format(
            "<html>" +
            "<head>" +
            "<style>" +
            "body { font-family: Helvetica, Arial, sans-serif; margin: 2em; }" +
            "h1, h2, h3, h4 { color: #2a4d7c; }" +
            "table { border-collapse: collapse; width: 100%%; margin-bottom: 1em; }" +
            "th, td { border: 1px solid #888; padding: 0.5em; text-align: left; }" +
            "th { background: #d5e4f3; }" +
            "code { background: #eee; padding: 2px 4px; border-radius: 4px; }" +
            "pre { background: #f4f4f4; padding: 1em; border-radius: 4px; }" +
            "ul { margin: 1em 0; padding-left: 2em; }" +
            "li { margin: 0.5em 0; }" +
            "</style>" +
            "</head>" +
            "<body>%s</body>" +
            "</html>", htmlContent);

        Path htmlFile = Files.createTempFile(null, ".html");
        Files.write(htmlFile, htmlTemplate.getBytes());

        Path pdfFile = Files.createTempFile(null, ".pdf");

        try {
            ProcessBuilder pb = new ProcessBuilder("node", "../puppeteer_render.js",
                htmlFile.toString(), pdfFile.toString());
            Process process = pb.start();
            int exitCode = process.waitFor();

            if (exitCode != 0) {
                throw new IOException("Failed to convert HTML to PDF");
            }

            return Files.readAllBytes(pdfFile);
        } finally {
            Files.deleteIfExists(htmlFile);
            Files.deleteIfExists(pdfFile);
        }
    }

    private static void extractPages(String inputFile, String outputFile,
                                   String yamlPath, String markdownFile) throws Exception {

        String configContent = new String(Files.readAllBytes(Paths.get(yamlPath)));
        Yaml yaml = new Yaml();
        Config config = yaml.loadAs(configContent, Config.class);

        // Get project root (parent of yaml directory)
        Path yamlParent = Paths.get(yamlPath).getParent().getParent();

        if (inputFile == null || inputFile.isEmpty()) {
            inputFile = config.file;
            if (inputFile != null && !Paths.get(inputFile).isAbsolute()) {
                Path standardPath = yamlParent.resolve(inputFile);
                if (Files.exists(standardPath)) {
                    inputFile = standardPath.toString();
                } else {
                    Path fallbackPath = Paths.get(yamlPath).getParent().resolve(inputFile);
                    if (Files.exists(fallbackPath)) {
                        inputFile = fallbackPath.toString();
                    } else {
                        inputFile = standardPath.toString();
                    }
                }
            }
        }

        if (outputFile == null || outputFile.isEmpty()) {
            outputFile = config.output;
            if (outputFile != null && !Paths.get(outputFile).isAbsolute()) {
                outputFile = yamlParent.resolve(outputFile).toString();
            }

            // Add _java suffix to filename
            if (outputFile != null) {
                Path path = Paths.get(outputFile);
                String fileName = path.getFileName().toString();
                int dotIndex = fileName.lastIndexOf('.');
                String name = (dotIndex > 0) ? fileName.substring(0, dotIndex) : fileName;
                String ext = (dotIndex > 0) ? fileName.substring(dotIndex) : "";
                outputFile = path.getParent().resolve(name + "_java" + ext).toString();
            }
        }

        String mdFile = null;
        if (markdownFile != null && !markdownFile.isEmpty()) {
            mdFile = markdownFile;
        } else if (config.appendFirstPage != null && !config.appendFirstPage.isEmpty()) {
            Path yamlDir = Paths.get(yamlPath).getParent();
            mdFile = yamlDir.resolve(config.appendFirstPage).toString();
        }

        if (!Files.exists(Paths.get(inputFile))) {
            System.out.printf("Error: '%s' not found.%n", inputFile);
            return;
        }

        // Collect selected pages
        List<Integer> selectedPages = new ArrayList<>();
        Set<Integer> seen = new HashSet<>();

        for (PageConfig pageConfig : config.pages) {
            Integer idx = null;
            if (pageConfig.pageIndex != null) {
                idx = pageConfig.pageIndex;
            } else if (pageConfig.page != null) {
                idx = pageConfig.page;
            }

            if (idx != null && !seen.contains(idx)) {
                selectedPages.add(idx);
                seen.add(idx);
            }
        }

        // Create temporary directory
        Path tempDir = Files.createTempDirectory("pdf-extractor");
        List<String> filesToMerge = new ArrayList<>();

        try {
            // Add markdown PDF if provided
            if (mdFile != null) {
                byte[] mdPDFBytes = markdownToPDFBytes(mdFile);
                Path mdPDFPath = tempDir.resolve("markdown.pdf");
                Files.write(mdPDFPath, mdPDFBytes);
                filesToMerge.add(mdPDFPath.toString());
            }

            // Extract specified pages using pdftk
            if (!selectedPages.isEmpty()) {
                String pagesStr = selectedPages.stream()
                    .map(String::valueOf)
                    .collect(Collectors.joining(" "));

                Path extractedPDF = tempDir.resolve("extracted.pdf");

                List<String> args = new ArrayList<>();
                args.add("pdftk");
                args.add(inputFile);
                args.add("cat");
                args.addAll(selectedPages.stream().map(String::valueOf).collect(Collectors.toList()));
                args.add("output");
                args.add(extractedPDF.toString());

                ProcessBuilder pb = new ProcessBuilder(args);
                Process process = pb.start();
                int exitCode = process.waitFor();

                if (exitCode != 0) {
                    throw new IOException("Failed to extract pages with pdftk");
                }

                filesToMerge.add(extractedPDF.toString());
            }

            // Merge all PDFs
            if (filesToMerge.size() == 1) {
                // Just copy the single file
                Files.copy(Paths.get(filesToMerge.get(0)), Paths.get(outputFile),
                          StandardCopyOption.REPLACE_EXISTING);
            } else if (filesToMerge.size() > 1) {
                // Merge multiple files
                List<String> args = new ArrayList<>();
                args.add("pdftk");
                args.addAll(filesToMerge);
                args.add("cat");
                args.add("output");
                args.add(outputFile);

                ProcessBuilder pb = new ProcessBuilder(args);
                Process process = pb.start();
                int exitCode = process.waitFor();

                if (exitCode != 0) {
                    throw new IOException("Failed to merge PDFs with pdftk");
                }
            }

            System.out.printf("Saved to: %s%n", outputFile);

        } finally {
            // Clean up temporary directory
            Files.walk(tempDir)
                .sorted(Comparator.reverseOrder())
                .map(Path::toFile)
                .forEach(File::delete);
        }
    }
}
