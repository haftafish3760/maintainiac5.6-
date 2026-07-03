# Receipt Camera Cleanup Pass Log Archive - Pass 518

Archived from the active cleanup pass log to keep the live working log under
the project line-count cap.

## Pass 518 - 01:31:00 EDT to 01:39:00 EDT

Scope:
- Hardened long-receipt add-photo ordering so continuation photos insert after
  the same selected section slot that launched the camera, not the first
  matching path after async return.
- Hardened remove-photo ordering so confirmed removals delete the original
  selected section slot and reject ambiguous duplicate or stale section paths.
- Added insert/remove order plan regressions for duplicate current paths and
  stale async anchors.
- Recorded `BUG-RECEIPT-0036` under `multi_photo_ordering`.
- Archived Pass 493 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for photo review ordering actions,
  retake/order plans, and focused ordering regression coverage.
- Passed full focused Flutter test `test/receipt_photo_review_retake_order_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.
