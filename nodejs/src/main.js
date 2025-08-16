#!/usr/bin/env node

import fs from 'fs/promises';
import { PdfExtractor } from './pdf-extractor.js';
import { ConfigManager } from './config.js';
import { CliManager } from './cli.js';
import { PathUtils } from './path-utils.js';

async function main() {
  const configManager = new ConfigManager();
  const cliManager = new CliManager(configManager);

  const program = await cliManager.createProgram();
  program.parse();
  const options = program.opts();

  let { input: inputFile, output: outputFile, yaml: yamlFile, markdown: markdownFile } = options;

  // Handle relative paths and add language suffix
  inputFile = await PathUtils.resolveInputPath(inputFile, yamlFile);
  outputFile = PathUtils.resolveOutputPath(outputFile, yamlFile, '_nodejs');

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
