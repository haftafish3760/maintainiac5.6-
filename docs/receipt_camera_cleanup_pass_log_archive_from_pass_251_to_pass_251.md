# Receipt Camera Cleanup Pass Log Archive

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line rule.

## Pass 251 - 08:49:04 EDT to 08:51:14 EDT

Scope:
- Archived active Passes 230 and 231 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_230_to_pass_230.md` and
  `receipt_camera_cleanup_pass_log_archive_from_pass_231_to_pass_231.md` so the
  active cleanup log stays under the 500-line rule.
- Split initial attachment hydration out of `receipt_attachment_panel.dart`
  into `receipt_attachment_initial_state.dart`.
- Kept the shared receipt attachment widget shell, lifecycle hooks, build
  layout, recoverable capture banner, read status, attachment summary/list, and
  update guard in the original panel file.
- Reduced `receipt_attachment_panel.dart` from 341 lines to 291 lines; the new
  initial-state part is 54 lines.
- Updated the OCR-source handoff source bundle to include the new initial-state
  part because it asserts restored `attachment.readState` handling.

Failures fixed during this pass:
- First focused run failed because `receipt_camera_ocr_source_handoff_test.dart`
  read only `receipt_attachment_panel.dart` while expecting `attachment.readState`
  code moved into the initial-state part. Added the part and reran.

Verification:
- Rerun passed: `dart format`, targeted `dart analyze`, and focused
  `flutter test test/receipt_attachment_panel_actions_test.dart
  test/receipt_attachment_panel_recovery_contract_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart
  test/receipt_camera_help_flow_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_capture_flow_shareability_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
