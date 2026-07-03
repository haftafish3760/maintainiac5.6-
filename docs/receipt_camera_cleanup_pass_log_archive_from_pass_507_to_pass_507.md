# Receipt Camera Cleanup Pass Log Archive - Pass 507

This archive preserves older cleanup/QA passes moved out of the active receipt
camera cleanup log to keep the live log under the project line-count cap.

## Pass 507 - 00:56:22 EDT to 00:57:13 EDT

Scope:
- Hardened quick price-only split line entry so custom business percent text can
  include a percent sign just like the full line editor.
- Added regression coverage proving the quick split parser strips `%` and the
  old direct `double.tryParse(...trim())` path is gone.
- Recorded `BUG-RECEIPT-0025` under `business_personal_split`.
- Archived Pass 471 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for quick line-mode helpers and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
