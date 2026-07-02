# Receipt Camera Cleanup Pass Log Archive - Pass 190

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line file-size rule.

## Pass 190 - 07:09:00 EDT to 07:12:50 EDT

Scope:
- Archived active Pass 168 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_168_to_pass_168.md` so the
  active cleanup log stays under the 500-line rule.
- Split native camera UI, close-capture, capture-source, surface, and receipt
  brain document/risk signal helpers out of
  `receipt_attachment_native_signal_helpers.dart` into
  `receipt_attachment_native_signal_documents.dart`.
- Updated source-level receipt camera tests and shared source readers so they
  include the new signal-document part where the moved contracts now live.
- Tightened two brittle source assertions to check source-visible adjacent
  string pieces instead of requiring one long literal.

Failures fixed during this pass:
- First focused Flutter run failed because source readers still looked only at
  the old native signal helper and because two copy assertions expected adjacent
  Dart strings as one source literal. Updated the readers/assertions and reran
  the same focused test group successfully.

Verification:
- Rerun passed: targeted `dart analyze`, focused source audit, and `flutter test
  test/receipt_camera_help_flow_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_camera_capture_layout_test.dart -r compact`.
- Fast receipt guard passed: `bash tool/receipt_fast_guard_gate.sh`.
- `git diff --check` passed.
- Touched files remain under 500 lines:
  `receipt_attachment_native_signal_helpers.dart` 201 lines,
  `receipt_attachment_native_signal_documents.dart` 202 lines,
  `receipt_camera_help_flow_test.dart` 285 lines, and
  `receipt_capture_flow_handoff_contract_test.dart` 394 lines.
