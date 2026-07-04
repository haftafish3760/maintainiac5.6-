# Receipt Camera Cleanup Pass Log Archive - Pass 729

This archive preserves older cleanup entries so the active pass log stays under
the project line-count cap.

## Pass 729 - 03:15:57 EDT to active cleanup

Scope:
- Removed remaining active native service spec wording that listed
  focus/exposure/white-balance lock controls after the receipt camera moved to
  continuous autofocus/readability guidance.
- Removed dormant lock-tag builder lines from current Dart session config so a
  future flag flip cannot re-add `focus_lock`, `brightness_lock`, or
  `white_balance_lock` tags.
- Extended active-doc and session-contract regressions for retired lock-control
  wording and tags.
- Recorded `BUG-RECEIPT-0219` under `native_bridge`.
- Archived Pass 704 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused active-doc/session
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
