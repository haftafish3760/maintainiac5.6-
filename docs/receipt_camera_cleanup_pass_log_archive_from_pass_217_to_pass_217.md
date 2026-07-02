## Pass 217 - 07:54:00 EDT to 07:55:38 EDT

Scope:
- Archived active Pass 197 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_197_to_pass_197.md` so the
  active cleanup log stays under the 500-line rule.
- Split saved-photo camera warning coverage out of
  `receipt_camera_result_native_close_settings_test.dart` into
  `receipt_camera_result_saved_photo_warning_test.dart`.
- Kept native close/back/settings control health coverage in the original file
  while giving saved-photo OCR-readability handoff signals their own focused
  regression test.
- Reduced `receipt_camera_result_native_close_settings_test.dart` from 410 lines
  to 303 lines; the new saved-photo warning test is 111 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test`, and
  `git diff --check` for both touched test files.
