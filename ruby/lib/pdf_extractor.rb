# frozen_string_literal: true

require_relative 'pdf_extractor/version'
require_relative 'pdf_extractor/extractor'
require_relative 'pdf_extractor/command_runner'
require_relative 'pdf_extractor/markdown_converter'
require_relative 'pdf_extractor/cli'

# Main module for PDF page extraction functionality
module PdfExtractor
  class Error < StandardError; end
  class CommandError < Error; end
  class FileNotFoundError < Error; end
end
