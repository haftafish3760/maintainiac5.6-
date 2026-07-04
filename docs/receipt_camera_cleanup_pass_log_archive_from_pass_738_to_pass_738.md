# Receipt Camera Cleanup Pass Log Archive - Pass 738

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 738 - 03:33:00 EDT to active cleanup

Scope:
- Added a shared `ReceiptCaptureFlow.scanBarcodesFromReviewResult` handoff
  helper for expense, inventory, and maintenance consumers.
- Routed barcode scanning through OCR-source photos first, with saved proof
  fallback only when the review result already fell back.
- Added focused regressions for OCR-source preference and saved-proof fallback.
- Archived Pass 713 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for capture flow barcode handoff.
- Passed focused Flutter barcode handoff and barcode scanner regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
