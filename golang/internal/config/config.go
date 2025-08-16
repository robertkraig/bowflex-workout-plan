package config

import (
	"io/ioutil"

	"gopkg.in/yaml.v3"
)

type Config struct {
	File            string       `yaml:"file"`
	Output          string       `yaml:"output"`
	AppendFirstPage string       `yaml:"appendFirstPage"`
	Pages           []PageConfig `yaml:"pages"`
}

type PageConfig struct {
	Name       string `yaml:"name"`
	PageIndex  *int   `yaml:"pageIndex"`
	Page       *int   `yaml:"page"`
	PageNumber *int   `yaml:"pageNumber"`
}

// LoadConfig loads configuration from a YAML file
func LoadConfig(yamlPath string) (*Config, error) {
	configContent, err := ioutil.ReadFile(yamlPath)
	if err != nil {
		return nil, err
	}

	var config Config
	err = yaml.Unmarshal(configContent, &config)
	if err != nil {
		return nil, err
	}

	return &config, nil
}

// ExtractPageIndices extracts unique page indices from the configuration
func (c *Config) ExtractPageIndices() []int {
	var selectedPages []int
	seen := make(map[int]bool)

	for _, pageConfig := range c.Pages {
		var idx *int
		if pageConfig.PageIndex != nil {
			idx = pageConfig.PageIndex
		} else if pageConfig.Page != nil {
			idx = pageConfig.Page
		}

		if idx != nil && !seen[*idx] {
			selectedPages = append(selectedPages, *idx)
			seen[*idx] = true
		}
	}

	return selectedPages
}
