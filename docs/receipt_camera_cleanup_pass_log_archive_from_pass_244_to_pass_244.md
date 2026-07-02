# Receipt Camera Cleanup Pass Log Archive - Pass 244

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 244 - 08:35:38 EDT to 08:38:34 EDT

Scope:
- Archived active Pass 223 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_223_to_pass_223.md` so the
  active cleanup log stays under the 500-line rule.
- Split saved-proof count labels, next-review source selection labels, handoff
  labels, diagnostic labels, and match-readiness labels out of
  `receipt_capture_review_result_completion.dart` into
  `receipt_capture_review_result_next_review.dart`.
- Kept possible-partial receipt detection, final-section evidence, user
  completion decisions, and completion outcome counts in the original
  completion file.
- Reduced `receipt_capture_review_result_completion.dart` from 349 lines to 256
  lines; the new next-review part is 96 lines.
- Updated the two handoff source-contract tests that read the completion file
  directly so they include the new next-review part.

Verification:
- Passed: `dart format`, targeted `dart analyze`, and focused `flutter test
  test/receipt_capture_flow_handoff_order_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart
  test/receipt_camera_result_completion_coverage_test.dart
  test/receipt_camera_result_stitch_scanner_test.dart
  test/receipt_camera_result_coverage_totals_test.dart
  test/receipt_photo_review_exit_completion_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
