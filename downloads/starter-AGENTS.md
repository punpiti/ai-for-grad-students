# AI for Research workspace

- Treat `content.md` as the editable source of truth.
- Put generated files in `output/`; do not replace the source unless asked.
- When the user asks for a PDF, run:

  ```text
  pandoc content.md --defaults templates/modern-thai.yaml -o output/content.pdf
  ```

- The PDF baseline is A4, XeLaTeX, and the exact font family `TH Sarabun New`.
- Keep the modern blue/teal template unless the user requests another design.
- Do not ask the learner to edit generated LaTeX.
- After building, confirm that `output/content.pdf` exists and is non-empty. Report the real build error if font discovery or PDF generation fails.
