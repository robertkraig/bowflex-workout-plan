import fs from 'fs/promises';
import path from 'path';
import { marked } from 'marked';
import { exec } from 'child_process';
import { promisify } from 'util';
import { tmpdir } from 'os';

const execAsync = promisify(exec);

export class MarkdownConverter {
  constructor() {
    // Configure marked with table support
    marked.setOptions({
      gfm: true,
      breaks: false
    });
  }

  generateHtmlTemplate(htmlContent: string): string {
    return `
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
  }

  async markdownToPdfBytes(mdPath: string): Promise<Uint8Array> {
    const mdContent = await fs.readFile(mdPath, 'utf8');
    const htmlContent = marked(mdContent);
    const htmlTemplate = this.generateHtmlTemplate(htmlContent);

    const tempDir = tmpdir();
    const htmlFile = path.join(tempDir, `html_${Date.now()}_${Math.random().toString(36).substr(2, 9)}.html`);
    const pdfFile = path.join(tempDir, `pdf_${Date.now()}_${Math.random().toString(36).substr(2, 9)}.pdf`);

    try {
      await fs.writeFile(htmlFile, htmlTemplate);
      await execAsync(`node ../puppeteer_render.js "${htmlFile}" "${pdfFile}"`);
      const pdfBuffer = await fs.readFile(pdfFile);
      return pdfBuffer;
    } finally {
      await this.cleanupTempFiles([htmlFile, pdfFile]);
    }
  }

  private async cleanupTempFiles(files: string[]): Promise<void> {
    for (const file of files) {
      try {
        await fs.unlink(file);
      } catch (e: unknown) {}
    }
  }
}
