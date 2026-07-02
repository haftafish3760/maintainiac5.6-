## Pass 231 - 08:18:00 EDT to 08:20:09 EDT

Scope:
- Archived active Pass 210 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_210_to_pass_210.md` so the
  active cleanup log stays under the 500-line rule.
- Split split-row/abbreviated fuel detail OCR evidence out of
  `receipt_ocr_service_vendor_recovery_test.dart` into
  `receipt_ocr_service_fuel_detail_evidence_test.dart`.
- Kept fuel-named merchant, noisy fuel header metadata, unknown fuel total-only
  review, and unknown material merchant structure coverage in the original
  vendor recovery test.
- Reduced `receipt_ocr_service_vendor_recovery_test.dart` from 367 lines to
  233 lines; the new fuel-detail evidence test is 170 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test`, and
  `git diff --check` for both touched OCR-service tests.
