# Receipt Camera Cleanup Pass Log Archive - Pass 688

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 688 - 00:46:49 EDT to active cleanup

Scope:
- Added explicit business and personal allocated subtotal, tax, and total
  values to selected receipt line references while preserving raw receipt
  totals for audit.
- Exposed selected business/personal totals on receipt selection bundles and
  privacy-safe readiness maps so split lines cannot be mistaken for all-business
  amounts downstream.
- Added regression coverage for a 50/50 split receipt line in the invoice/client
  proof selection contract.
- Recorded `BUG-RECEIPT-0175` under `business_personal_split`.
- Archived Pass 617 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt line selection contracts.
- Passed focused Flutter receipt processing contract regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.
