# Receipt Camera Cleanup Pass Log Archive - Pass 142

This archive preserves older receipt camera cleanup pass evidence moved out of
the active log to keep every pass-log file under the 500-line rule.

## Pass 142 - 05:50:23 EDT to 05:53:38 EDT

Scope:
- Hardened `ReceiptImageProcessor.rotateFile` so missing source files use the
  shared safe file-read helper before image decode.
- Kept rotate failure behavior stable by reporting unreadable rotate inputs as
  `StateError('Image could not be decoded.')` for missing, empty, corrupt, and
  wrong-file-type sources.
- Added a rotate-source regression test covering the unreadable source family.

Failures fixed during this pass:
- The first focused verification failed analyzer because the safe read helper
  returns nullable bytes; `rotateFile` now treats null bytes as an unreadable
  image before retrying the focused gate.

Verification:
- Focused rotate guard verification passed:
  `dart format`, `dart analyze`, `flutter test
  test/receipt_image_data_saver_test.dart -r compact`,
  `dart run tool/maintainiac_source_audit.dart --include-tests`, and
  `git diff --check` for the image processor and focused test file.
- `test/receipt_image_data_saver_test.dart` passed all 12 tests, including the
  new missing/empty/corrupt/wrong-type rotate-source regression.
- Touched files remain under 500 lines:
  `receipt_image_processor.dart` 413 lines and
  `receipt_image_data_saver_test.dart` 490 lines.

Known follow-up:
- `receipt_image_data_saver_test.dart` is close to the 500-line limit and
  should be split before adding more image processor regressions there.
