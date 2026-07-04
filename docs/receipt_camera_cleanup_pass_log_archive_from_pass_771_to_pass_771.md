# Receipt Camera Cleanup Pass Log Archive - Pass 771

This archive preserves older cleanup passes moved out of
`receipt_camera_cleanup_pass_log.md` to keep the active log under the project
line cap.

## Pass 771 - 05:44:56 EDT to active cleanup

Scope:
- Hardened shared camera review-opening selection so the old-photo offset uses
  the same normalized initial receipt photo count as the review screen.
- Prevented invalid or duplicate existing photo paths from shifting selection
  away from the newly staged receipt section.
- Added a source regression tying review-opening index math to
  `uniqueNormalizedReceiptPhotoPaths`.
- Recorded `BUG-RECEIPT-0259` under `camera_review_state`.
- Archived Pass 743 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for review-opening offset changes.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
