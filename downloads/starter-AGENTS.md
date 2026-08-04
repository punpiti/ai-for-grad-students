# AI for Research workspace

- Treat `content.md` as the editable source of truth.
- Put generated files in `output/`; do not replace the source unless asked.
- Keep untouched source documents in `input/original/` and derived Markdown in `input/markdown/`.
- Before analyzing documents, run `tools/import-documents.ps1` on Windows or `tools/import-documents.sh` on macOS/Linux when Markdown copies are missing.
- OCR uses Thai and English. Treat OCR text as a draft: preserve the source filename and identify passages that need comparison with the original.
- Never delete or overwrite files in `input/original/`.
- When the user asks for a PDF, run:

  ```text
  pandoc content.md --defaults templates/modern-thai.yaml -o output/content.pdf
  ```

- Run that exact `pandoc` build once; do not split it into repeated exploratory shell commands.
- If the IDE asks for command permission, ask the learner to always allow the exact `pandoc` executable for this trusted course workspace. Never ask for broad permission to run every shell command.
- The PDF baseline is A4, XeLaTeX, and the bundled `TH Sarabun New` files under `templates/fonts/`; do not depend on system font discovery.
- Keep the modern blue/teal template unless the user requests another design.
- Do not ask the learner to edit generated LaTeX.
- After building, use the IDE file explorer to confirm that `output/content.pdf` exists and is non-empty. Do not run extra terminal commands merely to restate what the tool output and file explorer already show. Report the real build error if PDF generation fails.
