# Receipt Camera Cleanup Pass Log Archive - Pass 526

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
within the project line-count cap while preserving the pass history.

## Pass 526 - 01:50:00 EDT to 01:55:00 EDT

Scope:
- Hardened OCR parser handoff line-id lookup maps so duplicate stable line IDs
  preserve the first receipt line instead of silently overwriting it with a
  later line.
- Added regression coverage proving line number, proof label, draft, amount,
  and text maps stay pinned to the first duplicate line ID.
- Recorded `BUG-RECEIPT-0044` under `receipt_line_numbering`.
- Archived Pass 501 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial regression expectation to match the existing section-1
  `source line` label contract, then reran the focused chain.
- Passed targeted Dart format and analyzer for parser handoff line maps and
  parser handoff structure regression coverage.
- Passed focused Flutter test
  `test/receipt_ocr_service_parser_handoff_structure_test.dart --plain-name
  "parser handoff line id maps preserve first duplicate line id"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.
