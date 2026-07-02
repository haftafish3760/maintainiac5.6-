## Pass 154 - 06:08:02 EDT to 06:11:39 EDT

Scope:
- Split `PrivacySafeReceiptEvent` factory construction out of
  `expense_receipt_privacy_event.dart` into
  `expense_receipt_privacy_event_factories.dart`.
- Kept the public factory constructors on `PrivacySafeReceiptEvent`; they now
  delegate to private helpers in the new part.
- Reduced `expense_receipt_privacy_event.dart` from 497 lines to 299 lines;
  the new factory helper part is 260 lines.
- Archived active Pass 139 before logging to keep the active cleanup log below
  the 500-line rule.

Failures fixed during this pass:
- The first replacement left stale duplicate factory/field content in the
  model file. The duplicate tail was removed before analyzer or tests were
  allowed to pass.
- Redirecting factories were corrected to normal factory bodies because Dart
  redirecting factories must target constructors, not top-level helpers.

Verification:
- `dart analyze` passed for the parser library, privacy event parts, and
  focused privacy event tests.
- `flutter test test/receipt_privacy_event_test.dart
  test/receipt_privacy_event_capture_handoff_test.dart -r compact` passed all
  focused privacy event tests.
- `dart run tool/maintainiac_source_audit.dart ... --max-line-length=220`
  passed for the touched files.
- `bash tool/receipt_fast_guard_gate.sh` passed.
- `git diff --check` passed.
