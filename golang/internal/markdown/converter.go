package markdown

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"

	"github.com/russross/blackfriday/v2"
)

// Converter handles markdown to PDF conversion
type Converter struct{}

// NewConverter creates a new markdown converter
func NewConverter() *Converter {
	return &Converter{}
}

// generateHTMLTemplate creates the HTML template with styling
func (c *Converter) generateHTMLTemplate(htmlContent []byte) string {
	return fmt.Sprintf(`
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
}

// ConvertToPDFBytes converts markdown file to PDF bytes
func (c *Converter) ConvertToPDFBytes(mdPath string) ([]byte, error) {
	mdContent, err := ioutil.ReadFile(mdPath)
	if err != nil {
		return nil, err
	}

	htmlContent := blackfriday.Run(mdContent)
	htmlTemplate := c.generateHTMLTemplate(htmlContent)

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
