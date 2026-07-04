# Receipt Camera Cleanup Pass Log Archive - Pass 773 to Pass 773

This archive keeps older completed cleanup entries available while the active
cleanup log stays under the project line cap.

## Pass 773 - 05:54:18 EDT to active cleanup

Scope:
- Hardened recovered native-capture review opening so the first recovered photo
  index uses the normalized existing receipt photo count.
- Prevented invalid or duplicate existing review paths from shifting recovered
  receipt photos to the wrong selected section.
- Added a recovery-contract source regression for normalized recovered-photo
  index calculation.
- Recorded `BUG-RECEIPT-0261` under `camera_review_state`.
- Archived Pass 745 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for recovery review index changes.
- Passed focused Flutter recovery contract regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
