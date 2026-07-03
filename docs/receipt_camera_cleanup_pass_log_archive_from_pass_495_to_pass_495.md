# Receipt Camera Cleanup Pass Log Archive - Pass 495

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 495 - 01:03:00 EDT to 01:07:00 EDT

Scope:
- Hardened the receipt line editor split-percent parser so negative values keep
  their sign until the clamp step instead of becoming positive percentages.
- Added regression coverage that blocks the old non-digit stripping behavior and
  keeps percent-sign normalization explicit.
- Recorded `BUG-RECEIPT-0014` under `business_personal_split`.
- Archived Pass 484 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the receipt line editor derived
  fields and assisted-review source regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
