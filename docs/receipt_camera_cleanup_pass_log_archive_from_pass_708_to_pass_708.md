# Receipt Camera Cleanup Pass Log Archive - Pass 708

This file archives Pass 708 from `docs/receipt_camera_cleanup_pass_log.md` to
keep the active cleanup log under the 500-line limit enforced by
`tool/receipt_cleanup_log_gate.sh`.

## Pass 708 - 02:45:00 EDT to active cleanup

Scope:
- Removed stale iOS native settings copy that still told users to use focus
  assist after the receipt camera moved to continuous-autofocus/readability
  guidance.
- Added focused iOS bridge source regression coverage so the retired focus
  assist copy cannot return through settings/help text.
- Fixed stale iOS bridge QA assertions that still expected direct raw
  readability-signal equality checks instead of the named readability-review
  policy set.
- Recorded `BUG-RECEIPT-0195` under `camera_capture_quality`.
- Recorded `BUG-RECEIPT-0196` under `qa_harness`.
- Archived Pass 650 from the active cleanup log to keep the doc under cap.

Verification:
- First focused iOS settings bridge regression failed because the test still
  expected raw `latestReadabilitySignal == ...` checks; fixed the regression to
  require the helper/set policy and reject direct equality checks.
- Passed targeted Dart format/analyzer for the iOS settings bridge test.
- Passed focused iOS settings bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
