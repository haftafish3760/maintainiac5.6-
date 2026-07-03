# Receipt Camera Cleanup Pass Log Archive - Pass 528

Archived from the active cleanup pass log to keep the live working log under
the project line-count cap.

## Pass 528 - 02:01:00 EDT to 02:05:00 EDT

Scope:
- Hardened OCR parser category and customer-proof line ID lists so duplicate
  stable line IDs do not appear twice in selectable/task/redaction lists.
- Preserved raw `stableLineIds` ordering so duplicate OCR rows remain auditable
  while actionable line-ID lists stay unique.
- Extended duplicate-ID regression coverage for parser task lists,
  inventory/material IDs, and customer-proof review IDs.
- Recorded `BUG-RECEIPT-0046` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format and analyzer for parser handoff line-ID lists,
  customer-proof lists, and parser handoff structure regression coverage.
- Passed focused Flutter test
  `test/receipt_ocr_service_parser_handoff_structure_test.dart --plain-name
  "parser handoff line id maps preserve first duplicate line id"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.
