# Receipt Camera Cleanup Pass Log Archive - Pass 358

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line rule.

## Pass 358 - 11:40:18 EDT to 11:42:12 EDT

Scope:
- Split duplicate receipt-attachment candidate scanning out of
  `expense_ledger_store.dart` into
  `expense_ledger_attachment_duplicates.dart`.
- Kept the public call as `ledger.duplicateAttachmentCandidatesFor(...)` via a
  same-library controller extension.
- Reduced `expense_ledger_store.dart` from 358 lines to 293 lines; the new
  attachment duplicate helper is 69 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused duplicate detection,
  ledger store, and receipt metadata tests, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
