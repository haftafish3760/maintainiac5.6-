# Receipt Camera Cleanup Pass Log Archive - Pass 493

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 493 - 00:42:00 EDT to 00:47:00 EDT

Scope:
- Hardened receipt line split allocation math so parser/adaptor-created split
  lines cannot produce more than 100% business or negative personal amounts.
- Ensured serialized receipt line maps write bounded split percentages, keeping
  saved records and downstream reports inside valid financial ranges.
- Added regression coverage for malformed over- and under-allocated split
  percentages.
- Recorded `BUG-RECEIPT-0012` under `business_personal_split`.
- Archived Pass 486 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for receipt line records,
  serialization, and focused line-record regression coverage.
- Passed focused Flutter regression
  `test/expense_receipt_line_record_test.dart --plain-name "split receipt lines
  bound malformed business percentages"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
