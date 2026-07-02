# Receipt Camera Cleanup Pass Log Archive - Pass 140

This archive preserves older receipt camera cleanup pass evidence moved out of
the active log to keep every pass-log file under the 500-line rule.

## Pass 140 - 05:41:08 EDT to 05:44:58 EDT

Scope:
- Tightened long-receipt stitching image reads so missing, empty, corrupt, and
  wrong-file-type photo paths explicitly fall back as `decode_failed`.
- Reused the shared receipt image safe file-read and decode helpers instead of
  letting stitch input failures depend on the broad `stitch_exception` catch.
- Added a stitching regression test covering the unreadable-photo family with a
  valid first receipt section plus each bad second image case.

Verification:
- Focused stitching verification passed:
  `dart analyze` over `receipt_image_processor.dart` and
  `test/receipt_stitching_test.dart`,
  `flutter test test/receipt_stitching_test.dart -r compact`,
  `dart run tool/maintainiac_source_audit.dart --include-tests` for the stitch
  API/test files, and `git diff --check` for those files.
- `test/receipt_stitching_test.dart` passed all 15 tests, including the new
  unreadable-photo family regression.
- Touched files remain under 500 lines:
  `receipt_image_processor_stitch_api.dart` 172 lines and
  `receipt_stitching_test.dart` 461 lines.

Known follow-up:
- Photo-review manual crop/rotate still has a UI-layer raw decode path that
  should get the same missing/empty/corrupt/wrong-type treatment in a later
  pass.
