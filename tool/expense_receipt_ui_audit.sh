#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

scopes=(
  lib/screens/expenses
  lib/shared/widgets/receipt_capture
)

report="${TMPDIR:-/tmp}/maintainiac-expense-receipt-ui-audit.txt"
: >"$report"

record_matches() {
  local title="$1"
  local pattern="$2"
  shift 2
  {
    echo "$title"
    rg -n --glob '*.dart' "$pattern" "$@" || true
    echo
  } >>"$report"
}

oversized=0
while IFS= read -r file; do
  lines=$(wc -l <"$file" | tr -d ' ')
  if [ "$lines" -gt 500 ]; then
    printf 'OVER_500 %s %s\n' "$lines" "$file" >>"$report"
    oversized=$((oversized + 1))
  fi
done < <(rg --files "${scopes[@]}" | rg '\.dart$')

record_matches \
  'VISIBLE_TEXT_ELLIPSIS' \
  'TextOverflow\.ellipsis' \
  "${scopes[@]}"
record_matches \
  'VISIBLE_TEXT_FADE_OR_CLIP' \
  'TextOverflow\.(fade|clip)' \
  "${scopes[@]}"
record_matches \
  'USER_FACING_OCR_TERM_CANDIDATES' \
  "['\"][^'\"]*\\bOCR\\b[^'\"]*['\"]" \
  "${scopes[@]}"
record_matches \
  'SETTINGS_INFORMATION_WITHOUT_OBVIOUS_CONTROL' \
  '(settingSummary\(|SettingsPanel|SettingsSection|SettingsCard)' \
  "${scopes[@]}"
record_matches \
  'BORDER_LABEL_IMPLEMENTATIONS' \
  '(labelText:|InputDecoration\(|legend|border.*label|BorderLabel)' \
  "${scopes[@]}"

ellipsis_count=$(
  (rg -n --glob '*.dart' 'TextOverflow\.ellipsis' "${scopes[@]}" || true) |
    wc -l | tr -d ' '
)
ocr_copy_count=$(
  (rg -n --glob '*.dart' "['\"][^'\"]*\\bOCR\\b[^'\"]*['\"]" "${scopes[@]}" || true) |
    wc -l | tr -d ' '
)
settings_files=$(
  (rg -l --glob '*.dart' '(settingSummary\(|SettingsPanel|SettingsSection|SettingsCard)' "${scopes[@]}" || true) |
    wc -l | tr -d ' '
)

printf 'EXPENSE_RECEIPT_UI_AUDIT oversized=%s ellipsis=%s user_facing_ocr_candidates=%s settings_files=%s report=%s\n' \
  "$oversized" "$ellipsis_count" "$ocr_copy_count" "$settings_files" "$report"
