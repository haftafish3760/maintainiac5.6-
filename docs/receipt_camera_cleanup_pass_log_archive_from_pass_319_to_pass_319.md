# Receipt Camera Cleanup Pass Log Archive - Pass 319

## Pass 319 - 10:41:09 EDT to 10:41:09 EDT

Scope:
- Tightened the Android session-argument/native-back-handler imports in
  `ReceiptCameraSessionArguments.kt` from the copied generated block to the
  three imports it actually uses.
- Added `receipt_native_android_import_hygiene_test.dart` to guard the cleaned
  Android native receipt camera files against regaining copied import blocks.
- Reduced `ReceiptCameraSessionArguments.kt` from 197 lines to 145 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, and
  `flutter test test/receipt_native_android_import_hygiene_test.dart -r compact`.
- Passed `bash tool/android_receipt_camera_compile_gate.sh`, focused Android
  native settings/import hygiene tests, `bash tool/receipt_fast_guard_gate.sh`,
  and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.75 MB.
