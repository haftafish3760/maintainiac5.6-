# Receipt Camera Cleanup Pass Log Archive - Pass 797

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line cap.

## Pass 797 - 08:52:23 EDT to active cleanup

Scope:
- Hardened the shared ML Kit barcode/QR scanner boundary so only local absolute
  image paths can reach the decoder.
- Blocked relative paths, URLs, PDFs/text files, whitespace-padded paths, and
  NUL-tainted paths before ML Kit invocation.
- Added barcode scanner path-family regressions.
- Recorded `BUG-RECEIPT-0281` under `barcode_qr_scanning`.
- Archived Pass 767 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
