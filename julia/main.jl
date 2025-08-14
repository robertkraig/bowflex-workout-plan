using ArgParse
using YAML
using Markdown
using Dates

struct PageConfig
    name::String
    pageIndex::Union{Int, Nothing}
    page::Union{Int, Nothing}
    pageNumber::Union{Int, Nothing}
end

struct Config
    file::Union{String, Nothing}
    output::Union{String, Nothing}
    appendFirstPage::Union{String, Nothing}
    pages::Vector{PageConfig}
end

function parse_config(yaml_path::String)::Config
    config_dict = YAML.load_file(yaml_path)

    pages = PageConfig[]
    if haskey(config_dict, "pages")
        for page_dict in config_dict["pages"]
            push!(pages, PageConfig(
                get(page_dict, "name", ""),
                get(page_dict, "pageIndex", nothing),
                get(page_dict, "page", nothing),
                get(page_dict, "pageNumber", nothing)
            ))
        end
    end

    return Config(
        get(config_dict, "file", nothing),
        get(config_dict, "output", nothing),
        get(config_dict, "appendFirstPage", nothing),
        pages
    )
end

function markdown_to_pdf_bytes(md_path::String)::Vector{UInt8}
    # Read markdown content
    md_content = read(md_path, String)

    # Convert to HTML
    html_content = sprint(show, MIME("text/html"), Markdown.parse(md_content))

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
    <body>$html_content</body>
    </html>
    """

    # Create temporary HTML file
    html_temp = tempname() * ".html"
    write(html_temp, html_template)

    # Create temporary PDF file
    pdf_temp = tempname() * ".pdf"

    try
        # Use Node.js Puppeteer for PDF generation
        run(`node ../puppeteer_render.js $html_temp $pdf_temp`)
        pdf_bytes = read(pdf_temp)
        return pdf_bytes
    finally
        # Clean up temporary files
        isfile(html_temp) && rm(html_temp)
        isfile(pdf_temp) && rm(pdf_temp)
    end
end

function extract_pages_with_pdftk(input_pdf::String, output_pdf::String, page_numbers::Vector{Int}, md_path::Union{String, Nothing}=nothing)
    # Create temporary directory for processing
    temp_dir = mktempdir()

    try
        files_to_merge = String[]

        # Add markdown PDF if provided
        if md_path !== nothing
            md_pdf_bytes = markdown_to_pdf_bytes(md_path)
            md_pdf_path = joinpath(temp_dir, "markdown.pdf")
            write(md_pdf_path, md_pdf_bytes)
            push!(files_to_merge, md_pdf_path)
        end

        # Extract specified pages
        if !isempty(page_numbers)
            pages_args = string.(page_numbers)
            extracted_pdf = joinpath(temp_dir, "extracted.pdf")
            cmd = `pdftk $input_pdf cat`
            for page in pages_args
                cmd = `$cmd $page`
            end
            cmd = `$cmd output $extracted_pdf`
            run(cmd)
            push!(files_to_merge, extracted_pdf)
        end

        # Merge all PDFs
        if length(files_to_merge) == 1
            cp(files_to_merge[1], output_pdf)
        elseif length(files_to_merge) > 1
            cmd = `pdftk`
            for file in files_to_merge
                cmd = `$cmd $file`
            end
            cmd = `$cmd cat output $output_pdf`
            run(cmd)
        end

    finally
        # Clean up temporary directory
        rm(temp_dir, recursive=true)
    end
end

function extract_pages(input_pdf::String, output_pdf::String, yaml_path::String, md_path::Union{String, Nothing}=nothing)
    # Parse configuration
    config = parse_config(yaml_path)

    # Get unique page numbers
    selected_pages = Int[]
    seen = Set{Int}()

    for page_config in config.pages
        idx = something(page_config.pageIndex, page_config.page, nothing)
        if idx !== nothing && !(idx in seen)
            push!(selected_pages, idx)
            push!(seen, idx)
        end
    end

    # Determine markdown file path
    final_md_path = md_path
    if final_md_path === nothing && config.appendFirstPage !== nothing
        yaml_dir = dirname(yaml_path)
        final_md_path = joinpath(yaml_dir, config.appendFirstPage)
    end

    # Extract pages using pdftk
    extract_pages_with_pdftk(input_pdf, output_pdf, selected_pages, final_md_path)

    println("Saved to: $output_pdf")
end

function parse_commandline()
    s = ArgParseSettings(
        description = "Extract selected pages from PDF and optionally prepend Markdown intro"
    )

    @add_arg_table! s begin
        "--yaml", "-y"
            help = "YAML file with page configuration"
            default = "../resources/config.yaml"
        "--input", "-i"
            help = "Input PDF file"
        "--output", "-o"
            help = "Output PDF file"
        "--markdown", "-m"
            help = "Markdown file to prepend"
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    # Load config for defaults
    yaml_path = args["yaml"]
    config = parse_config(yaml_path)

    # Get project root (parent of yaml directory)
    yaml_parent = dirname(dirname(yaml_path))

    # Determine input and output files with proper path resolution
    input_file = args["input"]
    if input_file === nothing && config.file !== nothing
        if isabspath(config.file)
            input_file = config.file
        else
            input_file = joinpath(yaml_parent, config.file)
        end
    end
    input_file = something(input_file, "")

    output_file = args["output"]
    if output_file === nothing && config.output !== nothing
        if isabspath(config.output)
            output_file = config.output
        else
            output_file = joinpath(yaml_parent, config.output)
        end

        # Add _julia suffix to filename
        if output_file !== nothing
            dir_part = dirname(output_file)
            file_part = basename(output_file)
            name_part = splitext(file_part)[1]
            output_file = joinpath(dir_part, "$(name_part)_julia.pdf")
        end
    end
    output_file = something(output_file, "")
    markdown_file = args["markdown"]

    # Check if input file exists
    if !isfile(input_file)
        println("Error: '$input_file' not found.")
        return
    end

    # Extract pages
    extract_pages(input_file, output_file, yaml_path, markdown_file)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
