# Receipt Camera Cleanup Pass Log Archive - Pass 764

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 764 - 04:52:58 EDT to active cleanup

Scope:
- Hardened the Dart native camera session boundary so previous-section ghost
  guide paths must be local absolute image-like paths before native handoff.
- Rejected relative paths, URLs, `file://` URIs, non-image files, and NUL-tainted
  guide paths before the app marks a long-receipt guide as active.
- Kept previous-section reason, guidance, and ghost fractions disabled whenever
  the guide photo path itself is invalid.
- Added Dart session regressions for unsafe guide path families.
- Recorded `BUG-RECEIPT-0252` under `multi_photo_ordering`.
- Archived Pass 736 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for session boundary changes.
- Passed focused Flutter native camera session limit regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
