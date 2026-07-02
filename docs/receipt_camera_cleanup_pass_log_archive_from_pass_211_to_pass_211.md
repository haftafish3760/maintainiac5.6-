## Pass 211 - 07:43:49 EDT to 07:45:00 EDT

Scope:
- Split the interrupted native capture recovery banner out of
  `receipt_attachment_status_widgets.dart` into
  `receipt_interrupted_capture_banner.dart`.
- Kept receipt read status and proof-removal sheet widgets in the original
  status widget part.
- Updated the recovery contract source reader so the existing recovery-banner
  expectations follow the new part file instead of only reading the old status
  widget file.
- Reduced `receipt_attachment_status_widgets.dart` to 189 lines; the new
  banner part is 179 lines.

Verification:
- First focused test run failed because
  `receipt_attachment_panel_recovery_contract_test.dart` still read only the old
  status widget source and could not find `Resume Interrupted Receipt Photos`.
- Fixed that source-contract reader without removing behavior expectations.
- Rerun passed: `dart format`, targeted `dart analyze`, and `flutter test
  test/receipt_attachment_panel_recovery_contract_test.dart
  test/receipt_attachment_panel_actions_test.dart
  test/receipt_native_capture_recovery_record_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the fix.
