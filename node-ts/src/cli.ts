import { Command } from 'commander';
import path from 'path';
import { ConfigManager } from './config.js';

export class CliManager {
  constructor(private configManager: ConfigManager) {}

  async createProgram(): Promise<Command> {
    const program = new Command();
    const configPath = '../resources/config.yaml';
    const config = await this.configManager.loadDefaultConfig(configPath);

    const defaultInput = config.file;
    const defaultOutput = config.output;
    const appendFirstPage = config.appendFirstPage;
    const defaultMarkdown = appendFirstPage
      ? path.join(path.dirname(configPath), appendFirstPage)
      : null;

    program
      .name('pdf-extractor')
      .description('Extract selected pages from PDF and optionally prepend Markdown intro')
      .option('--input <file>', `Input PDF file (default from config.yaml: ${defaultInput})`, defaultInput)
      .option('--output <file>', `Output PDF file (default from config.yaml: ${defaultOutput})`, defaultOutput)
      .option('--yaml <file>', 'YAML file with page configuration', configPath)
      .option('--markdown <file>', `Markdown file to prepend (default from config.yaml: ${defaultMarkdown || 'None'})`, defaultMarkdown || undefined);

    return program;
  }
}
