#!/usr/bin/env bash
set -euo pipefail

PDFINFO_BIN="${PDFINFO_BIN:-$(command -v pdfinfo || true)}"
PDFTOPPM_BIN="${PDFTOPPM_BIN:-$(command -v pdftoppm || true)}"

if [[ -z "$PDFINFO_BIN" && -x "$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/pdfinfo" ]]; then
  PDFINFO_BIN="$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/pdfinfo"
fi
if [[ -z "$PDFTOPPM_BIN" && -x "$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/pdftoppm" ]]; then
  PDFTOPPM_BIN="$HOME/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/pdftoppm"
fi
if [[ -z "$PDFINFO_BIN" || -z "$PDFTOPPM_BIN" ]]; then
  echo "Missing Poppler pdfinfo/pdftoppm for PDF render smoke gate." >&2
  exit 1
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/maintainiac_pdf_render_gate.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

fontconfig_dir="$work_dir/fontconfig"
fontconfig_cache_dir="$work_dir/fontconfig-cache"
mkdir -p "$fontconfig_dir" "$fontconfig_cache_dir"
cat > "$fontconfig_dir/fonts.conf" <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>/System/Library/Fonts</dir>
  <dir>/Library/Fonts</dir>
  <cachedir>$fontconfig_cache_dir</cachedir>
</fontconfig>
EOF
export FONTCONFIG_FILE="$fontconfig_dir/fonts.conf"
export FONTCONFIG_PATH="$fontconfig_dir"

receipt_pdf="$work_dir/sample_receipt.pdf"
invoice_pdf="$work_dir/sample_invoice.pdf"
real_invoice_pdf="$work_dir/real_invoice_renderer.pdf"

dart run tool/generate_sample_receipt_pdf.dart "$receipt_pdf" >/dev/null
dart run tool/generate_sample_invoice_pdf.dart "$invoice_pdf" >/dev/null
PDF_RENDER_GATE_INVOICE_OUTPUT="$real_invoice_pdf" \
  flutter test test/pdf_render_gate_invoice_generator_test.dart -r compact >/dev/null

for pdf in "$receipt_pdf" "$invoice_pdf" "$real_invoice_pdf"; do
  "$PDFINFO_BIN" "$pdf" >/dev/null
  prefix="$work_dir/$(basename "$pdf" .pdf)"
  "$PDFTOPPM_BIN" -singlefile -png -r 72 "$pdf" "$prefix" >/dev/null
  png="$prefix.png"
  if [[ ! -s "$png" ]]; then
    echo "Rendered PDF page is blank or missing for $pdf" >&2
    exit 1
  fi
  bytes="$(wc -c < "$png" | tr -d ' ')"
  if [[ "$bytes" -lt 1000 ]]; then
    echo "Rendered PDF page is suspiciously small for $pdf: $bytes bytes" >&2
    exit 1
  fi
  python3 tool/pdf_render_pixel_assertions.py "$png"
done
