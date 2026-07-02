## Pass 224 - 08:05:00 EDT to 08:08:50 EDT

Scope:
- Archived active Pass 203 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_203_to_pass_203.md` so the
  active cleanup log stays under the 500-line rule.
- Split stitch result labels, fallback reason labels, final OCR path rebinding,
  and durable OCR artifact copy coverage out of `receipt_stitching_test.dart`
  into `receipt_stitching_result_contract_test.dart`.
- Kept generated-image stitching, zoom/rotation, oversized-output fallback, and
  low-confidence overlap fallback coverage in the original stitching test.
- Reduced `receipt_stitching_test.dart` from 385 lines to 238 lines; the new
  stitching result contract test is 155 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test`, and
  `git diff --check` for both touched stitching tests.
