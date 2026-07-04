# Receipt Camera Cleanup Pass Log Archive - Pass 744

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active
cleanup log under the project line-count cap.

## Pass 744 - 03:42:58 EDT to active cleanup

Scope:
- Hardened parser/readiness gates so duplicate OCR line IDs downgrade receipt
  parser, downstream, merchant-independent, mixed-classification, and lean-local
  OCR readiness instead of appearing only as metadata.
- Added a focused regression with an otherwise ready receipt whose duplicate
  line IDs force review before line-numbered proof or split classification.
- Split duplicate line identity coverage into a focused test file after the
  source audit caught the structure test over the line cap.
- Recorded `BUG-RECEIPT-0232` under `receipt_line_numbering`.
- Archived Pass 719 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for parser handoff readiness.
- Passed focused Flutter parser handoff structure and line-identity regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates after splitting the oversized test.
