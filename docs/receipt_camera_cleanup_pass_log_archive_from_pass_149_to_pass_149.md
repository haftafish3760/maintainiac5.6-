## Pass 149 - 05:59:00 EDT to 06:01:30 EDT

Scope:
- Split `ReceiptLayoutAnalyzer` out of
  `lib/shared/receipts/receipt_layout_intelligence.dart` into
  `lib/shared/receipts/receipt_layout_analyzer.dart`.
- Kept `receipt_layout_intelligence.dart` as the public library entrypoint, so
  existing imports continue to work.
- Reduced the near-limit production receipt layout file from 497 lines to 269
  lines; the new analyzer part is 229 lines.

Verification:
- `dart format` passed for the touched layout files.
- `dart analyze` passed for the layout library files and focused direct parser
  parity test.
- `flutter test test/expense_receipt_parser_direct_parity_test.dart -r compact`
  passed all 6 focused parser/layout tests.
- `dart run tool/maintainiac_source_audit.dart` passed for the touched layout
  files and focused test with `--max-line-length=220`.
- `bash tool/receipt_fast_guard_gate.sh` passed before this log entry.
- `git diff --check` passed.
- Touched layout files remain under 500 lines:
  `receipt_layout_intelligence.dart` 269 lines,
  `receipt_layout_analyzer.dart` 229 lines, and
  `receipt_layout_patterns.dart` 42 lines.

Known follow-up:
- Continue reducing near-limit receipt/OCR production files before adding new
  behavior to them.
