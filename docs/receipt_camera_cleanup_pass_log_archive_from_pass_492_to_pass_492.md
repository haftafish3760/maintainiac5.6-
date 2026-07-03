# Receipt Camera Cleanup Pass Log Archive - Pass 492

Archived out of `docs/receipt_camera_cleanup_pass_log.md` during Pass 505 to
keep the active cleanup log under the project line-count cap.

## Pass 492 - 00:18:14 EDT to 00:19:58 EDT

Scope:
- Hardened multi-photo native review-depth handoff so detailed line review is
  not downgraded to prices-only when any captured section requests detailed
  lines.
- Added privacy-safe review-depth counts to receipt reader handoff metadata.
- Recorded `BUG-RECEIPT-0011` under `receipt_line_review_mode`.
- Archived Pass 469 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed `dart format --set-exit-if-changed` for receipt review result native
  signal/metadata files and focused frozen result test.
- Passed targeted analyzer for receipt capture models, focused frozen result
  test, and bug ledger gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed full focused `flutter test
  test/receipt_camera_result_frozen_brain_install_test.dart -r compact`.

