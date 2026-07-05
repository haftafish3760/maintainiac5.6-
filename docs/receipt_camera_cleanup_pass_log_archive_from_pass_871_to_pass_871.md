# Receipt Camera Cleanup Pass Log Archive - Pass 871

This archive keeps older receipt camera cleanup pass entries outside the active
cleanup log so the active log stays under the project line-count cap.

## Pass 871 - 16:12:00 EDT to active cleanup

Scope:
- Stopped top-section retakes from feeding the next receipt section into the
  native previous-section ghost overlay field.
- Added a previous-section-only retake guide handoff so native top ghost
  overlays are used only when the retake has true previous-section context.
- Kept top-section next-context guidance as review guidance until a real
  next-section overlay exists.
- Added focused retake-order and long-receipt guidance regressions.
- Recorded `BUG-RECEIPT-0320` under `ghost_overlap_stitching`.
- Archived Pass 798 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused retake-order/long-receipt
  guidance regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
