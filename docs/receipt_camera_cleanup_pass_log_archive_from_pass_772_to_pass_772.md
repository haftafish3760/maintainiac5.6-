# Receipt Camera Cleanup Pass Log Archive - Pass 772

This archive preserves older cleanup passes moved out of
`receipt_camera_cleanup_pass_log.md` to keep the active log under the project
line cap.

## Pass 772 - 05:51:44 EDT to active cleanup

Scope:
- Hardened attachment-panel review opening so Add Existing Photo / picked-photo
  review uses the normalized existing receipt photo count for the first new
  section index.
- Prevented invalid or duplicate existing attachment photo paths from shifting
  the review screen away from newly picked receipt photos.
- Added source regressions for normalized first-new-photo index calculation.
- Recorded `BUG-RECEIPT-0260` under `camera_review_state`.
- Archived Pass 744 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for attachment review index changes.
- Passed focused Flutter camera capture layout/native bridge layout
  regressions.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
