import fs from 'fs/promises';
import path from 'path';

export class PathUtils {
  static async resolveInputPath(inputFile, yamlFile) {
    if (!inputFile || path.isAbsolute(inputFile)) {
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

  static resolveOutputPath(outputFile, yamlFile, suffix = '_nodejs') {
    if (!outputFile || path.isAbsolute(outputFile)) {
      return this.addSuffixToFilename(outputFile, suffix);
    }

    const yamlParent = path.dirname(path.dirname(yamlFile));
    const resolvedPath = path.join(yamlParent, outputFile);
    return this.addSuffixToFilename(resolvedPath, suffix);
  }

  static addSuffixToFilename(filePath, suffix) {
    if (!filePath) return filePath;

    const dirPart = path.dirname(filePath);
    const filePart = path.basename(filePath);
    const namePart = path.parse(filePart).name;
    const extPart = path.parse(filePart).ext;
    return path.join(dirPart, `${namePart}${suffix}${extPart}`);
  }

  static resolveMarkdownPath(markdownFile, yamlPath, appendFirstPage) {
    if (markdownFile === null && appendFirstPage) {
      return path.join(path.dirname(yamlPath), appendFirstPage);
    }
    return markdownFile;
  }
}
