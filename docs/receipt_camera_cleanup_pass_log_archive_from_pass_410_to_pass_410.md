# Receipt Camera Cleanup Pass Log Archive - Pass 410

This archive keeps older receipt camera cleanup passes out of the active log so
each log file stays under the 500-line rule.

## Pass 410 - 13:17:08 EDT to 13:18:38 EDT

Scope:
- Wired `test/receipt_camera_footprint_audit_test.dart` into
  `tool/receipt_fast_guard_gate.sh` so the fast gate verifies the machine-readable
  footprint scope and PDF exclusion contract, not just the audit script output.
- Updated `receipt_fast_guard_gate_contract_test.dart` so the footprint audit
  contract test cannot be silently removed from the fast gate.

Verification:
- Passed `bash -n tool/receipt_fast_guard_gate.sh`.
- Passed focused `flutter test test/receipt_fast_guard_gate_contract_test.dart
  test/receipt_camera_footprint_audit_test.dart -r compact`.
- Passed updated `bash tool/receipt_fast_guard_gate.sh`, including scoped
  analyzer, source audits, I/O guard, footprint audit, footprint contract test,
  quality-gate contract test, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.68 MB.
