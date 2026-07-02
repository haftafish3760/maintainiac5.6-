# Receipt Camera Cleanup Pass Log Archive - Pass 168

This archive keeps the active receipt camera cleanup log under the 500-line
project limit while preserving the full pass history.

## Pass 168 - 06:33:15 EDT to 06:34:16 EDT

Scope:
- Split receipt recap line controls out of
  `lib/screens/expenses/entry/expense_receipt_recap_allocation_controls.dart`
  into `expense_receipt_recap_line_controls.dart`.
- Kept the business/personal/split line-row widgets behavior-preserving while
  reducing the allocation controls file from 451 lines to 184 lines.
- Restored the source-visible OCR bottom-section ghost-slice action contract in
  `expense_receipt_parse_diagnostics_ocr.dart` using a line-length-safe
  constant.

Verification:
- `dart format`, focused `dart analyze`, and source audit passed for touched
  recap/OCR files.
- First focused assisted-review test run failed because QA could not find the
  exact ghost-slice action phrase in source after it was split across adjacent
  strings.
- Fixed that contract, then `flutter test
  test/expense_receipt_assisted_review_flow_test.dart
  test/expense_receipt_assisted_review_save_guardrails_test.dart -r compact`
  passed.
- `bash tool/receipt_fast_guard_gate.sh` passed after the repair.

Known follow-up:
- Continue reducing near-limit receipt/OCR files and keep long-receipt
  continuation contracts source-visible for QA.
