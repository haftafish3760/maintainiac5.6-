# Receipt Camera Cleanup Pass Log Archive - Pass 508

This archive preserves older cleanup/QA passes moved out of the active receipt
camera cleanup log to keep the live log under the project line-count cap.

## Pass 508 - 00:58:43 EDT to 00:59:26 EDT

Scope:
- Hardened the main split-percent sheet so custom business percent text can
  include a percent sign, matching the quick price-only split path.
- Added regression coverage proving the old direct custom controller parse path
  is gone.
- Recorded `BUG-RECEIPT-0026` under `business_personal_split`.
- Archived Pass 472 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the split percent sheet and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
