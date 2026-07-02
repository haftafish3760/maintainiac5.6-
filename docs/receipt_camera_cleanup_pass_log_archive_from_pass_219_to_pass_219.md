## Pass 219 - 07:56:00 EDT to 07:58:18 EDT

Scope:
- Archived active Pass 199 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_199_to_pass_199.md` so the
  active cleanup log stays under the 500-line rule.
- Split accepted-photo handoff ordering coverage out of
  `receipt_capture_flow_handoff_contract_test.dart` into
  `receipt_capture_flow_handoff_order_test.dart`.
- Kept shared camera attachment metadata, OCR-source handoff, and next/review
  label contract coverage in the original file.
- Reduced `receipt_capture_flow_handoff_contract_test.dart` from 394 lines to
  221 lines; the new handoff-order regression test is 178 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test`, and
  `git diff --check` for both touched handoff test files.
