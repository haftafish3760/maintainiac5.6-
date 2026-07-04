# Receipt Camera Cleanup Pass Log Archive - Pass 825

## Pass 825 - 14:43:00 EDT to active cleanup

Scope:
- Hardened barcode/QR privacy lookup blocking for compact customer/account
  identifiers that do not use a separator after the sensitive token.
- Added focused barcode scanner regression coverage so customer/account QR text
  cannot become an inventory lookup candidate or leak raw values in summaries.
- Recorded `BUG-RECEIPT-0311` under `barcode_qr_scanning`.
- Archived Pass 786 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and diff
  whitespace gates.
