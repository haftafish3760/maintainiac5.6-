# Receipt Camera Cleanup Pass Log Archive - Pass 650

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 650 - 22:51:56 EDT to active cleanup

Scope:
- Hardened the shared ML Kit barcode/QR scanner boundary so privacy-safe
  summaries expose sanitized value-type buckets instead of raw scanner text.
- Made sensitive QR/barcode payload blocking case-insensitive and passed only
  safe value-type buckets into the work-supply barcode bridge.
- Added regressions for uppercase sensitive QR types and malformed value-type
  strings.
- First focused test run failed because `privacySafeSummaryMap` still exposed
  the raw `valueType`; fixed by removing that raw key.
- Recorded `BUG-RECEIPT-0168` under `barcode_qr_scanning`.
- Archived Pass 612 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared scanner and bridge tests.
- Passed focused Flutter barcode scanner and work-supply barcode bridge
  regressions.
