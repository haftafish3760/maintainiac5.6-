# Receipt Camera Cleanup Pass Log Archive - Pass 870

This archive keeps older receipt camera cleanup pass entries outside the active
cleanup log so the active log stays under the project line-count cap.

## Pass 870 - 16:09:00 EDT to active cleanup

Scope:
- Forwarded long-receipt retake alignment reason and guidance into the native
  camera session when a user retakes a top, middle, or bottom receipt segment.
- Kept generic coverage guidance as the fallback only when no retake alignment
  context exists.
- Added retake guidance text regressions for top, middle, and bottom segment
  replacement.
- Added long-receipt handoff regressions proving the retake context is wired
  through to native previous-section reason/guidance fields.
- Recorded `BUG-RECEIPT-0319` under `ghost_overlap_stitching`.
- Archived Pass 797 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused retake-order/long-receipt
  guidance regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
