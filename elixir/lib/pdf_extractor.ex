defmodule PdfExtractor do
  @moduledoc """
  PDF page extractor for Elixir.

  This module provides functionality to extract specific pages from PDF files
  and optionally prepend Markdown content as styled introductions.
  """

  @doc """
  Extract pages from a PDF file based on configuration.
  """
  defdelegate extract_pages(input_pdf, output_pdf, yaml_path, markdown_path \\ nil),
    to: PdfExtractor.Core
end
