# Receipt Camera Cleanup Pass Log Archive - Pass 721

This file archives Pass 721 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 721 - 02:47:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native capture callbacks so an over-budget receipt
  photo is deleted and rejected before it is appended to captured sections.
- Preserved existing captured sections when a close-after-capture path fails due
  to the byte budget.
- Added Android/iOS bridge source regressions for native over-budget cleanup and
  `native_capture_over_byte_budget` status.
- Recorded `BUG-RECEIPT-0209` under `source_preservation`.
- Fixed stale Android auto-capture QA assertions that still expected raw
  readability-signal equality checks instead of the named readability-review
  policy set.
- Recorded `BUG-RECEIPT-0210` under `qa_harness`.
- Archived Pass 694 from the active cleanup log to keep the doc under cap.

Verification:
- First focused bridge run failed because the Android auto-capture test still
  expected raw `latestReadabilitySignal == ...` checks; fixed the test to
  require the helper/set policy and reject direct equality checks.
- Passed targeted Dart format/analyzer for Android/iOS bridge regressions.
- Passed focused Android/iOS native bridge regressions.
