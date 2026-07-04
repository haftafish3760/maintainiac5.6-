# Receipt Camera Cleanup Pass Log Archive - Pass 780

## Pass 780 - 07:20:47 EDT to active cleanup

Scope:
- Hardened OCR scanner-preparation signal/risk handoff for normalized paths.
- Replaced raw `preparationDiagnosticsByOcrPath` lookups with normalized
  receipt-photo map lookups in attachment and capture-flow helpers.
- Added source regressions proving scanner preparation metadata does not depend
  on raw OCR source path equality.
- Recorded `BUG-RECEIPT-0267` under `source_preservation`.
- Archived Pass 752 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Flutter OCR source
  attachment/handoff contract regressions.
- Passed doc-size, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.
