# Receipt Camera Cleanup Pass Log Archive - Pass 418

This archive keeps older receipt camera cleanup passes out of the active log so
each log file stays under the 500-line rule.

## Pass 418 - 13:40:00 EDT to 13:42:00 EDT

Scope:
- Stayed on formatter-projection guardrails for receipt/OCR source.
- Added `tool/receipt_formatter_projection_gate.sh` to run `dart format
  --output=show` over receipt Dart files and fail if any projected file exceeds
  500 lines.
- Wired the projection gate into `tool/receipt_quality_gate.sh` instead of the
  fast gate so deep quality checks catch compacted Dart files without slowing
  every fast guard pass.
- Updated `receipt_quality_gate_contract_test.dart` to keep the projection gate
  wired into the quality gate.

Verification:
- Passed `bash tool/receipt_formatter_projection_gate.sh` across 477 Dart files.
- Passed `flutter test test/receipt_quality_gate_contract_test.dart -r compact`.
- Passed targeted `git diff --check`.
