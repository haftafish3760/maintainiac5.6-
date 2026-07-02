# Receipt Camera Cleanup Pass Log Archive - Pass 323

## Pass 323 - 10:46:39 EDT to 10:48:28 EDT

Scope:
- Tightened Android native capture/close imports in
  `ReceiptCameraCaptureClose.kt` from the copied generated block to the six
  imports it actually uses.
- Extended `receipt_native_android_import_hygiene_test.dart` so the native
  capture/close file cannot regain the generated import block.
- Reduced `ReceiptCameraCaptureClose.kt` from 203 lines to 155 lines.

Failures fixed during this pass:
- First focused Flutter test run used stale
  `receipt_native_bridge_close_recovery_test.dart` target name. Replaced it
  with the existing close-controls and recovery-record tests, then reran green.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused Android import
  hygiene/settings/close/recovery tests, and `bash
  tool/android_receipt_camera_compile_gate.sh`.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.75 MB.
