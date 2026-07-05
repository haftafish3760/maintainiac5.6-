# Receipt Camera Cleanup Pass Log Archive - Pass 841

Times are local to the development machine.

## Pass 841 - 11:51:00 EDT to active cleanup

Scope:
- Added privacy-safe batch barcode/QR summary counts for scanned images,
  warning images, and invalid images.
- Pinned mixed valid/invalid long-receipt barcode inputs so QA/admin diagnostics
  can see scan coverage without exposing raw paths.
- Recorded `BUG-RECEIPT-0315` under `barcode_qr_scanning`.
- Archived Pass 790 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
