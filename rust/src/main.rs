use anyhow::Result;
use clap::Parser;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
use std::process::Command;
use tempfile::NamedTempFile;

#[derive(Parser)]
#[command(name = "pdf-extractor")]
#[command(about = "Extract selected pages from PDF and optionally prepend Markdown intro")]
struct Args {
    #[arg(long, default_value = "../resources/config.yaml")]
    yaml: String,

    #[arg(long)]
    input: Option<String>,

    #[arg(long)]
    output: Option<String>,

    #[arg(long)]
    markdown: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
struct Config {
    file: Option<String>,
    output: Option<String>,
    #[serde(rename = "appendFirstPage")]
    append_first_page: Option<String>,
    pages: Vec<PageConfig>,
}

#[derive(Debug, Deserialize, Serialize)]
struct PageConfig {
    name: String,
    #[serde(rename = "pageIndex")]
    page_index: Option<u32>,
    page: Option<u32>,
    #[serde(rename = "pageNumber")]
    page_number: Option<u32>,
}

fn markdown_to_pdf_bytes(md_path: &str) -> Result<Vec<u8>> {
    let md_content = fs::read_to_string(md_path)?;

    // Use pulldown-cmark for better markdown parsing with tables enabled
    let mut options = pulldown_cmark::Options::empty();
    options.insert(pulldown_cmark::Options::ENABLE_TABLES);
    options.insert(pulldown_cmark::Options::ENABLE_STRIKETHROUGH);

    let parser = pulldown_cmark::Parser::new_ext(&md_content, options);
    let mut html_content = String::new();
    pulldown_cmark::html::push_html(&mut html_content, parser);


    let html_template = format!(
        r#"
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
                ul {{ margin: 1em 0; padding-left: 2em; }}
                li {{ margin: 0.5em 0; }}
            </style>
        </head>
        <body>{}</body>
        </html>
        "#,
        html_content
    );

    let html_file = NamedTempFile::new()?;
    fs::write(html_file.path(), html_template)?;

    let pdf_file = NamedTempFile::new()?;

    Command::new("node")
        .arg("../puppeteer_render.js")
        .arg(html_file.path())
        .arg(pdf_file.path())
        .status()?;

    let pdf_bytes = fs::read(pdf_file.path())?;
    Ok(pdf_bytes)
}

fn extract_pages(
    input_pdf: &str,
    output_pdf: &str,
    yaml_path: &str,
    md_path: Option<&str>,
) -> Result<()> {
    let config_content = fs::read_to_string(yaml_path)?;
    let config: Config = serde_yaml::from_str(&config_content)?;

    let mut selected_pages = Vec::new();
    let mut seen = std::collections::HashSet::new();

    for page_config in &config.pages {
        let idx = page_config.page_index.or(page_config.page);
        if let Some(idx) = idx {
            if !seen.contains(&idx) {
                selected_pages.push(idx);
                seen.insert(idx);
            }
        }
    }

    let temp_dir = tempfile::tempdir()?;
    let mut files_to_merge = Vec::new();

    // Add markdown PDF if provided
    if let Some(md_path) = md_path {
        let md_pdf_bytes = markdown_to_pdf_bytes(md_path)?;
        let md_pdf_path = temp_dir.path().join("markdown.pdf");
        fs::write(&md_pdf_path, md_pdf_bytes)?;
        files_to_merge.push(md_pdf_path.to_string_lossy().to_string());
    }

    // Extract specified pages using pdftk
    if !selected_pages.is_empty() {
        let pages_str = selected_pages.iter()
            .map(|p| p.to_string())
            .collect::<Vec<_>>()
            .join(" ");

        let extracted_pdf = temp_dir.path().join("extracted.pdf");
        Command::new("pdftk")
            .arg(input_pdf)
            .arg("cat")
            .args(pages_str.split_whitespace())
            .arg("output")
            .arg(&extracted_pdf)
            .status()?;

        files_to_merge.push(extracted_pdf.to_string_lossy().to_string());
    }

    // Merge all PDFs
    if files_to_merge.len() == 1 {
        fs::copy(&files_to_merge[0], output_pdf)?;
    } else if files_to_merge.len() > 1 {
        let mut cmd = Command::new("pdftk");
        for file in &files_to_merge {
            cmd.arg(file);
        }
        cmd.arg("cat")
            .arg("output")
            .arg(output_pdf)
            .status()?;
    }

    println!("Saved to: {}", output_pdf);
    Ok(())
}

fn main() -> Result<()> {
    let args = Args::parse();

    let config_content = fs::read_to_string(&args.yaml)?;
    let config: Config = serde_yaml::from_str(&config_content)?;

    // Get project root (parent of yaml directory)
    let yaml_parent = Path::new(&args.yaml).parent()
        .and_then(|p| p.parent())
        .unwrap_or(Path::new("."));

    let input_file = args.input.or_else(|| {
        config.file.as_ref().map(|f| {
            if Path::new(f).is_absolute() {
                f.clone()
            } else {
                yaml_parent.join(f).to_string_lossy().to_string()
            }
        })
    }).unwrap_or_default();

    let output_file = args.output.or_else(|| {
        config.output.as_ref().map(|f| {
            let path = if Path::new(f).is_absolute() {
                Path::new(f).to_path_buf()
            } else {
                yaml_parent.join(f)
            };

            // Add _rust suffix to filename
            if let Some(stem) = path.file_stem() {
                if let Some(parent) = path.parent() {
                    let new_filename = format!("{}_rust.pdf", stem.to_string_lossy());
                    parent.join(new_filename).to_string_lossy().to_string()
                } else {
                    format!("{}_rust.pdf", stem.to_string_lossy())
                }
            } else {
                path.to_string_lossy().to_string()
            }
        })
    }).unwrap_or_default();

    let md_file = if let Some(md) = args.markdown {
        Some(md)
    } else if let Some(append_first_page) = config.append_first_page {
        let yaml_dir = Path::new(&args.yaml).parent().unwrap_or(Path::new("."));
        let md_path = yaml_dir.join(append_first_page).to_string_lossy().to_string();
        if Path::new(&md_path).exists() {
            Some(md_path)
        } else {
            None
        }
    } else {
        None
    };

    if !Path::new(&input_file).exists() {
        eprintln!("Error: '{}' not found.", input_file);
        return Ok(());
    }

    extract_pages(&input_file, &output_file, &args.yaml, md_file.as_deref())?;

    Ok(())
}
