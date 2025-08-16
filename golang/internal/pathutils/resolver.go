package pathutils

import (
	"os"
	"path/filepath"
)

// Resolver handles file path resolution logic
type Resolver struct{}

// NewResolver creates a new path resolver
func NewResolver() *Resolver {
	return &Resolver{}
}

// ResolveInputPath resolves the input file path
func (r *Resolver) ResolveInputPath(inputFile, yamlPath string) (string, error) {
	if inputFile == "" {
		return "", nil
	}

	if filepath.IsAbs(inputFile) {
		return inputFile, nil
	}

	// Get project root (parent of yaml directory)
	yamlParent := filepath.Dir(filepath.Dir(yamlPath))

	// Try standard path resolution first (relative to project root)
	standardPath := filepath.Join(yamlParent, inputFile)
	if _, err := os.Stat(standardPath); err == nil {
		return standardPath, nil
	}

	// Fallback: try looking in resources directory for backward compatibility
	fallbackPath := filepath.Join(filepath.Dir(yamlPath), inputFile)
	if _, err := os.Stat(fallbackPath); err == nil {
		return fallbackPath, nil
	}

	return standardPath, nil
}

// ResolveOutputPath resolves the output file path and adds suffix
func (r *Resolver) ResolveOutputPath(outputFile, yamlPath, suffix string) string {
	if outputFile == "" {
		return ""
	}

	var resolvedPath string
	if filepath.IsAbs(outputFile) {
		resolvedPath = outputFile
	} else {
		yamlParent := filepath.Dir(filepath.Dir(yamlPath))
		resolvedPath = filepath.Join(yamlParent, outputFile)
	}

	// Add suffix to filename
	dir := filepath.Dir(resolvedPath)
	base := filepath.Base(resolvedPath)
	ext := filepath.Ext(base)
	name := base[:len(base)-len(ext)]

	return filepath.Join(dir, name+suffix+ext)
}

// ResolveMarkdownPath resolves the markdown file path
func (r *Resolver) ResolveMarkdownPath(markdownFile, yamlPath, appendFirstPage string) *string {
	if markdownFile != "" {
		return &markdownFile
	}

	if appendFirstPage != "" {
		yamlDir := filepath.Dir(yamlPath)
		fullPath := filepath.Join(yamlDir, appendFirstPage)
		return &fullPath
	}

	return nil
}
