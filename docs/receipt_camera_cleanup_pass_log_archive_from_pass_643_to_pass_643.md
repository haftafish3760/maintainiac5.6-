# Receipt Camera Cleanup Pass Log Archive - Pass 643

Archived from the active cleanup log so the current working log stays under the
project documentation line-count cap.

## Pass 643 - 22:37:28 EDT to active cleanup

Scope:
- Hardened manual long-receipt reorder summaries so malformed non-adjacent
  section moves cannot be reported as preserved order.
- Added manual-reorder invalid codes for unknown direction, non-adjacent moves,
  and missing preserved-path evidence.
- Added focused regression coverage proving a bad manual reorder stays
  privacy-safe and becomes a section-order handoff risk.
- Recorded `BUG-RECEIPT-0162` under `multi_photo_ordering`.
- Archived Pass 606 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format for section-order helpers and regressions.
- Passed focused Flutter section-order regression.
