# Receipt Camera Cleanup Pass Log Archive - Pass 789

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the project line-count cap.

## Pass 789 - 08:01:22 EDT to active cleanup

Scope:
- Renamed native camera memory-policy diagnostics from original-for-OCR wording
  to temporary-source-for-OCR wording.
- Updated Android/iOS default policy strings, Dart session policy strings, and
  focused fixtures/expectations that consume those diagnostics.
- Kept the legacy `ocrUsesOriginalFirst` bridge key untouched for compatibility.
- Recorded `BUG-RECEIPT-0276` under `source_preservation`.
- Archived Pass 762 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native camera storage,
  session, contract, and staging regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
