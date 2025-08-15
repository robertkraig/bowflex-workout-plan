defmodule PdfExtractor.MarkdownConverter do
  @moduledoc """
  Converts Markdown files to PDF using Earmark and Puppeteer.
  """

  def convert(md_path, output_pdf) do
    md_content = File.read!(md_path)
    html_content = Earmark.as_html!(md_content, %Earmark.Options{gfm: true})

    html_template = """
    <html>
    <head>
        <style>
            body { font-family: Helvetica, Arial, sans-serif; margin: 2em; }
            h1, h2, h3, h4 { color: #2a4d7c; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 1em; }
            th, td { border: 1px solid #888; padding: 0.5em; text-align: left; }
            th { background: #d5e4f3; }
            code { background: #eee; padding: 2px 4px; border-radius: 4px; }
            pre { background: #f4f4f4; padding: 1em; border-radius: 4px; }
            ul { margin: 1em 0; padding-left: 2em; }
            li { margin: 0.5em 0; }
        </style>
    </head>
    <body>#{html_content}</body>
    </html>
    """

    # Write HTML to temporary file
    html_temp = create_temp_file("markdown", ".html")
    File.write!(html_temp, html_template)

    try do
      # Use shared puppeteer_render.js script
      puppeteer_script = Path.join(["..", "puppeteer_render.js"])

      case System.cmd("node", [puppeteer_script, html_temp, output_pdf], stderr_to_stdout: true) do
        {_output, 0} ->
          if File.exists?(output_pdf) do
            :ok
          else
            raise "Failed to create PDF from markdown"
          end

        {output, exit_code} ->
          raise "Failed to convert markdown to PDF. Exit code: #{exit_code}. Output: #{output}"
      end
    after
      File.rm(html_temp)
    end
  end

  defp create_temp_file(prefix, suffix) do
    random = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    filename = "#{prefix}_#{random}#{suffix}"
    Path.join(System.tmp_dir!(), filename)
  end
end
