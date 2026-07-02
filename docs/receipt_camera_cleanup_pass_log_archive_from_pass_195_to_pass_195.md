# Receipt Camera Cleanup Pass Log Archive - Pass 195

Archived from the active cleanup log to keep
`docs/receipt_camera_cleanup_pass_log.md` under the 500-line file-size rule.

## Pass 195 - 07:20:47 EDT to 07:22:57 EDT

Scope:
- Archived active `Pass 174` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_174_to_pass_174.md`
  so the active cleanup log stays under the 500-line project limit.
- Split `ReceiptCaptureFlow.captureAndReview` implementation out of
  `receipt_capture_flow.dart` into
  `receipt_capture_flow_capture_and_review.dart`.
- Kept the public capture/review API stable while reducing
  `receipt_capture_flow.dart` to 62 lines; the new capture/review part is 337
  lines.

Verification:
- First focused run failed because source-contract tests still read only the
  old wrapper file or matched `_staging.stage` instead of `flow._staging.stage`.
- Updated those contract tests to read the flow library with parts and match the
  new delegated staging call.
- Rerun passed: `dart format`, targeted `dart analyze`, and `flutter test
  test/receipt_capture_flow_handoff_contract_test.dart
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_camera_capture_layout_test.dart -r compact`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed.
