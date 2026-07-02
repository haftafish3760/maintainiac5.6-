## Pass 209 - 07:40:43 EDT to 07:41:50 EDT

Scope:
- Split missing-vendor review variants out of
  `test/receipt_ocr_service_long_receipt_diagnostics_test.dart` into
  `test/receipt_ocr_service_vendor_review_test.dart`.
- Kept damaged-header recovery and address/contact metadata suppression coverage
  in the original long-receipt diagnostics test.
- Removed unused temp-directory and path-provider mock setup from the original
  test after confirming the coverage is pure `ReceiptOcrResult` contract logic.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test
  test/receipt_ocr_service_long_receipt_diagnostics_test.dart
  test/receipt_ocr_service_vendor_review_test.dart -r compact`, and
  `git diff --check`.
- Touched files remain under 500 lines:
  `receipt_ocr_service_long_receipt_diagnostics_test.dart` 200 lines and
  `receipt_ocr_service_vendor_review_test.dart` 185 lines.
