# Receipt Camera Cleanup Pass Log Archive - Pass 573

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 573 - 09:14:52 EDT to 09:21:30 EDT

Scope:
- Hardened Android native camera session double extras so non-finite zoom,
  exposure, and auto-capture thresholds fall back before camera clamping.
- Hardened iOS native camera session double arguments so non-finite zoom,
  exposure, and auto-capture thresholds cannot reach AVFoundation controls.
- Added Android and iOS source contract regressions for finite native bridge
  double handling.
- Recorded `BUG-RECEIPT-0089` under `native_bridge`.
- Archived Pass 547 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed one line-wrap-sensitive Android source regression expectation, then
  reran the focused native bridge checks.
- Passed targeted Dart format/analyzer for Android and iOS native bridge source
  regressions.
- Passed focused Flutter regressions
  `test/receipt_native_android_bridge_settings_quality_test.dart` and
  `test/receipt_native_ios_bridge_ui_session_test.dart`.
