import fs from 'fs/promises';
import path from 'path';
import { PDFDocument } from 'pdf-lib';

export class PdfProcessor {
  constructor(markdownConverter) {
    this.markdownConverter = markdownConverter;
  }

  async createOutputDocument() {
    return await PDFDocument.create();
  }

  async loadInputDocument(inputPdf) {
    const inputPdfBytes = await fs.readFile(inputPdf);
    return await PDFDocument.load(inputPdfBytes);
  }

  async addMarkdownPages(outputPdfDoc, mdPath) {
    if (!mdPath) return;

    try {
      await fs.access(mdPath);
      const mdPdfBytes = await this.markdownConverter.markdownToPdfBytes(mdPath);
      const mdPdfDoc = await PDFDocument.load(mdPdfBytes);
      const mdPages = await outputPdfDoc.copyPages(mdPdfDoc, mdPdfDoc.getPageIndices());
      mdPages.forEach((page) => outputPdfDoc.addPage(page));
    } catch (error) {
      console.warn(`Warning: Could not process markdown file: ${mdPath}`);
      console.warn(`Error details: ${error.message}`);
    }
  }

  async addSelectedPages(outputPdfDoc, inputPdfDoc, selectedPages) {
    const pagesToCopy = selectedPages.filter(pageNum => pageNum < inputPdfDoc.getPageCount());
    if (pagesToCopy.length > 0) {
      const copiedPages = await outputPdfDoc.copyPages(inputPdfDoc, pagesToCopy);
      copiedPages.forEach((page) => outputPdfDoc.addPage(page));
    }
  }

  async savePdf(outputPdfDoc, outputPath) {
    const pdfBytes = await outputPdfDoc.save();
    await fs.writeFile(outputPath, pdfBytes);
    console.log(`Saved to: ${outputPath}`);
  }
}
