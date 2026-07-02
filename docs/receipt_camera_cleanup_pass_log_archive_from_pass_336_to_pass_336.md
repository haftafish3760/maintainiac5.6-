# Receipt Camera Cleanup Pass Log Archive - Pass 336

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the 500-line source guard.

## Pass 336 - 11:03:20 EDT to 11:05:27 EDT

Scope:
- Split `ExpenseReceiptParseResult` out of
  `expense_receipt_parse_models.dart` into `expense_receipt_parse_result.dart`.
- Kept `ExpenseReceiptParseDiagnostics` and related OCR/parser diagnostic model
  fields in the original parse models part.
- Reduced `expense_receipt_parse_models.dart` from 392 lines to 235 lines; the
  new parse result part is 158 lines.

Failures fixed during this pass:
- First fast guard rerun failed because concurrent log entries pushed
  `receipt_camera_cleanup_pass_log.md` to 505 lines. Archived Pass 310 and
  reran the same guard green.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused receipt parser,
  allocation, parser failure diagnostics, and receipt processing contract tests.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff
  --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
