# Receipt Camera Cleanup Pass Log Archive - Pass 186

## Pass 186 - 07:02:44 EDT to 07:04:27 EDT

Scope:
- Archived active Pass 165 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_165_to_pass_165.md` so the
  active log stays under the 500-line rule.
- Split native camera shell top controls out of
  `receipt_native_camera_shell.dart` into
  `receipt_native_camera_shell_top_controls.dart`.
- Kept the public `ReceiptNativeCameraShell` composition API stable while moving
  preview tap-focus/pinch-zoom handling, exposure slider UI, and top bar/title
  widgets into the helper part.

Verification:
- Focused verification passed: `dart format`, targeted `dart analyze`, focused
  source audit, and `flutter test test/receipt_native_camera_shell_test.dart
  test/receipt_camera_capture_layout_test.dart
  test/receipt_camera_native_bridge_layout_test.dart -r compact`.
- Fast receipt guard passed: `bash tool/receipt_fast_guard_gate.sh`.
- `git diff --check` passed.
- Touched native shell files remain under 500 lines:
  `receipt_native_camera_shell.dart` 158 lines and
  `receipt_native_camera_shell_top_controls.dart` 247 lines.
