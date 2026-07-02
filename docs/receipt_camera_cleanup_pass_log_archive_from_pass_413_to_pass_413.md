# Receipt Camera Cleanup Pass Log Archive - Pass 413

This archive keeps older receipt camera cleanup passes out of the active log so
each log file stays under the 500-line rule.

## Pass 413 - 13:21:00 EDT to 13:24:19 EDT

Scope:
- Stayed on one topic: long-receipt retake/order behavior.
- Added `ReceiptPhotoRetakeOrderPlan` as a pure retake-order helper so retaking
  section N keeps the same section slot and inserts any extra retake photos
  immediately after that slot.
- Wired `retakeCurrentReceiptPhoto` through the helper without changing the
  native camera or backup camera capture flow.
- Added regression coverage for middle-section replacement, multi-photo retake
  insertion, and the async edge case where the original target photo disappears.

Failures fixed during this pass:
- First targeted analyzer/test run failed because the new test imported
  `package:maintainiac/...` instead of the repo package name
  `package:maintaniac/...`. Corrected the import and reran the failed checks
  green.

Verification:
- Passed targeted `dart analyze` for the touched retake/order files and test.
- Passed `flutter test test/receipt_photo_review_retake_order_test.dart
  -r compact`.
- Passed focused `flutter test test/receipt_photo_section_labels_test.dart
  test/receipt_photo_review_retake_order_test.dart -r compact`.
- Passed receipt source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  targeted `git diff --check`.
