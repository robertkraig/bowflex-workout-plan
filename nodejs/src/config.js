import fs from 'fs/promises';
import yaml from 'yaml';
import path from 'path';

export class ConfigManager {
  async loadConfig(yamlPath) {
    const configContent = await fs.readFile(yamlPath, 'utf8');
    return yaml.parse(configContent);
  }

  async loadDefaultConfig(configPath = '../resources/config.yaml') {
    try {
      return await this.loadConfig(configPath);
    } catch (error) {
      return {};
    }
  }

  extractPageIndices(config) {
    const pages = config.pages || [];
    const seen = new Set();
    const selectedPages = [];

    for (const pageConfig of pages) {
      const idx = pageConfig.pageIndex || pageConfig.page;
      if (idx !== undefined && idx !== null && !seen.has(idx)) {
        selectedPages.push(idx - 1); // Convert to 0-based index
        seen.add(idx);
      }
    }

    return selectedPages;
  }
}
