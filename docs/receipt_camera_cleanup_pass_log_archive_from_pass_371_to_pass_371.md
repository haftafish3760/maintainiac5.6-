# Receipt Camera Cleanup Pass Log Archive - Pass 371

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active cleanup
log under the 500-line file-size guard.

## Pass 371 - 12:01:58 EDT to 12:04:48 EDT

Scope:
- Split receipt entry split-percentage modal logic out of
  `expense_receipt_entry_state_actions.dart` into
  `expense_receipt_entry_split_percent_actions.dart`.
- Kept line editing, date/time selection, draft scheduling, parser line
  confirmation, expense-only marking, and line-use mutation in the original
  state-actions part.
- Reduced `expense_receipt_entry_state_actions.dart` from 341 lines to 215
  lines; the new split-percent actions part is 130 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused assisted-review
  handoff/save-guardrail tests, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
