# Receipt Camera Cleanup Pass Log Archive - Pass 823

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 823 - 13:36:37 EDT to active cleanup

Scope:
- Exposed receipt review-depth handoff as typed OCR diagnostics fields:
  `ocrSourceReviewDepthSignalCounts` and `ocrSourceReviewDepthStatus`.
- Kept detailed-line versus price-only receipt review intent available to
  downstream UI, admin diagnostics, and telemetry without forcing callers to
  scrape the privacy-safe contract map.
- Added focused OCR service regression coverage for the typed review-depth
  diagnostics fields.
- Recorded `BUG-RECEIPT-0309` under `receipt_line_review_mode`.
- Archived Pass 784 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused OCR service regression.
- Passed doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and diff
  whitespace gates.
