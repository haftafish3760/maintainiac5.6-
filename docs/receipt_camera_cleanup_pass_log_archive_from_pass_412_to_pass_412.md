# Receipt Camera Cleanup Pass Log Archive - Pass 412

This archive keeps older receipt camera cleanup passes out of the active log so
each log file stays under the 500-line rule.

## Pass 412 - 13:20:58 EDT to 13:21:39 EDT

Scope:
- Wired `bash tool/receipt_fast_guard_gate.sh` into
  `tool/receipt_quality_gate.sh` so the expensive receipt gate includes the fast
  gate's scoped analyzer, footprint scope, source audits, and contract checks.
- Added footprint-audit tooling and `receipt_camera_footprint_audit_test.dart`
  to the quality gate and its contract.

Failures fixed during this pass:
- First focused contract run failed because the quality-gate test expected the
  old one-line QA runner `flutter test` command. Updated the assertion to
  require `flutter test` and the test path separately, then reran green.

Verification:
- Passed `bash -n tool/receipt_quality_gate.sh tool/receipt_fast_guard_gate.sh`.
- Passed focused quality/fast/footprint contract Flutter tests.
- Passed `bash tool/receipt_fast_guard_gate.sh`, focused source audit,
  cleanup log gate, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.68 MB.
