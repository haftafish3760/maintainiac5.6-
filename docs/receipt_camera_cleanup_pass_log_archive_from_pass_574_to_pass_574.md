# Receipt Camera Cleanup Pass Log Archive - Pass 574

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the live pass
log under the project line-count cap.

## Pass 574 - 09:22:37 EDT to 09:24:08 EDT

Scope:
- Hardened Android captured-photo diagnostic rounding so non-finite quality
  values become unknown evidence instead of unsafe diagnostic numbers.
- Hardened iOS captured-photo diagnostic rounding with the same finite-value
  guard.
- Added Android and iOS source contract regressions for finite captured quality
  diagnostics.
- Recorded `BUG-RECEIPT-0090` under `camera_capture_quality`.
- Archived Pass 548 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for Android and iOS native quality
  source regressions.
- Passed focused Flutter regressions
  `test/receipt_native_android_bridge_settings_quality_test.dart` and
  `test/receipt_native_ios_bridge_long_receipt_quality_test.dart`.
