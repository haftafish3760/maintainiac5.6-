# Receipt Camera Cleanup Pass Log Archive - Pass 499

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 499 - 01:33:00 EDT to 01:38:00 EDT

Scope:
- Hardened long-receipt manual overlap stitching so non-finite overlap fractions
  cannot escape the safe manual-overlap fallback path.
- Added regression coverage proving non-finite manual overlap uses
  `manual_overlap_unsafe` and preserves ordered OCR source paths.
- Recorded `BUG-RECEIPT-0018` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format and analyzer for stitch helpers and focused manual
  overlap regression coverage.
- Passed focused Flutter test
  `test/receipt_stitching_manual_overlap_test.dart --plain-name "manual overlap
  fraction rejects non-finite values safely"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
