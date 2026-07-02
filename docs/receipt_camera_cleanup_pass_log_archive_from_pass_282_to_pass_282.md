# Receipt Camera Cleanup Pass Log Archive - Pass 282

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 282 - 09:43:32 EDT to 09:43:32 EDT

Scope:
- Split the first-use receipt camera intro sheet out of
  `receipt_camera_help_sheet.dart` into
  `receipt_camera_first_use_intro_sheet.dart`.
- Kept ordinary camera help, long receipt guidance, business/personal/split
  guidance, and storage/backup help in the regular help sheet.
- Added the new part to `receipt_attachment_panel.dart` and updated
  `receipt_camera_help_flow_test.dart` so its source-contract bundle follows
  the split intro file.
- Reduced `receipt_camera_help_sheet.dart` from 298 lines to 94 lines; the new
  first-use intro part is 205 lines.

Failures fixed during this pass:
- First focused Flutter test run failed because the source-contract test still
  read only `receipt_camera_help_sheet.dart` after the intro text moved.
  Updated the test bundle to include the new intro part and reran.

Verification:
- Rerun passed `dart format`, targeted `dart analyze`, focused camera-help and
  attachment-panel tests.
- Passed `bash tool/receipt_fast_guard_gate.sh`, `git diff --check`, and the
  standalone `dart run tool/receipt_camera_footprint_audit.dart`; footprint
  remains `total_receipt_camera_ocr_source` at 1.75 MB.
