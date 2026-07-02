# Receipt Camera Cleanup Pass Log Archive - Pass 417

This archive keeps older receipt camera cleanup passes out of the active log so
each log file stays under the 500-line rule.

## Pass 417 - 13:34:00 EDT to 13:39:00 EDT

Scope:
- Stayed on oversized receipt/OCR documentation cleanup and guardrails.
- Split `receipt_camera_ocr_master_pass_plan.md` from 32,721 lines into a
  264-line active index plus semantic archive files under the 500-line limit.
- Split oversized scoped OCR docs:
  `expense_command_center_ocr_contract.md`,
  `receipt_camera_ocr_pipeline_handoff_report.md`, and
  `receipt_camera_ocr_state_of_art_spec.md`.
- Added `tool/receipt_doc_size_gate.sh` and wired it into
  `tool/receipt_fast_guard_gate.sh` so scoped receipt/OCR docs cannot drift
  above 500 lines again.

Verification:
- Passed `bash tool/receipt_doc_size_gate.sh` across 88 scoped receipt/OCR docs.
- Passed `flutter test test/receipt_fast_guard_gate_contract_test.dart
  -r compact`.
- Passed updated `bash tool/receipt_fast_guard_gate.sh`, including the new doc
  size gate, scoped analyzer, source audits, I/O guard, footprint audit, and
  fast-gate contract tests.
