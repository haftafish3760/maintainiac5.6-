# Receipt Camera Cleanup Pass Log Archive - Pass 728

This archive preserves older cleanup entries so the active pass log stays under
the project line-count cap.

## Pass 728 - 03:11:18 EDT to active cleanup

Scope:
- Retired Dart-side focus/exposure/white-balance lock enablement so current
  receipt camera sessions no longer advertise lock controls or lock tags.
- Removed lock-control descriptors from the current receipt camera settings
  list, keeping continuous focus/readability guidance as the product path.
- Replaced lock-unavailable capability policy noise with a retired-lock policy
  code and updated channel/staging/native UI fixtures.
- Recorded `BUG-RECEIPT-0218` under `native_bridge`.
- Archived Pass 703 from the active cleanup log to keep the doc under cap.

Verification:
- First focused batch exposed stale previous-section capability-policy and
  native UI tag-count expectations; fixed before continuing.
- Passed targeted Dart format/analyzer and focused native contract/channel/
  staging/UI regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
