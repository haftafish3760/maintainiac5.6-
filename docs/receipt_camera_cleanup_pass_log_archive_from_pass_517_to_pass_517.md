# Receipt Camera Cleanup Pass Log Archive - Pass 517

Archived from the active cleanup pass log to keep the live working log under
the project line-count cap.

## Pass 517 - 01:17:01 EDT to 01:17:58 EDT

Scope:
- Hardened receipt section retake ordering so duplicate or unnormalized current
  section paths cannot make `indexOf` retake the wrong receipt slot.
- Added retake-order regression coverage proving ambiguous current section
  paths are rejected before replacement.
- Recorded `BUG-RECEIPT-0035` under `multi_photo_ordering`.
- Archived Pass 480 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial targeted analyzer failure by moving the current-path
  uniqueness helper where both retake builders can use it.
- Passed targeted Dart format and analyzer for retake ordering and focused
  retake-order regression coverage.
- Passed focused Flutter test
  `test/receipt_photo_review_retake_order_test.dart --plain-name "retake plan
  rejects duplicate current section paths"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
