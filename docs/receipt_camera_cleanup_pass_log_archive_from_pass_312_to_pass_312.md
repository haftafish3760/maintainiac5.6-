# Receipt Camera Cleanup Pass Log Archive - Pass 312

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line working limit.

## Pass 312 - 10:32:00 EDT to 10:34:36 EDT

Scope:
- Split the shared receipt store information bottom sheet out of
  `receipt_store_panel.dart` into `receipt_store_panel_sheet.dart`.
- Kept the public `SharedReceiptStorePanel` entrypoint and sheet-open guard in
  the original file, and left state-list/phone-format support in the existing
  support part.
- Reduced `receipt_store_panel.dart` from 465 lines to 179 lines; the new
  sheet part is 288 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused
  `receipt_store_panel_test.dart`, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.76 MB.

- Footprint remains `total_receipt_camera_ocr_source` at 1.76 MB.
