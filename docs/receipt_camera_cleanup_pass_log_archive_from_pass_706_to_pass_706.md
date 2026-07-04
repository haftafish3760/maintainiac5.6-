# Receipt Camera Cleanup Pass Log Archive - Pass 706

This file archives Pass 706 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 706 - 02:31:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native session argument readers so stale or malformed
  bridge arguments cannot re-enable tap-focus for receipt capture.
- Forced the native tap-focus policy to
  `continuous_focus_primary_no_tap_focus` at both platform boundaries.
- Updated Android and iOS bridge regressions to reject raw tap-focus argument
  trust.
- Recorded `BUG-RECEIPT-0193` under `native_bridge`.
- Archived Pass 647 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native bridge tests.
- Passed focused Android/iOS bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 648 from the active cleanup log to keep the doc under cap.
