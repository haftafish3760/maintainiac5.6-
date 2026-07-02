#!/usr/bin/env bash
set -euo pipefail

max_lines=500
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

find \
  lib/shared/widgets/receipt_capture \
  lib/shared/receipts \
  lib/screens/expenses/data \
  lib/screens/expenses/entry \
  -type f \
  -name '*.dart' \
  -not -path '*/build/*' \
  -print > "$tmp"

failed=0
checked=0
while IFS= read -r file; do
  checked=$((checked + 1))
  line_count=$(dart format --output=show "$file" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$line_count" -gt "$max_lines" ]]; then
    printf '%5s formatted lines  %s\n' "$line_count" "$file" >&2
    failed=1
  fi
done < "$tmp"

if [[ "$failed" -ne 0 ]]; then
  printf 'Receipt formatter projection gate failed: maxLines=%s\n' "$max_lines" >&2
  exit 1
fi

printf 'Receipt formatter projection gate: files=%s maxLines=%s\n' "$checked" "$max_lines"
