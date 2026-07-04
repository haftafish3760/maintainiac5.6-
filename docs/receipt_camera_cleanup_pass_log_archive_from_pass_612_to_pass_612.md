# Receipt Camera Cleanup Pass Log Archive - Pass 612

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
camera cleanup log under the project line-count cap.

## Pass 612 - 21:23:12 EDT to active cleanup

Scope:
- Hardened receipt layout line numbering so malformed zero or negative line
  numbers clamp before stable line IDs, proof redaction anchors, parser line
  lists, and client-proof default visible line lists use them.
- Filtered invalid requested redaction line numbers out of generated
  client-proof redaction plans.
- Added regression coverage for malformed layout lines and privacy-safe proof
  anchors.
- Recorded `BUG-RECEIPT-0133` under `receipt_line_numbering`.
- Archived Pass 589 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for receipt layout intelligence and
  direct parser parity regressions.
- Passed focused Flutter direct parser parity regression coverage.
