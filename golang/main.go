package main

import (
	"fmt"
	"os"

	"pdf-page-extractor/internal/cli"
)

func main() {
	cliManager := cli.NewManager()
	rootCmd := cliManager.CreateRootCommand()

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
