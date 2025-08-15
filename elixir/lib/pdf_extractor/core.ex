defmodule PdfExtractor.Core do
  @moduledoc """
  Core PDF extraction functionality.
  """

  def extract_pages(input_pdf, output_pdf, yaml_path, markdown_path \\ nil) do
    config = load_config(yaml_path)
    selected_pages = extract_page_indices(config)

    files_to_merge = []

    # Add markdown PDF if needed
    files_to_merge =
      case should_include_markdown?(markdown_path, config, yaml_path) do
        {true, md_path} ->
          md_pdf = create_markdown_pdf(md_path)
          [md_pdf | files_to_merge]

        {false, _} ->
          files_to_merge
      end

    # Add extracted pages if any
    files_to_merge =
      case selected_pages do
        [] ->
          files_to_merge

        pages ->
          extracted_pdf = extract_pdf_pages(input_pdf, pages)
          files_to_merge ++ [extracted_pdf]
      end

    case files_to_merge do
      [] ->
        raise "No pages to extract"

      [single_file] ->
        File.cp!(single_file, output_pdf)
        cleanup_temp_file(single_file)

      multiple_files ->
        merge_pdf_files(multiple_files, output_pdf)
        Enum.each(multiple_files, &cleanup_temp_file/1)
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

  defp extract_page_indices(config) do
    config
    |> Map.get("pages", [])
    |> Enum.reduce({[], MapSet.new()}, fn page_config, {acc, seen} ->
      page_index =
        Map.get(page_config, "pageIndex") || Map.get(page_config, "page")

      cond do
        page_index == nil -> {acc, seen}
        MapSet.member?(seen, page_index) -> {acc, seen}
        true -> {acc ++ [page_index], MapSet.put(seen, page_index)}
      end
    end)
    |> elem(0)
  end

  defp should_include_markdown?(nil, config, yaml_path) do
    case Map.get(config, "appendFirstPage") do
      nil ->
        {false, nil}

      md_file ->
        yaml_dir = Path.dirname(yaml_path)
        md_path = Path.join(yaml_dir, md_file)
        {File.exists?(md_path), md_path}
    end
  end

  defp should_include_markdown?(markdown_path, _config, _yaml_path) do
    {File.exists?(markdown_path), markdown_path}
  end

  defp create_markdown_pdf(md_path) do
    temp_pdf = create_temp_file("markdown", ".pdf")
    PdfExtractor.MarkdownConverter.convert(md_path, temp_pdf)
    temp_pdf
  end

  defp extract_pdf_pages(input_pdf, page_indices) do
    temp_pdf = create_temp_file("extracted", ".pdf")
    page_range = Enum.join(page_indices, " ")

    command = build_pdftk_command(input_pdf, page_range, temp_pdf)

    IO.puts("Debug: Running command: #{command}")

    case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
      {output, 0} ->
        IO.puts("Debug: Exit code: 0")
        unless String.trim(output) == "" do
          IO.puts("Debug: Output: #{output}")
        end

        if File.exists?(temp_pdf) do
          temp_pdf
        else
          raise "Failed to create extracted PDF: #{temp_pdf}"
        end

      {output, exit_code} ->
        IO.puts("Debug: Exit code: #{exit_code}")
        IO.puts("Debug: Output: #{output}")
        raise "Failed to extract pages using pdftk. Command: #{command}. Exit code: #{exit_code}. Output: #{output}"
    end
  end

  defp build_pdftk_command(input_file, page_range, output_file) do
    "pdftk #{shell_escape(input_file)} cat #{page_range} output #{shell_escape(output_file)}"
  end

  defp merge_pdf_files(input_files, output_file) do
    files_args = Enum.map_join(input_files, " ", &shell_escape/1)
    command = "pdftk #{files_args} cat output #{shell_escape(output_file)}"

    case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
      {_output, 0} when true ->
        if File.exists?(output_file) do
          :ok
        else
          raise "Failed to create merged PDF: #{output_file}"
        end

      {output, exit_code} ->
        raise "Failed to merge PDFs using pdftk. Command: #{command}. Exit code: #{exit_code}. Output: #{output}"
    end
  end

  defp shell_escape(path) do
    "'" <> String.replace(path, "'", "'\"'\"'") <> "'"
  end

  defp create_temp_file(prefix, suffix) do
    random = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    filename = "#{prefix}_#{random}#{suffix}"
    Path.join(System.tmp_dir!(), filename)
  end

  defp cleanup_temp_file(file_path) do
    case File.rm(file_path) do
      :ok -> :ok
      {:error, _reason} -> :ok  # Ignore cleanup errors
    end
  end
end
