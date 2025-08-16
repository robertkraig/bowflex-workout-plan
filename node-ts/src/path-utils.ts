import fs from 'fs/promises';
import path from 'path';

export class PathUtils {
  static async resolveInputPath(inputFile?: string, yamlFile?: string): Promise<string | undefined> {
    if (!inputFile || !yamlFile || path.isAbsolute(inputFile)) {
      return inputFile;
    }

    const yamlParent = path.dirname(path.dirname(yamlFile));
    const standardPath = path.join(yamlParent, inputFile);

    if (await fs.access(standardPath).then(() => true).catch(() => false)) {
      return standardPath;
    }

    // Fallback: try looking in resources directory for backward compatibility
    const fallbackPath = path.join(path.dirname(yamlFile), inputFile);
    const fallbackExists = await fs.access(fallbackPath).then(() => true).catch(() => false);
    return fallbackExists ? fallbackPath : standardPath;
  }

  static resolveOutputPath(outputFile?: string, yamlFile?: string, suffix: string = '_node-ts'): string | undefined {
    if (!outputFile || !yamlFile || path.isAbsolute(outputFile)) {
      return this.addSuffixToFilename(outputFile, suffix);
    }

    const yamlParent = path.dirname(path.dirname(yamlFile));
    const resolvedPath = path.join(yamlParent, outputFile);
    return this.addSuffixToFilename(resolvedPath, suffix);
  }

  static addSuffixToFilename(filePath?: string, suffix: string = ''): string | undefined {
    if (!filePath) return filePath;

    const dirPart = path.dirname(filePath);
    const filePart = path.basename(filePath);
    const namePart = path.parse(filePart).name;
    const extPart = path.parse(filePart).ext;
    return path.join(dirPart, `${namePart}${suffix}${extPart}`);
  }

  static resolveMarkdownPath(markdownFile?: string, yamlPath?: string, appendFirstPage?: string): string | undefined {
    if (!markdownFile && appendFirstPage && yamlPath) {
      return path.join(path.dirname(yamlPath), appendFirstPage);
    }
    return markdownFile || undefined;
  }
}
