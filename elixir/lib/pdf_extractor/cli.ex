defmodule PdfExtractor.CLI do
  @moduledoc """
  Command-line interface for PDF page extraction.
  """

  @default_config_path "../resources/config.yaml"

  def main(args) do
    args
    |> parse_args()
    |> process()
  end

  defp parse_args(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          input: :string,
          output: :string,
          yaml: :string,
          markdown: :string,
          help: :boolean
        ],
        aliases: [
          i: :input,
          o: :output,
          y: :yaml,
          m: :markdown,
          h: :help
        ]
      )

    %{
      input: opts[:input],
      output: opts[:output],
      yaml: opts[:yaml] || @default_config_path,
      markdown: opts[:markdown],
      help: opts[:help] || false
    }
  end

  defp process(%{help: true}) do
    print_help()
  end

  defp process(args) do
    try do
      config = load_config(args.yaml)

      # Resolve input and output paths with fallback logic
      input_file = resolve_input_path(args.input, config, args.yaml)
      output_file = resolve_output_path(args.output, config, args.yaml)
      markdown_file = resolve_markdown_path(args.markdown, config, args.yaml)

      case {input_file, output_file} do
        {nil, _} ->
          IO.puts("Error: Input file must be specified")
          System.halt(1)

        {_, nil} ->
          IO.puts("Error: Output file must be specified")
          System.halt(1)

        {input, output} ->
          case File.exists?(input) do
            true ->
              PdfExtractor.Core.extract_pages(input, output, args.yaml, markdown_file)
              IO.puts("Saved to: #{output}")

            false ->
              IO.puts("Error: '#{input}' not found.")
              System.halt(1)
          end
      end
    rescue
      e ->
        IO.puts("Error: #{Exception.message(e)}")
        System.halt(1)
    end
  end

  defp load_config(yaml_path) do
    case File.read(yaml_path) do
      {:ok, content} ->
        case YamlElixir.read_from_string(content) do
          {:ok, config} -> config
          {:error, reason} -> raise "Invalid YAML: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise "Could not read config file: #{inspect(reason)}"
    end
  end

  defp resolve_input_path(nil, config, yaml_path) do
    case Map.get(config, "file") do
      nil -> nil
      file_path -> resolve_file_path(file_path, yaml_path)
    end
  end

  defp resolve_input_path(input, _config, _yaml_path), do: input

  defp resolve_output_path(nil, config, yaml_path) do
    case Map.get(config, "output") do
      nil -> nil
      output_path ->
        resolved = resolve_file_path(output_path, yaml_path)
        add_elixir_suffix(resolved)
    end
  end

  defp resolve_output_path(output, _config, _yaml_path), do: output

  defp resolve_markdown_path(nil, config, yaml_path) do
    case Map.get(config, "appendFirstPage") do
      nil -> nil
      md_file ->
        yaml_dir = Path.dirname(yaml_path)
        md_path = Path.join(yaml_dir, md_file)
        if File.exists?(md_path), do: md_path, else: nil
    end
  end

  defp resolve_markdown_path(markdown, _config, _yaml_path), do: markdown

  defp resolve_file_path(file_path, yaml_path) do
    cond do
      Path.type(file_path) == :absolute ->
        file_path

      true ->
        # Try standard path resolution first (relative to project root)
        yaml_parent = yaml_path |> Path.dirname() |> Path.dirname()
        standard_path = Path.join(yaml_parent, file_path)

        if File.exists?(standard_path) do
          standard_path
        else
          # Fallback: try resources directory for backward compatibility
          yaml_dir = Path.dirname(yaml_path)
          fallback_path = Path.join(yaml_dir, file_path)
          if File.exists?(fallback_path), do: fallback_path, else: standard_path
        end
    end
  end

  defp add_elixir_suffix(output_path) do
    case String.contains?(output_path, "output/") do
      true ->
        dir = Path.dirname(output_path)
        basename = Path.basename(output_path, ".pdf")
        Path.join(dir, "#{basename}_elixir.pdf")

      false ->
        output_path
    end
  end

  defp print_help do
    IO.puts("""
    Usage: pdf_extractor [options]

    Options:
      -i, --input PDF        Input PDF file path
      -o, --output PDF       Output PDF file path
      -y, --yaml CONFIG      YAML configuration file path
      -m, --markdown MD      Markdown file to prepend
      -h, --help             Show this help message

    Example:
      pdf_extractor --input input.pdf --output output.pdf --yaml config.yaml
    """)
  end
end
