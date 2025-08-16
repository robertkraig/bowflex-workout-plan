package cli

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"pdf-page-extractor/internal/config"
	"pdf-page-extractor/internal/pathutils"
	"pdf-page-extractor/internal/pdf"
)

// Manager handles CLI operations
type Manager struct {
	pathResolver *pathutils.Resolver
	pdfProcessor *pdf.Processor
}

// NewManager creates a new CLI manager
func NewManager() *Manager {
	return &Manager{
		pathResolver: pathutils.NewResolver(),
		pdfProcessor: pdf.NewProcessor(),
	}
}

// CreateRootCommand creates the root cobra command
func (m *Manager) CreateRootCommand() *cobra.Command {
	rootCmd := &cobra.Command{
		Use:   "pdf-extractor",
		Short: "Extract selected pages from PDF and optionally prepend Markdown intro",
		RunE:  m.runCommand,
	}

	rootCmd.Flags().StringP("yaml", "y", "../resources/config.yaml", "YAML file with page configuration")
	rootCmd.Flags().StringP("input", "i", "", "Input PDF file")
	rootCmd.Flags().StringP("output", "o", "", "Output PDF file")
	rootCmd.Flags().StringP("markdown", "m", "", "Markdown file to prepend")

	return rootCmd
}

// runCommand handles the main command execution
func (m *Manager) runCommand(cmd *cobra.Command, args []string) error {
	yamlPath, _ := cmd.Flags().GetString("yaml")
	inputFile, _ := cmd.Flags().GetString("input")
	outputFile, _ := cmd.Flags().GetString("output")
	markdownFile, _ := cmd.Flags().GetString("markdown")

	// Load configuration
	cfg, err := config.LoadConfig(yamlPath)
	if err != nil {
		return err
	}

	// Resolve input file path
	if inputFile == "" {
		inputFile = cfg.File
	}
	resolvedInputFile, err := m.pathResolver.ResolveInputPath(inputFile, yamlPath)
	if err != nil {
		return err
	}

	// Resolve output file path
	if outputFile == "" {
		outputFile = cfg.Output
	}
	resolvedOutputFile := m.pathResolver.ResolveOutputPath(outputFile, yamlPath, "_golang")

	// Resolve markdown file path
	resolvedMarkdownFile := m.pathResolver.ResolveMarkdownPath(markdownFile, yamlPath, cfg.AppendFirstPage)

	// Check if input file exists
	if _, err := os.Stat(resolvedInputFile); os.IsNotExist(err) {
		fmt.Printf("Error: '%s' not found.\n", resolvedInputFile)
		return nil
	}

	// Extract page indices
	selectedPages := cfg.ExtractPageIndices()

	// Process PDF
	return m.pdfProcessor.ExtractPages(resolvedInputFile, resolvedOutputFile, selectedPages, resolvedMarkdownFile)
}
