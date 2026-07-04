# Receipt Camera Cleanup Pass Log Archive - Pass 727

This archive preserves older cleanup entries so the active pass log stays under
the project line-count cap.

## Pass 727 - 03:07:12 EDT to active cleanup

Scope:
- Pinned Android, iOS, and Dart bridge diagnostics so retired focus/exposure/
  white-balance lock controls are never reported as expected receipt-camera
  controls.
- Kept legacy lock setting fields available separately for compatibility while
  preventing them from driving expected-control health.
- Updated staging/channel fixtures and Android/iOS bridge regressions for the
  retired lock-control expected values.
- Recorded `BUG-RECEIPT-0217` under `native_bridge`.
- Archived Pass 701 from the active cleanup log to keep the doc under cap.

Verification:
- First focused run included a non-existent staging manifest test path and
  exposed a stale retired-lock health expectation; fixed the expectation and
  reran with the correct staging test.
- Focused staging rerun exposed stale manifest helper assertions for retired
  lock expected controls; fixed before continuing.
- Tests-only source audit initially hit a Dart native-assets codesign race while
  another audit was running; reran it alone and it passed.
- Passed targeted Dart format/analyzer and focused native bridge/staging
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
