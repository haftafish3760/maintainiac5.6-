# Receipt Camera Cleanup Pass Log Archive - Pass 786

## Pass 786 - 07:50:34 EDT to active cleanup

Scope:
- Reworded saved-proof preview copy that labeled the comparison size as an
  original photo.
- Changed the details row to `Capture source size` and the footer to
  `Capture source` so the panel does not imply full original retention.
- Added help-flow source regressions against the stale original-photo label.
- Recorded `BUG-RECEIPT-0273` under `source_preservation`.
- Archived Pass 759 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused help-flow source
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
