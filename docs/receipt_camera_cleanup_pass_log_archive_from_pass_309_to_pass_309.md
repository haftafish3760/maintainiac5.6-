# Receipt Camera Cleanup Pass Log Archive

Archived from the active cleanup pass log to keep the active file under the
500-line working limit.

## Pass 309 - 10:28:32 EDT to 10:28:32 EDT

Scope:
- Added `receipt_native_ios_diagnostics_payload_test.dart` to guard the iOS
  native receipt camera diagnostics dictionary against duplicate keys.
- The test extracts keys from `nativeCaptureDiagnostics` and fails if a later
  key would overwrite an earlier privacy-safe diagnostic value.
- This turns the duplicate-key warning cleanup from Pass 304 into a permanent
  focused regression guard.

Verification:
- Passed `dart format test/receipt_native_ios_diagnostics_payload_test.dart`.
- Passed `dart analyze test/receipt_native_ios_diagnostics_payload_test.dart`.
- Passed `flutter test test/receipt_native_ios_diagnostics_payload_test.dart -r compact`.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.76 MB.
