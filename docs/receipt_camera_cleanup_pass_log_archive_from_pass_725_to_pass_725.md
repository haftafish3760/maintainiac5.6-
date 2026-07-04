# Receipt Camera Cleanup Pass Log Archive - Pass 725

This archive preserves older cleanup entries so the active pass log stays under
the project line-count cap.

## Pass 725 - 03:01:36 EDT to active cleanup

Scope:
- Fixed Android and iOS native control readiness summaries so retired tap-focus
  and manual focus-lock controls do not make the active receipt camera look
  unhealthy.
- Kept explicit retired-control diagnostics available while limiting readiness
  summary evaluation to active controls such as back, settings, shutter, pinch
  zoom, brightness, reset, and torch.
- Added Android/iOS bridge regressions that inspect the readiness-summary body
  and reject retired tap/manual-lock controls inside it.
- Recorded `BUG-RECEIPT-0215` under `camera_capture_quality`.
- Archived Pass 699 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS native UI
  contract regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
