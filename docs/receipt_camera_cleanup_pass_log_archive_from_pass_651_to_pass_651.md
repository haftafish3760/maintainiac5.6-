# Receipt Camera Cleanup Pass Log Archive - Pass 651

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 651 - 22:54:25 EDT to active cleanup

Scope:
- Hardened barcode/QR diagnostic summaries so raw warning text cannot leak into
  admin or telemetry-style privacy-safe maps.
- Replaced raw barcode scan warning summaries with whitelisted warning buckets
  and a generic `barcode_scan_warning` fallback.
- Added regression coverage for private barcode warning text.
- Recorded `BUG-RECEIPT-0169` under `barcode_qr_scanning`.
- Archived Pass 613 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the barcode scanner service and
  focused scanner regression.
- Passed focused Flutter barcode scanner regression.
