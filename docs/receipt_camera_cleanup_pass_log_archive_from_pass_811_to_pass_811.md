# Receipt Camera Cleanup Pass Log Archive - Pass 811

Archived from the active cleanup log so the active pass log stays under the
project documentation line cap.

## Pass 811 - 12:14:00 EDT to active cleanup

Scope:
- Hardened derived OCR diagnostics so generic saved photo quality warning tokens
  also feed dark/glare/blur parser task-count review buckets.
- Added focused service coverage proving a too-dark saved receipt surfaces
  `photo_saved_dark_or_exposure_review` for admin/parser diagnostics.
- Recorded `BUG-RECEIPT-0296` under `ocr_handoff_contract`.
- Archived Pass 779 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted OCR diagnostics format/analyzer and focused service
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
