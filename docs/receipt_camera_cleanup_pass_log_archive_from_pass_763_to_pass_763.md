# Receipt Camera Cleanup Pass Log Archive - Pass 763

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 763 - 04:52:58 EDT to active cleanup

Scope:
- Hardened Android and iOS previous-section guide loaders so the long-receipt
  ghost overlay only accepts trimmed local absolute image paths.
- Removed Android's non-image `setImageURI` fallback so existing non-image
  files cannot appear as continuation guides.
- Added Android/iOS source regressions for local image guide enforcement.
- Recorded `BUG-RECEIPT-0251` under `multi_photo_ordering`.
- Archived Pass 735 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for previous-section guide regressions.
- Passed focused Android settings-quality and iOS long-receipt quality tests.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
