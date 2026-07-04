# Receipt Camera Cleanup Pass Log Archive - Pass 704

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 704 - 02:18:00 EDT to active cleanup

Scope:
- Audited the shared Google ML Kit barcode/QR scanner foundation after the
  camera-lane reminder to keep scanner support shared across expenses,
  inventory, and maintenance without touching inventory internals.
- Added corrupted/wrong-file style regression coverage so generic decoder
  failures become safe `barcode_scan_failed` warnings.
- Proved raw exception text from barcode failures does not leak into
  privacy-safe scanner summaries.
- Recorded `BUG-RECEIPT-0191` under `barcode_qr_scanning`.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service tests.
- Passed focused Flutter barcode scanner service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 645 from the active cleanup log to keep the doc under cap.
