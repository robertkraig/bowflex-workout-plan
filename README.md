# Workout Plan Exporter

This project allows you to export selected workout pages from a PDF and optionally prepend a Markdown file as an introduction using a simple Makefile and Poetry for dependency management.

## Setup

1. **Install dependencies with Poetry:**
   ```sh
   make install
   ```

## Usage

### 1. Prepare your files
- Place your input PDF (e.g., `BFX.Xceed.Global.OM.EN.pdf`) and optional Markdown file (e.g., `workout_plan.md`) in the `resources/` directory.
- Place your `workouts.yaml` in the project root directory (or update the Makefile if you want to move it).

### 2. Export the workout booklet

- To export the PDF with the workouts specified in `workouts.yaml`:
  ```sh
  make run
  ```
  This will create `Bowflex_Workout_Booklet.pdf` in the `output/` directory.

- To export with a Markdown intro at the front:
  ```sh
  make run-md
  ```
  This expects a file called `intro.md` in the `resources/` directory. You can change the file name by editing the Makefile or running the exporter manually.

- To remove the generated PDF:
  ```sh
  make clean
  ```

## Customization
- **Change workouts:** Edit `workouts.yaml` to add, remove, or reorder workout pages.
- **Change input/output files:** Edit the Makefile or run the exporter manually with custom arguments:
  ```sh
  poetry run python -m workout_exporter --input <your.pdf> --output <output.pdf> --yaml <your.yaml> --markdown <your.md>
  ```

## File Locations
- **PDF and Markdown files** should be placed in the `resources/` directory.
- **Output PDFs** will be written to the `output/` directory.
- **YAML file** (`workouts.yaml`) should be in the project root by default.

---

If you have any issues or want to further customize the workflow, see the code in `workout_exporter/__main__.py` or reach out for help!
