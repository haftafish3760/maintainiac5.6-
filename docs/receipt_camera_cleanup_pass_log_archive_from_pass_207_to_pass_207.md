# Receipt Camera Cleanup Pass Log Archive - Pass 207

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active log under
the 500-line project limit.

## Pass 207 - 07:37:38 EDT to 07:38:41 EDT

Scope:
- Archived active Pass 187 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_187_to_pass_187.md` so the
  active cleanup log stays under the 500-line rule.
- Split vehicle-supply and unknown-fuel merchant-structure coverage out of
  `test/receipt_ocr_service_material_vendor_test.dart` into
  `test/receipt_ocr_service_merchant_structure_test.dart`.
- Kept separatorless money rows, SKU/tax-code suffix handling, OCR summary word
  swaps, and split-cents money inference coverage in the original OCR material
  vendor test.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test test/receipt_ocr_service_material_vendor_test.dart
  test/receipt_ocr_service_merchant_structure_test.dart -r compact`, and
  `git diff --check`.
- Touched files remain under 500 lines:
  `receipt_ocr_service_material_vendor_test.dart` 269 lines and
  `receipt_ocr_service_merchant_structure_test.dart` 156 lines.
