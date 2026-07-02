## Pass 214 - 07:48:42 EDT to 07:50:12 EDT

Scope:
- Archived active Pass 194 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_194_to_pass_194.md` so the
  active cleanup log stays under the 500-line rule.
- Split source-section line maps, section continuity status, section review
  flags, and section-scoped parser line IDs out of
  `receipt_ocr_parser_handoff_lines.dart` into
  `receipt_ocr_parser_handoff_source_sections.dart`.
- Kept general line IDs, role maps, line drafts, item amount maps, and privacy
  safe line summaries in the original parser handoff line file.
- Reduced `receipt_ocr_parser_handoff_lines.dart` from 367 lines to 242 lines;
  the new source-section part is 128 lines.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, and `flutter test
  test/receipt_ocr_service_read_warnings_test.dart
  test/receipt_ocr_service_totals_coverage_test.dart
  test/receipt_processing_contract_test.dart
  test/receipt_ocr_service_parser_diagnostics_summary_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
