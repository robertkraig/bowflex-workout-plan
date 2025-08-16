package pdf

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"

	"pdf-page-extractor/internal/markdown"
)

// Processor handles PDF operations
type Processor struct {
	markdownConverter *markdown.Converter
}

// NewProcessor creates a new PDF processor
func NewProcessor() *Processor {
	return &Processor{
		markdownConverter: markdown.NewConverter(),
	}
}

// ExtractPages extracts specified pages and optionally prepends markdown
func (p *Processor) ExtractPages(inputPDF, outputPDF string, selectedPages []int, mdPath *string) error {
	// Create temporary directory
	tempDir, err := ioutil.TempDir("", "pdf-extractor")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	var filesToMerge []string

	// Add markdown PDF if provided
	if mdPath != nil {
		mdPDFBytes, err := p.markdownConverter.ConvertToPDFBytes(*mdPath)
		if err != nil {
			return err
		}

		mdPDFPath := filepath.Join(tempDir, "markdown.pdf")
		err = ioutil.WriteFile(mdPDFPath, mdPDFBytes, 0644)
		if err != nil {
			return err
		}
		filesToMerge = append(filesToMerge, mdPDFPath)
	}

	// Extract specified pages using pdftk
	if len(selectedPages) > 0 {
		extractedPDF, err := p.extractPagesToPDF(inputPDF, selectedPages, tempDir)
		if err != nil {
			return err
		}
		filesToMerge = append(filesToMerge, extractedPDF)
	}

	// Merge all PDFs
	err = p.mergePDFs(filesToMerge, outputPDF)
	if err != nil {
		return err
	}

	fmt.Printf("Saved to: %s\n", outputPDF)
	return nil
}

// extractPagesToPDF extracts specific pages to a temporary PDF file
func (p *Processor) extractPagesToPDF(inputPDF string, selectedPages []int, tempDir string) (string, error) {
	var pagesStr []string
	for _, page := range selectedPages {
		pagesStr = append(pagesStr, strconv.Itoa(page))
	}

	extractedPDF := filepath.Join(tempDir, "extracted.pdf")
	args := []string{inputPDF, "cat"}
	args = append(args, pagesStr...)
	args = append(args, "output", extractedPDF)

	cmd := exec.Command("pdftk", args...)
	err := cmd.Run()
	if err != nil {
		return "", err
	}

	return extractedPDF, nil
}

// mergePDFs merges multiple PDF files into one output file
func (p *Processor) mergePDFs(filesToMerge []string, outputPDF string) error {
	if len(filesToMerge) == 1 {
		// Just copy the single file
		input, err := ioutil.ReadFile(filesToMerge[0])
		if err != nil {
			return err
		}
		return ioutil.WriteFile(outputPDF, input, 0644)
	} else if len(filesToMerge) > 1 {
		// Merge multiple files
		args := filesToMerge
		args = append(args, "cat", "output", outputPDF)

		cmd := exec.Command("pdftk", args...)
		return cmd.Run()
	}

	return nil
}
