# Receipt Camera Cleanup Pass Log Archive - Pass 855

Times are local to the development machine.

## Pass 855 - 12:15:00 EDT to active cleanup

Scope:
- Changed barcode/QR batch scanning so invalid input paths do not consume the
  valid-image decoder limit.
- Added separate privacy-safe input, scanned, invalid, and skipped-invalid
  summary counts for long-receipt scan batches.
- Recorded `BUG-RECEIPT-0316` under `barcode_qr_scanning`.
- Archived Pass 792 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
