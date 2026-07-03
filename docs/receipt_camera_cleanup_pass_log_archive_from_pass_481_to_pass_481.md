# Receipt Camera Cleanup Pass Log Archive - Pass 481

Archived from the live cleanup log to keep the active receipt camera pass log
under the project line-count cap.

## Pass 481 - 23:43:00 EDT to 23:45:51 EDT

Scope:
- Added the receipt-line foundation for numbered review modes.
- Extended `ExpenseReceiptLineRecord` with receipt display line numbering,
  price-only versus detailed-line review mode labels, business/personal/split
  review labels, review summaries, and privacy-safe line review contracts.
- Preserved allocation-only behavior for users who only care about the price
  and business/personal/split allocation while detailed lines keep item detail.
- Added model and parser regressions proving parsed receipt lines expose line
  numbers and that allocation-only price lines do not leak item text in
  privacy-safe metadata.

Verification:
- Passed targeted Dart format and analyzer for the expense line model,
  serialization, and focused line/parser tests.
- Passed focused Flutter tests for `test/expense_receipt_line_record_test.dart`
  and `test/expense_receipt_parser_business_personal_test.dart`.
- Passed `bash tool/receipt_doc_size_gate.sh`, receipt source audit with
  `--max-line-length=220`, and targeted `git diff --check`.
