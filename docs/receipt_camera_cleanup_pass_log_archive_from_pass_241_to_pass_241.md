# Receipt Camera Cleanup Pass Log Archive - Pass 241

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 241 - 08:31:29 EDT to 08:35:37 EDT

Scope:
- Archived active Pass 219 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_219_to_pass_219.md` so the
  active cleanup log stays under the 500-line rule.
- Split adaptive exposure sampling and row-balancing helpers out of
  `receipt_image_processor_enhancement_helpers.dart` into
  `receipt_image_processor_exposure_helpers.dart`.
- Kept receipt enhancement candidate selection, OCR-source quality guarding,
  faded receipt cleanup, shadow balancing, sharpening, and scoring in the
  original enhancement helper file.
- Reduced `receipt_image_processor_enhancement_helpers.dart` from 349 lines to
  280 lines; the new exposure helper part is 70 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, and focused `flutter test
  test/receipt_image_source_prep_test.dart test/receipt_image_cleanup_settings_test.dart
  test/receipt_image_ocr_source_guard_test.dart test/receipt_image_data_saver_test.dart
  -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
