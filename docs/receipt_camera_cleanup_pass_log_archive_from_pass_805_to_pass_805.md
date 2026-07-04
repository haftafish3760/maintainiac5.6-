# Receipt Camera Cleanup Pass Log Archive - Pass 805

Archived from the active receipt camera cleanup log to keep the current log
under the project line cap.

## Pass 805 - 10:05:51 EDT to active cleanup

Scope:
- Added an explicit native camera `focusReadabilityFallbackPolicy` so devices
  without continuous focus declare whether live or saved-photo readability
  review is required.
- Surfaced the policy through native session arguments, control diagnostics,
  and photo-review native UI health counts.
- Added regressions for session policy, service handoff, and review health
  aggregation.
- Recorded `BUG-RECEIPT-0289` under `native_bridge`.
- Archived Pass 773 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native camera regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
