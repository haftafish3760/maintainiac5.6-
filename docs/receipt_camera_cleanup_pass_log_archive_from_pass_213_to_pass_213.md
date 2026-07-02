## Pass 213 - 07:47:57 EDT to 07:48:41 EDT

Scope:
- Archived active Pass 192 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_192_to_pass_192.md` so the
  active cleanup log stays under the 500-line rule.
- Split the healthy native camera UI handoff and attachment document-signal
  coverage out of `test/receipt_camera_result_native_ui_health_test.dart` into
  `test/receipt_camera_result_native_ui_ready_test.dart`.
- Kept missing-control, slow-latency, and incomplete-control risk coverage in
  the original native UI health test.

Failures fixed during this pass:
- First focused analyzer run failed because the original native UI health test
  still used `ReceiptCaptureFlow` after the split. Restored the import and
  reran the same focused verification successfully.

Verification:
- Rerun passed: `dart format`, targeted `dart analyze`, `flutter test
  test/receipt_camera_result_native_ui_health_test.dart
  test/receipt_camera_result_native_ui_ready_test.dart -r compact`, and
  `git diff --check`.
- Touched files remain under 500 lines:
  `receipt_camera_result_native_ui_health_test.dart` 207 lines and
  `receipt_camera_result_native_ui_ready_test.dart` 212 lines.
