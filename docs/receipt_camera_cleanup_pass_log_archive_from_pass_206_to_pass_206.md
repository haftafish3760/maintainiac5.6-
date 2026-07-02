## Pass 206 - 07:35:46 EDT to 07:37:37 EDT

Scope:
- Archived active `Pass 186` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_186_to_pass_186.md`
  so the active cleanup log stays under the 500-line project limit.
- Split OCR parser expense-family classification helpers out of
  `receipt_ocr_parser_line_signals.dart` into
  `receipt_ocr_parser_line_families.dart`.
- Kept OCR line normalization, trait building, confidence, and review reasons in
  the original line-signals file.
- Reduced `receipt_ocr_parser_line_signals.dart` from 374 lines to 299 lines;
  the new family helper part is 76 lines.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, and `flutter test test/receipt_ocr_service_item_family_test.dart
  test/receipt_ocr_service_line_signals_test.dart
  test/receipt_ocr_service_fuel_receipts_test.dart
  test/receipt_ocr_service_parser_handoff_structure_test.dart -r compact`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed.
