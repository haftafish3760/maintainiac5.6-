# Receipt Camera Cleanup Pass Log Archive - Pass 326

## Pass 326 - 10:50:22 EDT to 10:51:02 EDT

Scope:
- Tightened Android native diagnostics label imports in
  `ReceiptCameraDiagnosticsLabels.kt` from the copied generated block to the
  eleven imports it actually uses.
- Extended `receipt_native_android_import_hygiene_test.dart` so the diagnostics
  label helper cannot regain the generated import block.
- Reduced `ReceiptCameraDiagnosticsLabels.kt` from 169 lines to 125 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused Android import
  hygiene/analysis/settings tests, and `bash
  tool/android_receipt_camera_compile_gate.sh`.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
