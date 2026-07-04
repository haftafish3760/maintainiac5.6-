# Receipt Camera Cleanup Pass Log Archive - Pass 821

## Pass 821 - 13:07:00 EDT to active cleanup

Scope:
- Added a parser-risk parity contract so every saved-photo warning
  `parserRiskCode` must be recognized by OCR source handoff status and
  parser/admin diagnostics.
- The guard prevents future warning families from carrying parser risk in photo
  review while dropping the same risk in OCR-source handoff.
- Recorded `BUG-RECEIPT-0306` under `qa_harness`.
- Archived Pass 814 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted parser-risk parity format/analyzer and focused contract
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
