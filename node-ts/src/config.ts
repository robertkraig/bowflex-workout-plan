import fs from 'fs/promises';
import yaml from 'yaml';
import { Config } from './types.js';

export class ConfigManager {
  async loadConfig(yamlPath: string): Promise<Config> {
    const configContent = await fs.readFile(yamlPath, 'utf8');
    return yaml.parse(configContent);
  }

  async loadDefaultConfig(configPath: string = '../resources/config.yaml'): Promise<Config> {
    try {
      return await this.loadConfig(configPath);
    } catch (error) {
      return {};
    }
  }

  extractPageIndices(config: Config): number[] {
    const pages = config.pages || [];
    const seen = new Set<number>();
    const selectedPages: number[] = [];

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
