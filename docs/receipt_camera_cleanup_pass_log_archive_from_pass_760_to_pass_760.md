# Receipt Camera Cleanup Pass Log Archive - Pass 760

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line cap while preserving pass history.

## Pass 760 - 04:26:36 EDT to active cleanup

Scope:
- Hardened Android and iOS saved-photo vertical quality scoring so non-finite
  band luma or edge samples cannot appear as even vertical quality or bottom
  blur evidence.
- Kept malformed vertical-quality samples on the existing `unknown` path.
- Added Android/iOS native vertical-quality source regressions for finite sample
  checks.
- Recorded `BUG-RECEIPT-0248` under `camera_capture_quality`.
- Archived Pass 732 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for vertical-quality regressions.
- Passed focused Android close-controls and iOS long-receipt quality tests.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
