import fs from 'fs/promises';
import { PDFDocument } from 'pdf-lib';
import { MarkdownConverter } from './markdown-converter.js';

export class PdfProcessor {
  constructor(private markdownConverter: MarkdownConverter) {}

  async createOutputDocument(): Promise<PDFDocument> {
    return await PDFDocument.create();
  }

  async loadInputDocument(inputPdf: string): Promise<PDFDocument> {
    const inputPdfBytes = await fs.readFile(inputPdf);
    return await PDFDocument.load(inputPdfBytes);
  }

  async addMarkdownPages(outputPdfDoc: PDFDocument, mdPath?: string): Promise<void> {
    if (!mdPath) return;

    try {
      await fs.access(mdPath);
      const mdPdfBytes = await this.markdownConverter.markdownToPdfBytes(mdPath);
      const mdPdfDoc = await PDFDocument.load(mdPdfBytes);
      const mdPages = await outputPdfDoc.copyPages(mdPdfDoc, mdPdfDoc.getPageIndices());
      mdPages.forEach((page) => outputPdfDoc.addPage(page));
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.warn(`Warning: Could not process markdown file: ${mdPath}`);
      console.warn(`Error details: ${errorMessage}`);
    }
  }

  async addSelectedPages(outputPdfDoc: PDFDocument, inputPdfDoc: PDFDocument, selectedPages: number[]): Promise<void> {
    const pagesToCopy = selectedPages.filter(pageNum => pageNum < inputPdfDoc.getPageCount());
    if (pagesToCopy.length > 0) {
      const copiedPages = await outputPdfDoc.copyPages(inputPdfDoc, pagesToCopy);
      copiedPages.forEach((page) => outputPdfDoc.addPage(page));
    }
  }

  async savePdf(outputPdfDoc: PDFDocument, outputPath: string): Promise<void> {
    const pdfBytes = await outputPdfDoc.save();
    await fs.writeFile(outputPath, pdfBytes);
    console.log(`Saved to: ${outputPath}`);
  }
}
