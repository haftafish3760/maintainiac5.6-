# Receipt Camera Cleanup Pass Log Archive - Pass 364

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active cleanup
log under the 500-line file-size guard.

## Pass 364 - 11:51:34 EDT to 11:53:43 EDT

Scope:
- Split computed receipt record totals, labels, primary proof hash/category, and
  sort date out of `expense_receipt_record.dart` into
  `expense_receipt_record_computed_fields.dart`.
- Kept record construction, stored fields, map parsing, and `copyWith` in the
  original receipt record part.
- Reduced `expense_receipt_record.dart` from 344 lines to 253 lines; the new
  computed-fields extension is 95 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused ledger store, ledger
  totals, receipt line record, and draft store tests, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
