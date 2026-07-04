# Receipt Camera Cleanup Pass Log Archive - Pass 806

Archived from the active receipt camera cleanup log to keep the current log
under the project line cap.

## Pass 806 - 10:16:00 EDT to active cleanup

Scope:
- Treated native camera `review_required` health tokens as actionable
  attachment risk flags.
- Applied the same risk classification to shared capture-flow and
  attachment-panel native camera signal helpers.
- Added regressions proving focus/readability fallback review reaches receipt
  attachment risk flags and the duplicated helper paths stay aligned.
- Recorded `BUG-RECEIPT-0290` under `native_bridge`.
- Archived Pass 774 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native UI handoff
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
