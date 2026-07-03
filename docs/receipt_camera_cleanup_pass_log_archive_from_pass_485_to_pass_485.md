# Receipt Camera Cleanup Pass Log Archive - Pass 485

Archived from the live cleanup log to keep the active receipt camera pass log
under the project line-count cap.

## Pass 485 - 00:02:00 EDT to 00:06:00 EDT

Scope:
- Hardened privacy-safe section-order metadata for malformed native/recovery
  retake diagnostics.
- Added invalid retake order buckets when final section metadata is before the
  original section or when a preserved-slot retake claims it moved sections.
- Added regression coverage proving malformed retake diagnostics are counted in
  metadata and receipt-reader handoff counts without leaking file paths or
  receipt text.
- Recorded `BUG-RECEIPT-0004` under `multi_photo_ordering`.
- Archived Pass 464 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for section-order metadata,
  scanner/section-order tests, and the bug ledger gate.
- Passed focused Flutter test
  `test/receipt_camera_result_stitch_scanner_test.dart` with 5/5 tests
  passing.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
