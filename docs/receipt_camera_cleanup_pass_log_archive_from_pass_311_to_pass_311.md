# Receipt Camera Cleanup Pass Log Archive - Pass 311

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line working limit.

## Pass 311 - 10:30:11 EDT to 10:30:11 EDT

Scope:
- Added `receipt_native_android_diagnostics_payload_test.dart` to guard the
  Android native receipt camera diagnostics map against duplicate keys.
- Removed duplicate Android diagnostics entries for capture-review policy,
  manual/guidance policy, touch/zoom policy, exposure policy, shutter speed, and
  auto-capture policy fields.
- Preserved the canonical policy values near the top of the payload and kept the
  distinct expected-control booleans.

Failures fixed during this pass:
- The new Android diagnostics duplicate-key scan found 12 repeated keys in
  `ReceiptCameraDiagnosticsPayload.kt`; removed the later duplicate copies and
  reran the focused guard.

Verification:
- Passed `dart format`, targeted `dart analyze`, and
  `flutter test test/receipt_native_android_diagnostics_payload_test.dart -r compact`.
- Passed a standalone duplicate-key scan, `bash tool/android_receipt_camera_compile_gate.sh`,
  `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
