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
long_receipt_pdf="$work_dir/long_receipt.pdf"
invoice_pdf="$work_dir/sample_invoice.pdf"
real_invoice_pdf="$work_dir/real_invoice_renderer.pdf"
long_text_invoice_pdf="$work_dir/long_text_invoice_renderer.pdf"
landscape_invoice_pdf="$work_dir/landscape_invoice_renderer.pdf"

dart run tool/generate_sample_receipt_pdf.dart "$receipt_pdf" >/dev/null
dart run tool/generate_long_receipt_pdf.dart "$long_receipt_pdf" >/dev/null
dart run tool/generate_sample_invoice_pdf.dart "$invoice_pdf" >/dev/null
PDF_RENDER_GATE_INVOICE_OUTPUT="$real_invoice_pdf" \
PDF_RENDER_GATE_LONG_TEXT_INVOICE_OUTPUT="$long_text_invoice_pdf" \
PDF_RENDER_GATE_LANDSCAPE_INVOICE_OUTPUT="$landscape_invoice_pdf" \
  flutter test test/pdf_render_gate_invoice_generator_test.dart -r compact >/dev/null

for pdf in "$receipt_pdf" "$long_receipt_pdf" "$invoice_pdf" "$real_invoice_pdf" "$long_text_invoice_pdf" "$landscape_invoice_pdf"; do
  info="$("$PDFINFO_BIN" "$pdf")"
  page_count="$(printf '%s\n' "$info" | awk '/^Pages:/ {print $2}')"
  if [[ -z "$page_count" || "$page_count" -lt 1 ]]; then
    echo "Could not determine a positive page count for $pdf" >&2
    exit 1
  fi
  if [[ "$pdf" == "$real_invoice_pdf" && "$page_count" -lt 2 ]]; then
    echo "Real invoice render fixture must exercise multiple pages." >&2
    exit 1
  fi
  if [[ "$pdf" == "$long_receipt_pdf" && "$page_count" -lt 5 ]]; then
    echo "Long receipt render fixture must exercise repeated receipt sections." >&2
    exit 1
  fi
  if [[ "$pdf" == "$long_text_invoice_pdf" && "$page_count" -lt 2 ]]; then
    echo "Long-text invoice render fixture must exercise multiple pages." >&2
    exit 1
  fi
  if [[ "$pdf" == "$landscape_invoice_pdf" && "$page_count" -lt 1 ]]; then
    echo "Landscape invoice render fixture must exercise at least one page." >&2
    exit 1
  fi
  prefix="$work_dir/$(basename "$pdf" .pdf)"
  "$PDFTOPPM_BIN" -png -r 72 "$pdf" "$prefix" >/dev/null
  rendered_count="$(find "$work_dir" -maxdepth 1 -name "$(basename "$prefix")-*.png" | wc -l | tr -d ' ')"
  if [[ "$rendered_count" -ne "$page_count" ]]; then
    echo "Rendered page count mismatch for $pdf: expected $page_count, got $rendered_count" >&2
    exit 1
  fi
  for page_number in $(seq 1 "$page_count"); do
    png="${prefix}-${page_number}.png"
    if [[ ! -s "$png" ]]; then
      png="${prefix}-$(printf "%02d" "$page_number").png"
    fi
    if [[ ! -s "$png" ]]; then
      png="${prefix}-$(printf "%03d" "$page_number").png"
    fi
    if [[ ! -s "$png" ]]; then
      echo "Rendered PDF page is blank or missing for $pdf page $page_number" >&2
      exit 1
    fi
    bytes="$(wc -c < "$png" | tr -d ' ')"
    if [[ "$bytes" -lt 1000 ]]; then
      echo "Rendered PDF page is suspiciously small for $pdf page $page_number: $bytes bytes" >&2
      exit 1
    fi
    orientation="portrait"
    min_width=500
    min_height=650
    if [[ "$pdf" == "$landscape_invoice_pdf" ]]; then
      orientation="landscape"
      min_width=650
      min_height=500
    fi
    python3 tool/pdf_render_pixel_assertions.py \
      "$png" \
      --orientation "$orientation" \
      --min-width "$min_width" \
      --min-height "$min_height"
  done
done
