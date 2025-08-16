import { ConfigManager } from './config.js';
import { MarkdownConverter } from './markdown-converter.js';
import { PdfProcessor } from './pdf-processor.js';
import { PathUtils } from './path-utils.js';

export class PdfExtractor {
  private configManager: ConfigManager;
  private markdownConverter: MarkdownConverter;
  private pdfProcessor: PdfProcessor;

  constructor() {
    this.configManager = new ConfigManager();
    this.markdownConverter = new MarkdownConverter();
    this.pdfProcessor = new PdfProcessor(this.markdownConverter);
  }

  async extractPages(inputPdf: string, outputPdf: string, yamlPath: string = '../resources/config.yaml', mdPath?: string): Promise<void> {
    const config = await this.configManager.loadConfig(yamlPath);
    const selectedPages = this.configManager.extractPageIndices(config);
    const appendFirstPage = config.appendFirstPage || null;

    const inputPdfDoc = await this.pdfProcessor.loadInputDocument(inputPdf);
    const outputPdfDoc = await this.pdfProcessor.createOutputDocument();

    // Resolve markdown path
    const resolvedMdPath = PathUtils.resolveMarkdownPath(mdPath, yamlPath, appendFirstPage || undefined);

    // Add markdown pages if specified
    await this.pdfProcessor.addMarkdownPages(outputPdfDoc, resolvedMdPath);

    // Add selected pages from input PDF
    await this.pdfProcessor.addSelectedPages(outputPdfDoc, inputPdfDoc, selectedPages);

    // Save the final PDF
    await this.pdfProcessor.savePdf(outputPdfDoc, outputPdf);
  }
}
