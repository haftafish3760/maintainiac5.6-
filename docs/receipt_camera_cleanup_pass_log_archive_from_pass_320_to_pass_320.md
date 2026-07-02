# Receipt Camera Cleanup Pass Log Archive - Pass 320

## Pass 320 - 10:43:07 EDT to 10:43:07 EDT

Scope:
- Tightened the Android captured-photo quality imports in
  `ReceiptCameraPhotoQuality.kt` from the copied generated block to the five
  imports it actually uses.
- Extended `receipt_native_android_import_hygiene_test.dart` so the cleaned
  photo-quality native file cannot regain the generated import block.
- Reduced `ReceiptCameraPhotoQuality.kt` from 172 lines to 122 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, and focused Android import
  hygiene/settings tests.
- Passed `bash tool/android_receipt_camera_compile_gate.sh`, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.75 MB.
