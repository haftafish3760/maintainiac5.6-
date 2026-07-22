#!/usr/bin/env bash
set -euo pipefail

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/maintainiac_pdf_golden_gate.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

receipt_pdf="$work_dir/sample_receipt.pdf"
long_receipt_pdf="$work_dir/long_receipt.pdf"
invoice_pdf="$work_dir/sample_invoice.pdf"

dart run tool/generate_sample_receipt_pdf.dart "$receipt_pdf" >/dev/null
dart run tool/generate_long_receipt_pdf.dart "$long_receipt_pdf" >/dev/null
dart run tool/generate_sample_invoice_pdf.dart "$invoice_pdf" >/dev/null

expected_sample_receipt="cd6c1fd311b03dc37023c801f4dd66a4b7f1ee65146d65fbe38815e577f3e3f7"
expected_long_receipt="a2c66124b17781fcacf35e45004c2e2d7ecb8c0477d9d724580be8ca15a5dd60"
expected_sample_invoice="59705eaa4d975ebb0ac26c25747485ef974a1a2c348a651e70723f75e55c7e50"

actual_sample_receipt="$(shasum -a 256 "$receipt_pdf" | awk '{print $1}')"
actual_long_receipt="$(shasum -a 256 "$long_receipt_pdf" | awk '{print $1}')"
actual_sample_invoice="$(shasum -a 256 "$invoice_pdf" | awk '{print $1}')"

if [[ "$actual_sample_receipt" != "$expected_sample_receipt" ]]; then
  echo "Sample receipt PDF golden hash changed: $actual_sample_receipt" >&2
  exit 1
fi
if [[ "$actual_long_receipt" != "$expected_long_receipt" ]]; then
  echo "Long receipt PDF golden hash changed: $actual_long_receipt" >&2
  exit 1
fi
if [[ "$actual_sample_invoice" != "$expected_sample_invoice" ]]; then
  echo "Sample invoice PDF golden hash changed: $actual_sample_invoice" >&2
  exit 1
fi
