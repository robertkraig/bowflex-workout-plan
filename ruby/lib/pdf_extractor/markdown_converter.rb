# frozen_string_literal: true

require 'tempfile'

module PdfExtractor
  # Converts Markdown files to PDF using Node.js Puppeteer
  class MarkdownConverter
    PUPPETEER_SCRIPT = '../puppeteer_render.js'

    HTML_TEMPLATE = <<~HTML
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
    HTML

    def initialize(markdown_path, output_path)
      @markdown_path = markdown_path
      @output_path = output_path
      validate_input!
    end

    def convert
      markdown_content = read_markdown
      html_content = process_markdown(markdown_content)

      create_temp_html(html_content) do |html_file|
        render_pdf(html_file)
      end

      validate_output!
      @output_path
    end

    private

    attr_reader :markdown_path, :output_path

    def validate_input!
      return if File.exist?(@markdown_path)

      raise FileNotFoundError, "Markdown file not found: #{@markdown_path}"
    end

    def validate_output!
      return if File.exist?(@output_path)

      raise Error, "Failed to generate PDF: #{@output_path}"
    end

    def read_markdown
      File.read(@markdown_path)
    rescue StandardError => e
      raise FileNotFoundError, "Failed to read markdown file #{@markdown_path}: #{e.message}"
    end

    def process_markdown(content)
      # Simple markdown processing - in a real implementation, you might use a gem like kramdown
      content.gsub(/^# (.+)$/, '<h1>\\1</h1>')
             .gsub(/^## (.+)$/, '<h2>\\1</h2>')
             .gsub(/^### (.+)$/, '<h3>\\1</h3>')
             .gsub(/\*\*(.+?)\*\*/, '<strong>\\1</strong>')
             .gsub(/\*(.+?)\*/, '<em>\\1</em>')
             .gsub(/\n\n/, '</p><p>')
             .then { |processed| "<p>#{processed}</p>" }
    end

    def create_temp_html(content)
      Tempfile.create(['markdown', '.html']) do |file|
        file.write(format(HTML_TEMPLATE, content))
        file.flush
        yield file.path
      end
    end

    def render_pdf(html_file_path)
      command = "node #{PUPPETEER_SCRIPT} #{html_file_path.shellescape} #{@output_path.shellescape}"
      result = CommandRunner.execute(command)

      return if result.success?

      error_msg = build_error_message(command, result)
      raise CommandError, error_msg
    end

    def build_error_message(command, result)
      parts = ["Failed to convert markdown to PDF"]
      parts << "Command: #{command}"
      parts << "Exit code: #{result.exit_code}"
      parts << "Stdout: #{result.stdout}" unless result.stdout.empty?
      parts << "Stderr: #{result.stderr}" unless result.stderr.empty?

      parts.join('. ')
    end
  end
end
