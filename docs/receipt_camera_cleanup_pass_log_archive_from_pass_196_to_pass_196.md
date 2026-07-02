# Receipt Camera Cleanup Pass Log Archive - Pass 196

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project rule.

## Pass 196 - 07:22:58 EDT to 07:23:34 EDT

Scope:
- Archived active Pass 175 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_175_to_pass_175.md` so the
  active cleanup log stays under the 500-line rule.
- Split default data-saver, optional parser-pack, and install-footprint coverage
  out of `test/receipt_capture_settings_store_test.dart` into
  `test/receipt_capture_settings_data_saver_test.dart`.
- Kept camera preferences, performance mode, assisted auto-capture, effective
  runtime profile, source-level hardware privacy checks, and area reset defaults
  in the original settings store test.
- Preserved the Hive-backed controller setup in both focused test files so each
  suite can run independently.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test test/receipt_capture_settings_store_test.dart
  test/receipt_capture_settings_data_saver_test.dart -r compact`, and
  `git diff --check`.
- Touched files remain under 500 lines:
  `receipt_capture_settings_store_test.dart` 173 lines and
  `receipt_capture_settings_data_saver_test.dart` 311 lines.
