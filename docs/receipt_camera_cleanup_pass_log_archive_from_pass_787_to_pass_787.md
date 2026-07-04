# Receipt Camera Cleanup Pass Log Archive - Pass 787

## Pass 787 - 07:53:46 EDT to active cleanup

Scope:
- Changed native capture staging's omitted data-saver fallback from original
  retention to balanced saved proof.
- Added a no-argument staging regression proving saved attachments and recovery
  manifests default to `balanced`, not `original`.
- Recorded `BUG-RECEIPT-0274` under `source_preservation`.
- Archived Pass 760 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native staging regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
