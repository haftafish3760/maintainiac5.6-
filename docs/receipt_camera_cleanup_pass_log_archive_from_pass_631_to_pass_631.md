# Receipt Camera Cleanup Pass Log Archive - Pass 631

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project documentation size cap.

## Pass 631 - 22:12:52 EDT to active cleanup

Scope:
- Hardened OCR parser draft line numbering so malformed signal indexes or direct
  draft line numbers cannot publish `Line 0`, negative review labels, or unsafe
  redaction/proof anchors.
- Routed parser handoff `lineNumberByLineId` through the sanitized line number.
- Added focused behavior regression coverage for malformed draft and signal line
  numbers.
- Archived Pass 621 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0152` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format/analyzer for parser line numbering changes.
- Passed focused Flutter parser handoff structure regression.
- Passed whitespace check.
