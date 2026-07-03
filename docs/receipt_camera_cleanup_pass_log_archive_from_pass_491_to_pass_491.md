# Receipt Camera Cleanup Pass Log Archive - Pass 491

Archived out of `docs/receipt_camera_cleanup_pass_log.md` during Pass 504 to
keep the active cleanup log under the project line-count cap.

## Pass 491 - 00:16:05 EDT to 00:18:14 EDT

Scope:
- Hardened receipt client-proof redaction planning so subtotal, tax, and total
  lines stay together when totals context is requested.
- Kept unselected item lines and payment/transaction lines hidden unless they
  are explicitly selected or required context.
- Recorded `BUG-RECEIPT-0010` under `privacy_redaction`.

Verification:
- Passed `dart format --set-exit-if-changed` for the receipt layout model and
  direct parser parity test.
- Passed targeted analyzer for receipt layout, direct parser parity, and the
  bug ledger gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed full focused `flutter test
  test/expense_receipt_parser_direct_parity_test.dart -r compact`.

