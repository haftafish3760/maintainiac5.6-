# Receipt Camera Cleanup Pass Log Archive - Pass 407

This archive keeps older receipt camera cleanup passes out of the active log so
each log file stays under the 500-line rule.

## Pass 407 - 13:12:40 EDT to 13:13:58 EDT

Scope:
- Added scoped `dart analyze` coverage to `tool/receipt_fast_guard_gate.sh` for
  receipt capture, shared receipt contracts, expense export handoff, and expense
  telemetry.
- Updated `receipt_fast_guard_gate_contract_test.dart` so the fast gate cannot
  silently drop that analyzer coverage.

Why:
- The previous pipeline run caught a missing extension import only during the
  slower Android compile gate. The fast guard now catches that class of receipt
  import/type drift earlier.

Verification:
- Passed `bash -n tool/receipt_fast_guard_gate.sh`.
- Passed focused `flutter test test/receipt_fast_guard_gate_contract_test.dart
  -r compact`.
- Passed updated `bash tool/receipt_fast_guard_gate.sh`, including the new
  analyzer step, source audits, I/O guard, footprint audit, contract tests, and
  `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
