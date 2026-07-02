## Pass 292 - 09:58:00 EDT to 10:00:54 EDT

Scope:
- Split Android native previous-section ghost-guide UI and labels out of
  `ReceiptCameraUiChrome.kt` into `ReceiptCameraPreviousSectionGuide.kt`.
- Kept build-content ordering unchanged while moving the long-receipt overlap
  slice, accessibility copy, add-section labels, and bounded fraction helper to
  the new native camera helper file.
- Reduced `ReceiptCameraUiChrome.kt` from 405 lines to 277 lines; the new
  previous-section guide file is 141 lines.

Verification:
- Passed scoped source audit, focused Android native bridge UI/settings/close
  tests, and `bash tool/android_receipt_camera_compile_gate.sh`.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`;
  footprint remains `total_receipt_camera_ocr_source` at 1.75 MB.
