# Receipt Camera Cleanup Pass Log Archive - Pass 221

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project limit.

## Pass 221 - 07:59:00 EDT to 08:01:08 EDT

Scope:
- Split footer amount filtering coverage out of
  `receipt_ocr_service_fuel_unknown_test.dart` into
  `receipt_ocr_service_footer_amount_test.dart`.
- Kept merchant header recovery, damaged date/time recovery, and total-only
  receipt math coverage in the original OCR-service test.
- Reduced `receipt_ocr_service_fuel_unknown_test.dart` from 400 lines to
  284 lines; the new footer amount regression test is 152 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test`, and
  `git diff --check` for both touched OCR-service test files.
