#!/usr/bin/env bash
set -euo pipefail

# Read-only inventory for the generic receipt camera/OCR lane.
# Deliberately excludes domain parser implementation (fuel/materials/inventory).

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

echo "Receipt OCR audit"
echo "root=$root"
echo "branch=$(git branch --show-current)"
echo

declare -a roots=(
  lib/shared/receipts
  lib/shared/widgets/receipt_capture
  lib/screens/expenses/entry
  lib/screens/expenses/data/expense_receipt_ocr_review.dart
  lib/screens/expenses/data/expense_receipt_parser_ocr_handoff_logic.dart
  android/app/src/main/kotlin/com/maintainiac/ReceiptCamera
  ios/Runner/ReceiptCamera
  test/receipt_camera
  test/receipt_ocr
  test/receipt_capture
)

files=()
for pattern in "${roots[@]}"; do
  if [[ -d "$pattern" ]]; then
    while IFS= read -r file; do files+=("$file"); done < <(rg --files "$pattern")
  elif [[ -f "$pattern" ]]; then
    files+=("$pattern")
  else
    while IFS= read -r file; do files+=("$file"); done < <(rg --files | rg "^${pattern}")
  fi
done

filtered_files=()
while IFS= read -r file; do
  [[ -n "$file" ]] && filtered_files+=("$file")
done < <(
  printf '%s\n' "${files[@]}" |
    sort -u |
    rg -v '(^|/)(fuel|work_supply|materials|inventory)' || true
)
files=("${filtered_files[@]}")

echo "[file-size] generic OCR/camera files over 500 lines"
found=0
for file in "${files[@]}"; do
  [[ -f "$file" ]] || continue
  lines=$(wc -l < "$file" | tr -d ' ')
  if (( lines > 500 )); then
    printf '%4s %s\n' "$lines" "$file"
    found=1
  fi
done
(( found == 0 )) && echo "none"
echo

echo "[architecture] key symbols and boundaries"
rg -n --no-heading \
  'class ReceiptOcrService|class ReceiptOcrDocument|class ReceiptOcrResult|class ReceiptOcrHandoff|ReceiptOcrHandoffDestination|selectedCategory|inventoryRequested|recognizeTextFromAttachments|TextRecognizer|ocrSource|parserText|appFillText|captureReceipt' \
  lib/shared/receipts lib/shared/widgets/receipt_capture lib/screens/expenses/entry lib/screens/expenses/data/expense_receipt_ocr_review.dart lib/screens/expenses/data/expense_receipt_parser_ocr_handoff_logic.dart \
  android/app/src/main/kotlin/com/maintainiac/ReceiptCamera ios/Runner/ReceiptCamera 2>/dev/null || true
echo

echo "[coverage] focused OCR/camera tests"
rg --files test | rg -i '(receipt.*(ocr|camera|capture)|ocr.*receipt)' | rg -v '(fuel|work_supply|materials|inventory)' | sort
echo

echo "[wiring] category-to-handoff references"
rg -n --no-heading 'initialCategory|selectedCategory|receiptOcrHandoffDestinationFor|ReceiptOcrHandoff\.forUserSelection|handoffRouter\.dispatch' \
  lib/screens/expenses lib/shared/receipts lib/shared/widgets/receipt_capture 2>/dev/null | rg -v '(fuel|work_supply|materials|inventory)' || true
echo

echo "[docs] current OCR/camera standards"
for file in docs/receipt_camera_ocr_product_standard.md docs/receipt_camera_release_one_blueprint.md docs/receipt_camera_completion_map.md docs/receipt_native_camera_service_spec.md; do
  [[ -f "$file" ]] && printf '%s %s lines\n' "$file" "$(wc -l < "$file" | tr -d ' ')"
done
