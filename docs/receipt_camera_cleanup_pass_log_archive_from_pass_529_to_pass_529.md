# Receipt Camera Cleanup Pass Log Archive - Pass 529

Archived out of the live cleanup log to keep the active pass log under the
project line-count cap.

## Pass 529 - 02:12:33 EDT to 02:16:00 EDT

Scope:
- Hardened malformed retake section metadata so invalid retake-order evidence
  wins over preserved-slot evidence in receipt section order summaries.
- Added regression coverage proving an invalid middle-section retake reports
  `retake_order_invalid` and emits a matching privacy-safe evidence label.
- Recorded `BUG-RECEIPT-0047` under `multi_photo_ordering`.

Verification:
- Passed targeted Dart format and analyzer for retake section-order outcome
  logic and focused stitch scanner regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_stitch_scanner_test.dart --plain-name
  "malformed retake section metadata is counted without leaking paths"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.
