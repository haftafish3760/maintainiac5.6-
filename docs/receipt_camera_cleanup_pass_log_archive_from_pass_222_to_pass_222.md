# Receipt Camera Cleanup Pass Log Archive - Pass 222

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project limit.

## Pass 222 - 08:00:57 EDT to 08:03:32 EDT

Scope:
- Archived active Pass 201 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_201_to_pass_201.md` so the
  active cleanup log stays under the 500-line rule.
- Split saved-photo warning action codes, parser risk codes, primary action
  labels, parser impact guidance, and final user-facing message composition out
  of `receipt_native_saved_photo_warning.dart` into
  `receipt_native_saved_photo_warning_details.dart`.
- Kept diagnostic classification and readability threshold helpers in the
  original warning file.
- Reduced `receipt_native_saved_photo_warning.dart` from 360 lines to 273
  lines; the new warning-details part is 91 lines.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, and `flutter test
  test/receipt_camera_result_saved_photo_warning_test.dart
  test/receipt_camera_result_native_quality_test.dart
  test/receipt_photo_review_quality_handoff_test.dart
  test/expense_screen_telemetry_camera_health_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
