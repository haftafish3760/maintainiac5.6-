# Receipt Camera Cleanup Pass Log Archive - Pass 341

## Pass 341 - 11:13:30 EDT to 11:15:27 EDT

Scope:
- Split assisted receipt review detail-text routing out of
  `expense_receipt_parse_review_guidance.dart` into
  `expense_receipt_parse_review_guidance_detail_text.dart`.
- Kept OCR/parser signal collection, labels, icons, colors, and guidance object
  assembly in the existing guidance model.
- Reduced `expense_receipt_parse_review_guidance.dart` from 405 lines to 363
  lines; the new detail-text helper is 95 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused assisted-review
  parser guidance tests, source audit, `bash tool/receipt_fast_guard_gate.sh`,
  and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
