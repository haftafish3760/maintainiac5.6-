# Receipt Camera Cleanup Pass Log Archive - Pass 180

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line file-size rule.

## Pass 180 - 06:54:05 EDT to 06:55:59 EDT

Scope:
- Archived active `Pass 161` into a focused archive file so the active cleanup
  log stays under the 500-line project limit.
- Split older-phone OCR parser scope and inventory parser-depth coverage out of
  `test/expense_receipt_parser_ocr_handoff_test.dart` into
  `test/expense_receipt_parser_capability_scope_test.dart`.
- Kept the full parser-ready OCR signal handoff contract in the original file.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, `flutter test
  test/expense_receipt_parser_ocr_handoff_test.dart
  test/expense_receipt_parser_capability_scope_test.dart -r compact`,
  focused source audit, and `git diff --check`.
- Touched files remain under 500 lines:
  `expense_receipt_parser_ocr_handoff_test.dart` 349 lines and
  `expense_receipt_parser_capability_scope_test.dart` 116 lines.
