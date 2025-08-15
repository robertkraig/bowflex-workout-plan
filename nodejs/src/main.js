#!/usr/bin/env node

import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { PDFDocument } from 'pdf-lib';
import yaml from 'yaml';
import { marked } from 'marked';
import { Command } from 'commander';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class PdfExtractor {
  async markdownToPdfBytes(mdPath) {
    const mdContent = await fs.readFile(mdPath, 'utf8');

    // Configure marked with table support (similar to Python's extras=["tables"])
    marked.setOptions({
      gfm: true,
      tables: true,
      breaks: false,
      sanitize: false
    });

    const htmlContent = marked(mdContent);

    const htmlTemplate = `
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
    <body>${htmlContent}</body>
    </html>
    `;

    // Use the same approach as other languages - write to temp file and use shared puppeteer_render.js
    const { createWriteStream } = await import('fs');
    const { promisify } = await import('util');
    const { exec } = await import('child_process');
    const execAsync = promisify(exec);

    const tempDir = await import('os').then(os => os.tmpdir());
    const htmlFile = path.join(tempDir, `html_${Date.now()}_${Math.random().toString(36).substr(2, 9)}.html`);
    const pdfFile = path.join(tempDir, `pdf_${Date.now()}_${Math.random().toString(36).substr(2, 9)}.pdf`);

    try {
      await fs.writeFile(htmlFile, htmlTemplate);
      await execAsync(`node ../puppeteer_render.js "${htmlFile}" "${pdfFile}"`);
      const pdfBuffer = await fs.readFile(pdfFile);
      return pdfBuffer;
    } finally {
      try {
        await fs.unlink(htmlFile);
      } catch (e) {}
      try {
        await fs.unlink(pdfFile);
      } catch (e) {}
    }
  }

  async extractPages(inputPdf, outputPdf, yamlPath = '../resources/config.yaml', mdPath = null) {
    const configContent = await fs.readFile(yamlPath, 'utf8');
    const config = yaml.parse(configContent);
    const pages = config.pages || [];
    const appendFirstPage = config.appendFirstPage || null;

    const seen = new Set();
    const selectedPages = [];

    for (const pageConfig of pages) {
      const idx = pageConfig.pageIndex || pageConfig.page;
      if (idx !== undefined && idx !== null && !seen.has(idx)) {
        selectedPages.push(idx - 1); // Convert to 0-based index
        seen.add(idx);
      }
    }

    const inputPdfBytes = await fs.readFile(inputPdf);
    const inputPdfDoc = await PDFDocument.load(inputPdfBytes);
    const outputPdfDoc = await PDFDocument.create();

    // If a markdown file is provided, prepend its pages
    if (mdPath === null && appendFirstPage) {
      mdPath = path.join(path.dirname(yamlPath), appendFirstPage);
    }

    if (mdPath) {
      try {
        await fs.access(mdPath);
        const mdPdfBytes = await this.markdownToPdfBytes(mdPath);
        const mdPdfDoc = await PDFDocument.load(mdPdfBytes);
        const mdPages = await outputPdfDoc.copyPages(mdPdfDoc, mdPdfDoc.getPageIndices());
        mdPages.forEach((page) => outputPdfDoc.addPage(page));
      } catch (error) {
        console.warn(`Warning: Could not process markdown file: ${mdPath}`);
        console.warn(`Error details: ${error.message}`);
      }
    }

    // Copy selected pages from input PDF
    const pagesToCopy = selectedPages.filter(pageNum => pageNum < inputPdfDoc.getPageCount());
    if (pagesToCopy.length > 0) {
      const copiedPages = await outputPdfDoc.copyPages(inputPdfDoc, pagesToCopy);
      copiedPages.forEach((page) => outputPdfDoc.addPage(page));
    }

    const pdfBytes = await outputPdfDoc.save();
    await fs.writeFile(outputPdf, pdfBytes);
    console.log(`Saved to: ${outputPdf}`);
  }
}

async function main() {
  const program = new Command();

  // Load config for defaults
  const configPath = '../resources/config.yaml';
  let config = {};

  try {
    const configContent = await fs.readFile(configPath, 'utf8');
    config = yaml.parse(configContent);
  } catch (error) {
    // Config file doesn't exist, use empty config
  }

  const defaultInput = config.file;
  const defaultOutput = config.output;
  const appendFirstPage = config.appendFirstPage;
  const defaultMarkdown = appendFirstPage ? path.join(path.dirname(configPath), appendFirstPage) : null;

  program
    .name('pdf-extractor')
    .description('Extract selected pages from PDF and optionally prepend Markdown intro')
    .option('--input <file>', `Input PDF file (default from config.yaml: ${defaultInput})`, defaultInput)
    .option('--output <file>', `Output PDF file (default from config.yaml: ${defaultOutput})`, defaultOutput)
    .option('--yaml <file>', 'YAML file with page configuration', configPath)
    .option('--markdown <file>', `Markdown file to prepend (default from config.yaml: ${defaultMarkdown || 'None'})`, defaultMarkdown);

  program.parse();
  const options = program.opts();

  let { input: inputFile, output: outputFile, yaml: yamlFile, markdown: markdownFile } = options;

  // Handle relative paths and add language suffix
  if (inputFile && !path.isAbsolute(inputFile)) {
    const yamlParent = path.dirname(path.dirname(yamlFile));
    // Try standard path resolution first (relative to project root)
    const standardPath = path.join(yamlParent, inputFile);
    if (await fs.access(standardPath).then(() => true).catch(() => false)) {
      inputFile = standardPath;
    } else {
      // Fallback: try looking in resources directory for backward compatibility
      const fallbackPath = path.join(path.dirname(yamlFile), inputFile);
      const fallbackExists = await fs.access(fallbackPath).then(() => true).catch(() => false);
      inputFile = fallbackExists ? fallbackPath : standardPath;
    }
  }

  if (outputFile && !path.isAbsolute(outputFile)) {
    const yamlParent = path.dirname(path.dirname(yamlFile));
    outputFile = path.join(yamlParent, outputFile);
  }

  // Add _nodejs suffix to filename
  if (outputFile) {
    const dirPart = path.dirname(outputFile);
    const filePart = path.basename(outputFile);
    const namePart = path.parse(filePart).name;
    const extPart = path.parse(filePart).ext;
    outputFile = path.join(dirPart, `${namePart}_nodejs${extPart}`);
  }

  try {
    await fs.access(inputFile);
  } catch (error) {
    console.error(`Error: '${inputFile}' not found.`);
    process.exit(1);
  }

  const extractor = new PdfExtractor();
  await extractor.extractPages(inputFile, outputFile, yamlFile, markdownFile);
}

main().catch(console.error);
