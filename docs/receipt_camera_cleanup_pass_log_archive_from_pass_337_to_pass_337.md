# Receipt Camera Cleanup Pass Log Archive - Pass 337

## Pass 337 - 11:06:00 EDT to 11:07:36 EDT

Scope:
- Split expense receipt line record serialization out of
  `expense_line_record.dart` into `expense_line_record_serialization.dart`.
- Kept receipt proof labels, client-proof visibility, OCR source labels,
  allocation math, parser-review labels, and storage parsing in the main record
  file.
- Reduced `expense_line_record.dart` from 392 lines to 355 lines; the new
  serialization part is 42 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused receipt line record,
  ledger store, and ledger totals tests.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff
  --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
