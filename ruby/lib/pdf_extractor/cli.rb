# frozen_string_literal: true

require 'optparse'

module PdfExtractor
  # Command-line interface following Ruby conventions
  class CLI
    DEFAULT_OPTIONS = {
      config: '../resources/config.yaml',
      input: nil,
      output: nil,
      markdown: nil
    }.freeze

    def self.run(argv = ARGV)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv
      @options = DEFAULT_OPTIONS.dup
    end

    def run
      parse_arguments!
      load_config_defaults
      validate_required_options!

      extract_pages
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      error_exit("#{e.message}\n\n#{option_parser}")
    rescue PdfExtractor::Error => e
      error_exit("Error: #{e.message}")
    rescue StandardError => e
      error_exit("Unexpected error: #{e.message}")
    end

    private

    attr_reader :argv, :options

    def parse_arguments!
      option_parser.parse!(argv)
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      raise
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = 'Usage: ruby main.rb [options]'
        opts.separator ''
        opts.separator 'Options:'

        opts.on('-i', '--input PDF', 'Input PDF file path') do |input|
          options[:input] = input
        end

        opts.on('-o', '--output PDF', 'Output PDF file path') do |output|
          options[:output] = output
        end

        opts.on('-y', '--yaml CONFIG', 'YAML configuration file path') do |config|
          options[:config] = config
        end

        opts.on('-m', '--markdown MARKDOWN', 'Markdown file to prepend') do |markdown|
          options[:markdown] = markdown
        end

        opts.on('-h', '--help', 'Show this help message') do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Show version') do
          puts "PDF Extractor v#{PdfExtractor::VERSION}"
          exit
        end
      end
    end

    def load_config_defaults
      return unless File.exist?(expanded_config_path)

      config = YAML.load_file(expanded_config_path)
      return unless config.is_a?(Hash)

      options[:input] ||= resolve_input_path(config['file'])
      options[:output] ||= resolve_relative_path(config['output'], suffix: '_ruby')

      return unless config['appendFirstPage'] && !options[:markdown]

      markdown_path = File.join(File.dirname(expanded_config_path), config['appendFirstPage'])
      options[:markdown] = markdown_path if File.exist?(markdown_path)
    rescue Psych::SyntaxError
      # Ignore YAML errors when loading defaults
    end

    def resolve_input_path(path)
      return nil unless path

      # First try standard path resolution (relative to project root)
      standard_path = resolve_relative_path(path)
      return standard_path if File.exist?(standard_path)

      # Fallback: try looking in resources directory for backward compatibility
      config_dir = File.dirname(expanded_config_path)
      fallback_path = File.expand_path(path, config_dir)
      return fallback_path if File.exist?(fallback_path)

      # Return the standard path even if it doesn't exist (for error reporting)
      standard_path
    end

    def resolve_relative_path(path, suffix: nil)
      return nil unless path

      # Resolve paths relative to project root (2 levels up from config file)
      # This matches the pattern used by other language implementations
      config_parent = File.dirname(File.dirname(expanded_config_path))
      expanded = File.expand_path(path, config_parent)
      return add_suffix(expanded, suffix) if suffix && path.include?('output/')

      expanded
    end

    def add_suffix(path, suffix)
      dir = File.dirname(path)
      basename = File.basename(path, '.pdf')
      File.join(dir, "#{basename}#{suffix}.pdf")
    end

    def expanded_config_path
      @expanded_config_path ||= File.expand_path(options[:config])
    end

    def validate_required_options!
      missing = []
      missing << '--input' unless options[:input]
      missing << '--output' unless options[:output]

      return if missing.empty?

      error_exit("Missing required arguments: #{missing.join(', ')}")
    end

    def extract_pages
      extractor = Extractor.new(
        input_pdf: options[:input],
        output_pdf: options[:output],
        config_path: options[:config],
        markdown_path: options[:markdown]
      )

      extractor.extract_pages
    end

    def error_exit(message)
      warn message
      exit 1
    end
  end
end
