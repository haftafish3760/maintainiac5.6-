## Pass 230 - 08:16:00 EDT to 08:18:26 EDT

Scope:
- Split subtotal/total wording and missing-final-total OCR diagnostics out of
  `receipt_ocr_service_item_family_test.dart` into
  `receipt_ocr_service_totals_evidence_test.dart`.
- Kept generic priced-line review, embedded amount review, and quantity/fuel
  terminal amount readiness coverage in the original item-family test.
- Reduced `receipt_ocr_service_item_family_test.dart` from 371 lines to
  275 lines; the new totals-evidence test is 132 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test`, and
  `git diff --check` for both touched OCR-service tests.
