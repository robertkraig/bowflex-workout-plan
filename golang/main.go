package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"

	"github.com/russross/blackfriday/v2"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
)

type Config struct {
	File            string       `yaml:"file"`
	Output          string       `yaml:"output"`
	AppendFirstPage string       `yaml:"appendFirstPage"`
	Pages           []PageConfig `yaml:"pages"`
}

type PageConfig struct {
	Name      string `yaml:"name"`
	PageIndex *int   `yaml:"pageIndex"`
	Page      *int   `yaml:"page"`
	PageNumber *int  `yaml:"pageNumber"`
}

func markdownToPDFBytes(mdPath string) ([]byte, error) {
	mdContent, err := ioutil.ReadFile(mdPath)
	if err != nil {
		return nil, err
	}

	htmlContent := blackfriday.Run(mdContent)
	htmlTemplate := fmt.Sprintf(`
		<html>
		<head>
			<style>
				body { font-family: Helvetica, Arial, sans-serif; margin: 2em; }
				h1, h2, h3, h4 { color: #2a4d7c; }
				table { border-collapse: collapse; width: 100%%; margin-bottom: 1em; }
				th, td { border: 1px solid #888; padding: 0.5em; text-align: left; }
				th { background: #d5e4f3; }
				code { background: #eee; padding: 2px 4px; border-radius: 4px; }
				pre { background: #f4f4f4; padding: 1em; border-radius: 4px; }
				ul { margin: 1em 0; padding-left: 2em; }
				li { margin: 0.5em 0; }
			</style>
		</head>
		<body>%s</body>
		</html>
	`, htmlContent)

	htmlFile, err := ioutil.TempFile("", "*.html")
	if err != nil {
		return nil, err
	}
	defer os.Remove(htmlFile.Name())

	_, err = htmlFile.WriteString(htmlTemplate)
	if err != nil {
		return nil, err
	}
	htmlFile.Close()

	pdfFile, err := ioutil.TempFile("", "*.pdf")
	if err != nil {
		return nil, err
	}
	defer os.Remove(pdfFile.Name())
	pdfFile.Close()

	cmd := exec.Command("node", "../puppeteer_render.js", htmlFile.Name(), pdfFile.Name())
	err = cmd.Run()
	if err != nil {
		return nil, err
	}

	return ioutil.ReadFile(pdfFile.Name())
}

func extractPages(inputPDF, outputPDF, yamlPath string, mdPath *string) error {
	configContent, err := ioutil.ReadFile(yamlPath)
	if err != nil {
		return err
	}

	var config Config
	err = yaml.Unmarshal(configContent, &config)
	if err != nil {
		return err
	}

	var selectedPages []int
	seen := make(map[int]bool)

	for _, pageConfig := range config.Pages {
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

	// Create temporary directory
	tempDir, err := ioutil.TempDir("", "pdf-extractor")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tempDir)

	var filesToMerge []string

	// Add markdown PDF if provided
	if mdPath != nil {
		mdPDFBytes, err := markdownToPDFBytes(*mdPath)
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
		var pagesStr []string
		for _, page := range selectedPages {
			pagesStr = append(pagesStr, strconv.Itoa(page))
		}

		extractedPDF := filepath.Join(tempDir, "extracted.pdf")
		args := []string{inputPDF, "cat"}
		args = append(args, pagesStr...)
		args = append(args, "output", extractedPDF)

		cmd := exec.Command("pdftk", args...)
		err = cmd.Run()
		if err != nil {
			return err
		}

		filesToMerge = append(filesToMerge, extractedPDF)
	}

	// Merge all PDFs
	if len(filesToMerge) == 1 {
		// Just copy the single file
		input, err := ioutil.ReadFile(filesToMerge[0])
		if err != nil {
			return err
		}
		err = ioutil.WriteFile(outputPDF, input, 0644)
		if err != nil {
			return err
		}
	} else if len(filesToMerge) > 1 {
		// Merge multiple files
		args := filesToMerge
		args = append(args, "cat", "output", outputPDF)

		cmd := exec.Command("pdftk", args...)
		err = cmd.Run()
		if err != nil {
			return err
		}
	}

	fmt.Printf("Saved to: %s\n", outputPDF)
	return nil
}

var rootCmd = &cobra.Command{
	Use:   "pdf-extractor",
	Short: "Extract selected pages from PDF and optionally prepend Markdown intro",
	RunE: func(cmd *cobra.Command, args []string) error {
		yamlPath, _ := cmd.Flags().GetString("yaml")
		inputFile, _ := cmd.Flags().GetString("input")
		outputFile, _ := cmd.Flags().GetString("output")
		markdownFile, _ := cmd.Flags().GetString("markdown")

		configContent, err := ioutil.ReadFile(yamlPath)
		if err != nil {
			return err
		}

		var config Config
		err = yaml.Unmarshal(configContent, &config)
		if err != nil {
			return err
		}

		// Get project root (parent of yaml directory)
		yamlParent := filepath.Dir(filepath.Dir(yamlPath))

		if inputFile == "" {
			inputFile = config.File
			if inputFile != "" && !filepath.IsAbs(inputFile) {
				// Try standard path resolution first (relative to project root)
				standardPath := filepath.Join(yamlParent, inputFile)
				if _, err := os.Stat(standardPath); err == nil {
					inputFile = standardPath
				} else {
					// Fallback: try looking in resources directory for backward compatibility
					fallbackPath := filepath.Join(filepath.Dir(yamlPath), inputFile)
					if _, err := os.Stat(fallbackPath); err == nil {
						inputFile = fallbackPath
					} else {
						inputFile = standardPath
					}
				}
			}
		}
		if outputFile == "" {
			outputFile = config.Output
			if outputFile != "" && !filepath.IsAbs(outputFile) {
				outputFile = filepath.Join(yamlParent, outputFile)
			}

			// Add _golang suffix to filename
			if outputFile != "" {
				dir := filepath.Dir(outputFile)
				base := filepath.Base(outputFile)
				ext := filepath.Ext(base)
				name := base[:len(base)-len(ext)]
				outputFile = filepath.Join(dir, name+"_golang"+ext)
			}
		}

		var mdFile *string
		if markdownFile != "" {
			mdFile = &markdownFile
		} else if config.AppendFirstPage != "" {
			yamlDir := filepath.Dir(yamlPath)
			fullPath := filepath.Join(yamlDir, config.AppendFirstPage)
			mdFile = &fullPath
		}

		if _, err := os.Stat(inputFile); os.IsNotExist(err) {
			fmt.Printf("Error: '%s' not found.\n", inputFile)
			return nil
		}

		return extractPages(inputFile, outputFile, yamlPath, mdFile)
	},
}

func init() {
	rootCmd.Flags().StringP("yaml", "y", "../resources/config.yaml", "YAML file with page configuration")
	rootCmd.Flags().StringP("input", "i", "", "Input PDF file")
	rootCmd.Flags().StringP("output", "o", "", "Output PDF file")
	rootCmd.Flags().StringP("markdown", "m", "", "Markdown file to prepend")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
