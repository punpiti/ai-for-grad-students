#!/usr/bin/env bash
set -euo pipefail

workspace="${1:-$(pwd)}"
source_dir="$workspace/input/original"
target_dir="$workspace/input/markdown"
mkdir -p "$source_dir" "$target_dir"

have() { command -v "$1" >/dev/null 2>&1; }
have pandoc || { echo 'Missing pandoc.' >&2; exit 2; }
have tesseract || { echo 'Missing tesseract.' >&2; exit 2; }
have pdftotext || { echo 'Missing pdftotext (Poppler).' >&2; exit 2; }
have pdftoppm || { echo 'Missing pdftoppm (Poppler).' >&2; exit 2; }

languages="$(tesseract --list-langs 2>/dev/null || true)"
[[ "$languages" == *tha* && "$languages" == *eng* ]] || {
  echo 'Tesseract Thai and English language data are required.' >&2
  exit 2
}

count=0
while IFS= read -r -d '' source; do
  filename="$(basename "$source")"
  stem="${filename%.*}"
  extension="${filename##*.}"
  extension="$(printf '%s' "$extension" | tr '[:upper:]' '[:lower:]')"
  target="$target_dir/$filename.md"
  temporary="$(mktemp -d)"
  trap 'rm -rf "$temporary"' EXIT
  extracted="$temporary/extracted.txt"

  case "$extension" in
    md|txt)
      cp "$source" "$extracted"
      ;;
    docx|odt|rtf|html|htm)
      pandoc "$source" -t gfm -o "$extracted"
      ;;
    pdf)
      pdftotext -layout "$source" "$extracted" 2>/dev/null || true
      if ! grep -q '[^[:space:]]' "$extracted" 2>/dev/null; then
        : > "$extracted"
        pdftoppm -png -r 300 "$source" "$temporary/page" >/dev/null 2>&1
        while IFS= read -r -d '' page; do
          tesseract "$page" stdout -l tha+eng 2>/dev/null >> "$extracted"
          printf '\n\n' >> "$extracted"
        done < <(find "$temporary" -name 'page-*.png' -print0)
      fi
      ;;
    png|jpg|jpeg|tif|tiff|bmp|webp)
      tesseract "$source" stdout -l tha+eng 2>/dev/null > "$extracted"
      ;;
    *)
      echo "SKIP unsupported: $filename"
      rm -rf "$temporary"
      trap - EXIT
      continue
      ;;
  esac

  {
    printf '# %s\n\n' "$stem"
    printf '> Source: `%s`  \n' "$filename"
    printf '> Imported automatically. Compare important claims with the original file.\n\n'
    cat "$extracted"
    printf '\n'
  } > "$target"
  echo "CREATED ${target#"$workspace/"}"
  count=$((count + 1))
  rm -rf "$temporary"
  trap - EXIT
done < <(find "$source_dir" -maxdepth 1 -type f -print0)

echo "IMPORT_RESULT files=$count output=input/markdown"
