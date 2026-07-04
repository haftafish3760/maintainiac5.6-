# Receipt Camera Cleanup Pass Log Archive - Pass 724

This file archives Pass 724 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 724 - 02:59:50 EDT to active cleanup

Scope:
- Hardened Android and iOS native diagnostics so retired tap focus is never
  reported as an expected control, even if a stale internal flag flips later.
- Added Android/iOS bridge regressions requiring
  `tapFocusControlExpected` to be hard-coded false instead of derived from
  `tapFocusEnabled`.
- Recorded `BUG-RECEIPT-0214` under `camera_capture_quality`.
- Archived Pass 698 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS native UI
  contract regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
