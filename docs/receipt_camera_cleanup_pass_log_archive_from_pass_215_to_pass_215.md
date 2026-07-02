# Receipt Camera Cleanup Pass Log Archive - Pass 215

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project limit.

## Pass 215 - 07:50:13 EDT to 07:51:32 EDT

Scope:
- Split Android native bridge session/auto-capture diagnostics out of
  `test/receipt_native_android_bridge_analysis_exposure_test.dart` into
  `test/receipt_native_android_bridge_auto_capture_test.dart`.
- Kept live analysis, cleanup toggles, OCR-original-first, exposure, focus,
  lock, and capture-block guardrails in the original Android bridge test.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test
  test/receipt_native_android_bridge_analysis_exposure_test.dart
  test/receipt_native_android_bridge_auto_capture_test.dart -r compact`, and
  `git diff --check`.
- Touched files remain under 500 lines:
  `receipt_native_android_bridge_analysis_exposure_test.dart` 252 lines and
  `receipt_native_android_bridge_auto_capture_test.dart` 181 lines.
