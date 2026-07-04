# Receipt Camera Cleanup Pass Log Archive - Pass 730

This archive preserves older cleanup entries so the active pass log stays under
the project line-count cap.

## Pass 730 - 03:17:54 EDT to active cleanup

Scope:
- Removed retired lock controls from native capability policy scoring so
  capable devices can still report full camera assist.
- Kept lock enablement false, but stopped treating retired locks as a degraded
  capability or noisy policy code.
- Removed retired tap-focus controls from capability policy scoring after the
  focused test caught capable devices losing their full-assist policy code.
- Added session/channel regressions proving retired-lock policy noise stays out
  while full camera assist remains possible.
- Recorded `BUG-RECEIPT-0220` and `BUG-RECEIPT-0221` under `native_bridge`.
- Archived Pass 705 from the active cleanup log to keep the doc under cap.

Verification:
- Focused test caught `BUG-RECEIPT-0221`; fix added before continuing.
- Passed targeted Dart format/analyzer for native camera capability policy,
  session settings, channel expectations, and focused contract tests.
- Passed focused Flutter native session, settings-contract, and channel
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
