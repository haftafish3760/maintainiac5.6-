# Receipt Camera Cleanup Pass Log Archive - Pass 868

Times are local to the development machine.

## Pass 868 - 16:04:00 EDT to active cleanup

Scope:
- Classified native camera `lastFocusStatus` diagnostics into health counts for
  configured, unavailable, not-requested, configuration-failed, and stale
  not-used focus states.
- Promoted focus configuration failure and stale `not_used` diagnostics into
  native UI health outcomes so review/admin surfaces cannot silently treat them
  as ready.
- Routed focus configuration failure and stale `not_used` outcomes into
  attachment risk flags for OCR/review handoff.
- Recorded `BUG-RECEIPT-0318` under `native_bridge`.
- Archived Pass 823 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native UI health/ready
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
