# Receipt Camera Cleanup Pass Log Archive - Pass 774 to Pass 774

This archive keeps older completed cleanup entries available while the active
cleanup log stays under the project line cap.

## Pass 774 - 05:58:15 EDT to active cleanup

Scope:
- Updated the long-receipt guidance source regression after the review screen
  moved from raw initial photo counts to normalized initial photo counts.
- Required the test to prove `_initialReviewMode` is driven by
  `_initialPhotoPaths.length` and that initial paths are normalized once.
- Recorded `BUG-RECEIPT-0262` under `qa_harness`.
- Archived Pass 746 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for long-receipt guidance regression.
- Passed focused Flutter long-receipt guidance regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
