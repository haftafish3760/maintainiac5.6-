# Receipt Camera Cleanup Pass Log Archive - Pass 731

This archive preserves older cleanup entries so the active pass log stays under
the project line-count cap.

## Pass 731 - 03:22:11 EDT to active cleanup

Scope:
- Audited remaining tap-focus references after removing retired controls from
  capability policy scoring.
- Hard-coded the Dart service contract payload so `tapFocusControlExpected`
  stays false instead of deriving from `config.tapFocusEnabled`.
- Added a service source-contract regression proving the retired tap-focus
  expected flag cannot be reconnected through the service helper.
- Recorded `BUG-RECEIPT-0222` under `native_bridge`.
- Archived Pass 706 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
