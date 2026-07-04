# Receipt Camera Cleanup Pass Log Archive - Pass 709

This file archives Pass 709 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 709 - 02:21:00 EDT to active cleanup

Scope:
- Removed stale Android native settings copy that still told users to use focus
  assist after the receipt camera moved to continuous-autofocus/readability
  guidance.
- Added focused Android bridge source regression coverage so retired focus
  assist copy cannot return through settings/help text.
- Recorded `BUG-RECEIPT-0197` under `camera_capture_quality`.
- Archived Pass 651 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the Android settings bridge test.
- Passed focused Android settings bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
