# pdf_extractor/__main__.py

import io
import os
import subprocess
import tempfile

import yaml
from markdown2 import markdown
from PyPDF2 import PdfReader, PdfWriter


def markdown_to_pdf_bytes(md_path):
    # Convert markdown to PDF using Puppeteer via Node.js
    with open(md_path, "r") as f:
        md_content = f.read()
    html_content = markdown(md_content, extras=["tables"])
    html_template = f"""
    <html>
    <head>
        <style>
            body {{ font-family: Helvetica, Arial, sans-serif; margin: 2em; }}
            h1, h2, h3, h4 {{ color: #2a4d7c; }}
            table {{ border-collapse: collapse; width: 100%; margin-bottom: 1em; }}
            th, td {{ border: 1px solid #888; padding: 0.5em; text-align: left; }}
            th {{ background: #d5e4f3; }}
            code {{ background: #eee; padding: 2px 4px; border-radius: 4px; }}
            pre {{ background: #f4f4f4; padding: 1em; border-radius: 4px; }}
        </style>
    </head>
    <body>{html_content}</body>
    </html>
    """
    with tempfile.NamedTemporaryFile("w+", suffix=".html", delete=False) as html_file:
        html_file.write(html_template)
        html_file.flush()
        html_path = html_file.name
    with tempfile.NamedTemporaryFile("rb", suffix=".pdf", delete=False) as pdf_file:
        pdf_path = pdf_file.name
    try:
        subprocess.run(["node", "puppeteer_render.js", html_path, pdf_path], check=True)
        with open(pdf_path, "rb") as f:
            pdf_bytes = f.read()
    finally:
        os.remove(html_path)
        os.remove(pdf_path)
    return pdf_bytes


def extract_pages(
    input_pdf: str,
    output_pdf: str,
    yaml_path: str = "resources/config.yaml",
    md_path: str = None,
):
    # Read page configuration from YAML
    with open(yaml_path, "r") as f:
        config = yaml.safe_load(f)
        pages = config.get("pages", [])
        append_first_page = config.get("appendFirstPage", None)
    # Use only unique pageIndex values for extraction
    seen = set()
    selected_pages = []
    for page_config in pages:
        idx = (
            page_config.get("pageIndex")
            if "pageIndex" in page_config
            else page_config.get("page")
        )
        if idx is not None and idx not in seen:
            selected_pages.append(idx - 1)
            seen.add(idx)

    reader = PdfReader(input_pdf)
    writer = PdfWriter()

    # If a markdown file is provided, prepend its pages
    if md_path is None and append_first_page:
        md_path = os.path.join(os.path.dirname(yaml_path), append_first_page)
    if md_path:
        # Convert markdown to PDF bytes
        md_pdf_bytes = markdown_to_pdf_bytes(md_path)
        md_reader = PdfReader(io.BytesIO(md_pdf_bytes))
        for page in md_reader.pages:
            writer.add_page(page)

    for page_num in selected_pages:
        if page_num < len(reader.pages):
            writer.add_page(reader.pages[page_num])

    with open(output_pdf, "wb") as f_out:
        writer.write(f_out)

    print(f"Saved to: {output_pdf}")


if __name__ == "__main__":
    import argparse
    import glob

    # Load config.yaml for dynamic defaults
    config_path = "resources/config.yaml"
    config = {}
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)
    default_input = config.get("file")
    default_output = config.get("output")
    append_first_page = config.get("appendFirstPage")
    default_markdown = (
        os.path.join(os.path.dirname(config_path), append_first_page)
        if append_first_page
        else None
    )

    parser = argparse.ArgumentParser(
        description="Extract selected pages from PDF and optionally prepend "
        "Markdown intro."
    )
    parser.add_argument(
        "--input",
        default=default_input,
        help=f"Input PDF file (default from config.yaml: {default_input})",
    )
    parser.add_argument(
        "--output",
        default=default_output,
        help=f"Output PDF file (default from config.yaml: {default_output})",
    )
    parser.add_argument(
        "--yaml", default=config_path, help="YAML file with page configuration"
    )
    parser.add_argument(
        "--markdown",
        default=default_markdown,
        help=f"Markdown file to prepend (default from config.yaml: "
        f"{default_markdown or 'None'})",
    )
    args = parser.parse_args()

    # If --markdown is not set, use appendFirstPage from YAML config
    md_file = args.markdown
    if md_file is None:
        with open(args.yaml, "r") as f:
            config = yaml.safe_load(f)
            append_first_page = config.get("appendFirstPage", None)
            if append_first_page:
                md_file = os.path.join(os.path.dirname(args.yaml), append_first_page)
    if md_file is None:
        md_candidates = glob.glob("resources/*.md")
        if md_candidates:
            md_file = md_candidates[0]
            print(f"Auto-using markdown file: {md_file}")

    # If --input or --output are not set, use 'file' and 'output' from YAML config
    input_file = args.input
    output_file = args.output
    if (not input_file or not output_file) or (
        input_file == parser.get_default("input")
        and output_file == parser.get_default("output")
    ):
        with open(args.yaml, "r") as f:
            config = yaml.safe_load(f)
            if not input_file or input_file == parser.get_default("input"):
                input_file = config.get("file", input_file)
            if not output_file or output_file == parser.get_default("output"):
                output_file = config.get("output", output_file)

    if not os.path.exists(input_file):
        print(f"Error: '{input_file}' not found.")
    else:
        extract_pages(input_file, output_file, args.yaml, md_file)
