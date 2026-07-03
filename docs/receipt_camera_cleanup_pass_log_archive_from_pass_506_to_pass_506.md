# Receipt Camera Cleanup Pass Log Archive - Pass 506

This archive preserves older cleanup/QA passes moved out of the active receipt
camera cleanup log to keep the live log under the project line-count cap.

## Pass 506 - 00:54:54 EDT to 00:55:52 EDT

Scope:
- Hardened single-line split review metadata so the parser review reason records
  the user-selected business percent instead of always saying 50%.
- Added regression coverage proving the old misleading split reason is gone and
  the selected percent helper is present.
- Recorded `BUG-RECEIPT-0024` under `business_personal_split`.
- Archived Pass 470 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test compile failure caused by an unescaped `$percent`
  literal in the regression assertion, then reran the focused checks.
- Passed targeted Dart format and analyzer for receipt entry state actions and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
