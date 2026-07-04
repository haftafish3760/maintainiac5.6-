# Receipt Camera Cleanup Pass Log Archive - Pass 820

Archived from the active receipt camera cleanup log to keep the current log
under the project line cap.

## Pass 820 - 12:44:00 EDT to active cleanup

Scope:
- Preserved saved-photo parser-risk codes as OCR source risk flags in both
  shared capture-flow and attachment-panel handoff builders.
- Taught OCR source handoff and parser/admin diagnostics to classify the
  parser-risk tokens even if a future path lacks the matching action token.
- Added focused regressions for source builder parity and parser-risk-only
  source handoff classification.
- Recorded `BUG-RECEIPT-0305` under `ocr_handoff_contract`.
- Archived Pass 813 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted parser-risk handoff format/analyzer and focused regressions.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
