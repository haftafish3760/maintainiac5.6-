# Receipt Camera Cleanup Pass Log Archive - Pass 391

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source audit limit.

## Pass 391 - 12:37:25 EDT to 12:39:35 EDT

Scope:
- Stayed on expense receipt/admin telemetry QA, not PDF or inventory parser
  implementation.
- Split scheduler-specific Firestore telemetry summary tests out of
  `expense_screen_telemetry_firestore_bridge_test.dart` into
  `expense_screen_telemetry_summary_scheduler_firestore_test.dart`.
- Reduced the original Firestore bridge test from 461 lines to 303 lines; the
  new scheduler-focused test is 187 lines.

Failures fixed during this pass:
- First focused analyzer run found an unused ledger-store import left behind in
  the original test after the split. Removed it and reran analyzer green.
- First `bash tool/receipt_fast_guard_gate.sh` rerun failed on two active
  over-220-character constructor lines in
  `expense_screen_telemetry_health_snapshot_builder.dart`. Split those packed
  lines and reran the failed guard green.

Verification:
- Passed `dart format`, focused Flutter tests for both Firestore telemetry
  files, targeted analyzer, source audit, `bash tool/receipt_fast_guard_gate.sh`,
  and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
