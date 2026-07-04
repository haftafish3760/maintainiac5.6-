# Receipt Camera Cleanup Pass Log Archive - Pass 813

Archived from the active cleanup log so the active pass log stays under the
project documentation line cap.

## Pass 813 - 12:27:00 EDT to active cleanup

Scope:
- Promoted dirty-lens/hazy saved-photo warnings into a first-class OCR source
  quality review family.
- Added `saved_hazy_lens_review` with `wipe_lens_or_retake` action and parser
  task-count mapping for admin/review diagnostics.
- Added a source handoff regression for dirty lens saved-photo review.
- Recorded `BUG-RECEIPT-0298` under `ocr_handoff_contract`.
- Archived Pass 781 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted handoff/diagnostics format/analyzer and focused dirty-lens
  source handoff regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
