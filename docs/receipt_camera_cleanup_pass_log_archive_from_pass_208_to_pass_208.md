## Pass 208 - 07:37:38 EDT to 07:40:42 EDT

Scope:
- Archived active `Pass 188` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_188_to_pass_188.md`
  so the active cleanup log stays under the 500-line project limit.
- Split downstream readiness, required parser field status, and final aggregate
  parser handoff counts out of `receipt_ocr_parser_handoff_tasks.dart` into
  `receipt_ocr_parser_handoff_counts.dart`.
- Kept parser task line IDs, missing-field counts, review task counts, parser
  buckets, expense family counts, parser hints, and field readiness counts in
  the original task file.
- Reduced `receipt_ocr_parser_handoff_tasks.dart` from 371 lines to 213 lines;
  the new handoff-counts part is 161 lines.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, and `flutter test
  test/receipt_ocr_service_parser_diagnostics_summary_test.dart
  test/receipt_ocr_service_totals_coverage_test.dart
  test/receipt_privacy_event_test.dart
  test/expense_parser_failure_diagnostics_ocr_handoff_test.dart -r compact`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed.
