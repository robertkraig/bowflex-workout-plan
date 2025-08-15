# frozen_string_literal: true

require 'yaml'
require 'open3'
require 'shellwords'
require 'tempfile'

module PdfExtractor
  # Main PDF extraction class following Ruby conventions
  class Extractor
    DEFAULT_CONFIG_PATH = '../resources/config.yaml'

    def initialize(input_pdf:, output_pdf:, config_path: DEFAULT_CONFIG_PATH, markdown_path: nil)
      @input_pdf = File.expand_path(input_pdf)
      @output_pdf = File.expand_path(output_pdf)
      @config_path = File.expand_path(config_path)
      @markdown_path = markdown_path&.then { |path| File.expand_path(path) }
      @temp_files = []
    end

    def extract_pages
      CommandRunner.ensure_pdftk!

      config = load_config
      selected_pages = extract_page_indices(config)

      files_to_merge = []
      files_to_merge << create_markdown_pdf if should_include_markdown?(config)
      files_to_merge << extract_pdf_pages(selected_pages) unless selected_pages.empty?

      merge_or_copy_files(files_to_merge)
      cleanup_temp_files

      puts "Saved to: #{@output_pdf}"
      @output_pdf
    rescue StandardError => e
      cleanup_temp_files
      raise
    end

    private

    attr_reader :input_pdf, :output_pdf, :config_path, :markdown_path, :temp_files

    def load_config
      raise FileNotFoundError, "Config file not found: #{config_path}" unless File.exist?(config_path)

      config = YAML.load_file(config_path)
      validate_config!(config)
      config
    rescue Psych::SyntaxError => e
      raise Error, "Invalid YAML in config file: #{e.message}"
    end

    def validate_config!(config)
      raise Error, 'Config must be a Hash' unless config.is_a?(Hash)
      raise Error, "Config 'pages' must be an Array" unless config['pages'].is_a?(Array)
    end

    def extract_page_indices(config)
      seen_pages = Set.new

      config['pages'].filter_map do |page_config|
        next unless page_config.is_a?(Hash)

        page_index = page_config['pageIndex'] || page_config['page']
        next unless page_index&.respond_to?(:to_i) && !seen_pages.include?(page_index)

        seen_pages << page_index
        page_index.to_i
      end
    end

    def should_include_markdown?(config)
      return true if markdown_path && File.exist?(markdown_path)
      return false unless config['appendFirstPage']

      resolved_path = File.join(File.dirname(config_path), config['appendFirstPage'])
      @markdown_path = resolved_path if File.exist?(resolved_path)

      !@markdown_path.nil?
    end

    def create_markdown_pdf
      temp_pdf = create_temp_file('markdown', '.pdf')
      MarkdownConverter.new(markdown_path, temp_pdf).convert
      temp_pdf
    end

    def extract_pdf_pages(page_indices)
      temp_pdf = create_temp_file('extracted', '.pdf')
      page_range = page_indices.join(' ')

      command = build_pdftk_command(input_pdf, page_range, temp_pdf)
      execute_with_debug(command)

      validate_extracted_file!(temp_pdf)
      temp_pdf
    end

    def build_pdftk_command(input_file, page_range, output_file)
      "pdftk #{input_file.shellescape} cat #{page_range} output #{output_file.shellescape}"
    end

    def execute_with_debug(command)
      puts "Debug: Running command: #{command}"
      result = CommandRunner.execute(command)

      puts "Debug: Exit code: #{result.exit_code}"
      puts "Debug: Stdout: #{result.stdout}" unless result.stdout.empty?
      puts "Debug: Stderr: #{result.stderr}" unless result.stderr.empty?

      return if result.success?

      raise CommandError, build_command_error_message(command, result)
    end

    def build_command_error_message(command, result)
      [
        'Failed to extract pages using pdftk',
        "Command: #{command}",
        "Exit code: #{result.exit_code}",
        ("Stdout: #{result.stdout}" unless result.stdout.empty?),
        ("Stderr: #{result.stderr}" unless result.stderr.empty?)
      ].compact.join('. ')
    end

    def validate_extracted_file!(file_path)
      return if File.exist?(file_path)

      raise Error, "Failed to create extracted PDF: #{file_path}"
    end

    def merge_or_copy_files(files)
      case files.length
      when 0
        raise Error, 'No pages to extract'
      when 1
        copy_file(files.first, output_pdf)
      else
        merge_pdf_files(files, output_pdf)
      end
    end

    def copy_file(source, destination)
      FileUtils.cp(source, destination)
    rescue StandardError => e
      raise Error, "Failed to copy PDF file: #{e.message}"
    end

    def merge_pdf_files(input_files, output_file)
      files_args = input_files.map(&:shellescape).join(' ')
      command = "pdftk #{files_args} cat output #{output_file.shellescape}"

      result = CommandRunner.execute(command)
      return if result.success? && File.exist?(output_file)

      raise CommandError, build_merge_error_message(command, result)
    end

    def build_merge_error_message(command, result)
      [
        'Failed to merge PDFs using pdftk',
        "Command: #{command}",
        "Exit code: #{result.exit_code}",
        ("Stdout: #{result.stdout}" unless result.stdout.empty?),
        ("Stderr: #{result.stderr}" unless result.stderr.empty?)
      ].compact.join('. ')
    end

    def create_temp_file(prefix, suffix)
      temp_file = Tempfile.new([prefix, suffix])
      path = temp_file.path
      temp_file.close
      temp_files << path
      path
    end

    def cleanup_temp_files
      temp_files.each do |file|
        File.unlink(file) if File.exist?(file)
      rescue StandardError
        # Ignore cleanup errors
      end
      temp_files.clear
    end
  end
end
