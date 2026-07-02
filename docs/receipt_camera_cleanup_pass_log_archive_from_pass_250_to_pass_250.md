# Receipt Camera Cleanup Pass Log Archive - Pass 250

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 250 - 08:44:54 EDT to 08:49:03 EDT

Scope:
- Archived active Pass 229 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_229_to_pass_229.md` so the
  active cleanup log stays under the 500-line rule.
- Split photo attachment document-signal, risk-flag, diagnostic-signal,
  quality-score bucket, and attachment-signal token helpers out of
  `receipt_attachment_publish_helpers.dart` into
  `receipt_attachment_publish_signals.dart`.
- Kept attachment removal, clear-all, publish, settings, file-size, picker
  message, and attachment-to-quality conversion behavior in the original
  publish helper file.
- Reduced `receipt_attachment_publish_helpers.dart` from 341 lines to 195
  lines; the new publish-signals part is 150 lines.
- Updated attachment/source-contract tests that read publish helpers directly to
  include the new publish-signals part, and fixed one native staging source
  bundle to include the recovery-record part containing the expected copy.

Failures fixed during this pass:
- First focused run failed because `receipt_attachment_panel_recovery_contract_test.dart`
  read only the native staging entry file while expecting recovery copy from the
  recovery-record part. Added the part to that test source bundle and reran.

Verification:
- Rerun passed: `dart format`, targeted `dart analyze`, and focused
  `flutter test test/receipt_attachment_panel_recovery_contract_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart
  test/receipt_camera_help_flow_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_capture_flow_shareability_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
