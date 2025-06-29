# bowflex_workout_exporter/__main__.py

import os
import yaml
from PyPDF2 import PdfReader, PdfWriter
import io
from markdown2 import markdown
import tempfile
import subprocess
import os

def markdown_to_pdf_bytes(md_path):
    # Convert markdown to PDF using Puppeteer via Node.js
    with open(md_path, 'r') as f:
        md_content = f.read()
    html_content = markdown(md_content, extras=["tables"])
    html_template = f'''
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
    '''
    with tempfile.NamedTemporaryFile('w+', suffix='.html', delete=False) as html_file:
        html_file.write(html_template)
        html_file.flush()
        html_path = html_file.name
    with tempfile.NamedTemporaryFile('rb', suffix='.pdf', delete=False) as pdf_file:
        pdf_path = pdf_file.name
    try:
        subprocess.run([
            'node', 'puppeteer_render.js', html_path, pdf_path
        ], check=True)
        with open(pdf_path, 'rb') as f:
            pdf_bytes = f.read()
    finally:
        os.remove(html_path)
        os.remove(pdf_path)
    return pdf_bytes

def extract_workout_pages(input_pdf: str, output_pdf: str, yaml_path: str = "resources/workouts.yaml", md_path: str = None):
    # Read workout pages from YAML
    with open(yaml_path, 'r') as f:
        workouts = yaml.safe_load(f)['workouts']
    # Use only unique pageIndex values for extraction
    seen = set()
    exercise_pages = []
    for w in workouts:
        idx = w.get('pageIndex') if 'pageIndex' in w else w.get('page')
        if idx is not None and idx not in seen:
            exercise_pages.append(idx-1)
            seen.add(idx)

    reader = PdfReader(input_pdf)
    writer = PdfWriter()

    # If a markdown file is provided, prepend its pages
    if md_path:
        # Convert markdown to PDF bytes
        md_pdf_bytes = markdown_to_pdf_bytes(md_path)
        md_reader = PdfReader(io.BytesIO(md_pdf_bytes))
        for page in md_reader.pages:
            writer.add_page(page)

    for page_num in exercise_pages:
        if page_num < len(reader.pages):
            writer.add_page(reader.pages[page_num])

    with open(output_pdf, "wb") as f_out:
        writer.write(f_out)

    print(f"Saved to: {output_pdf}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Export workout pages and prepend Markdown intro.")
    parser.add_argument('--input', default="resources/BFX.Xceed.Global.OM.EN.pdf", help="Input PDF file")
    parser.add_argument('--output', default="output/Bowflex_Workout_Booklet.pdf", help="Output PDF file")
    parser.add_argument('--yaml', default="resources/workouts.yaml", help="YAML file with workout pages")
    parser.add_argument('--markdown', default="resources/workout_plan.md", help="Markdown file to prepend (default: resources/workout_plan.md, will auto-detect in resources/ if not set)")
    args = parser.parse_args()

    # Auto-detect markdown file in resources if not set
    md_file = args.markdown
    if md_file is None:
        import glob
        md_candidates = glob.glob("resources/*.md")
        if md_candidates:
            md_file = md_candidates[0]
            print(f"Auto-using markdown file: {md_file}")

    if not os.path.exists(args.input):
        print(f"Error: '{args.input}' not found.")
    else:
        extract_workout_pages(args.input, args.output, args.yaml, md_file)
