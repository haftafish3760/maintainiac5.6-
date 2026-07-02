## Pass 160 - 06:17:48 EDT to 06:19:39 EDT

Scope:
- Split private telemetry sanitizer implementation out of
  `expense_screen_telemetry_policy.dart` into
  `expense_screen_telemetry_policy_sanitizers.dart`.
- Kept the public `ExpenseTelemetryPolicy` API, telemetry allow-lists, blocked
  sensitive keys, and metadata behavior unchanged.
- Reduced `expense_screen_telemetry_policy.dart` from 484 lines to 411 lines;
  the new sanitizer helper part is 80 lines.

Verification:
- `dart analyze` passed for the telemetry library, policy files, and focused
  telemetry/admin diagnostic tests.
- `flutter test test/expense_screen_telemetry_test.dart
  test/expense_admin_diagnostic_contract_test.dart
  test/expense_screen_telemetry_camera_health_test.dart -r compact` passed all
  focused tests.
- `dart run tool/maintainiac_source_audit.dart ... --max-line-length=220`
  passed for the touched files.
- `bash tool/receipt_fast_guard_gate.sh` passed.
- `git diff --check` passed.
