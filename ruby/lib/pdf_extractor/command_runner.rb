# frozen_string_literal: true

require 'timeout'

module PdfExtractor
  # Executes external commands with proper stdout/stderr capture
  class CommandRunner
    CommandResult = Struct.new(:stdout, :stderr, :exit_code, :success?) do
      def success?
        exit_code.zero?
      end
    end

    class << self
      def execute(command, timeout: 30)
        stdout, stderr, status = Timeout.timeout(timeout) do
          Open3.capture3(command)
        end

        CommandResult.new(
          stdout&.strip || '',
          stderr&.strip || '',
          status.exitstatus || -1,
          status.success?
        )
      rescue Timeout::Error
        raise CommandError, "Command timed out after #{timeout} seconds: #{command}"
      rescue StandardError => e
        raise CommandError, "Failed to execute command '#{command}': #{e.message}"
      end

      def pdftk_available?
        result = execute('which pdftk')
        result.success? && !result.stdout.empty?
      end

      def ensure_pdftk!
        return if pdftk_available?

        raise CommandError, 'pdftk is required but not installed. Please install pdftk.'
      end
    end

    private_class_method :new
  end
end
