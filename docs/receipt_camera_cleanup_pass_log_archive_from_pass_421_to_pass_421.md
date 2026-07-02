# Receipt Camera Cleanup Pass Log Archive - Pass 421

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project file limit.

## Pass 421 - 13:55:31 EDT to 13:56:50 EDT

Scope:
- Stayed on reducing oversized Firestore/telemetry test files without changing
  behavior.
- Moved the expense telemetry sanitizer scalar and map-label tests out of
  `maintainiac_firestore_documents_test.dart` into
  `maintainiac_firestore_expense_telemetry_sanitizer_test.dart`.
- Moved the dedicated `_expenseTelemetrySnapshotForSanitizer` fixture helper
  with those tests so the broad Firestore document suite no longer carries that
  receipt/OCR telemetry fixture block.
- Reduced `maintainiac_firestore_documents_test.dart` from 2,046 lines to 1,653
  lines; the new focused sanitizer suite is 400 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, tests-only source audit, and
  targeted `git diff --check` for the split files.
- Passed focused `flutter test` for both affected Firestore telemetry test
  files with 21 tests passing.
