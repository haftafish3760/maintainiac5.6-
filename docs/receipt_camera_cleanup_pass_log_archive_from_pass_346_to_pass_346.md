# Receipt Camera Cleanup Pass Log Archive - Pass 346

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line rule.

## Pass 346 - 11:22:05 EDT to 11:25:02 EDT

Scope:
- Split receipt entry line model conversion out of
  `expense_receipt_line_models.dart` into
  `expense_receipt_line_model_conversions.dart`.
- Kept blank/from-ledger construction, copy behavior, display/allocation labels,
  parser review labels, OCR source labels, and amount math in the model file.
- Reduced `expense_receipt_line_models.dart` from 377 lines to 344 lines; the
  new conversion extension is 37 lines.

Failures fixed during this pass:
- First focused Flutter run failed because the assisted-review source fixture
  omitted the parser telemetry metadata part added by an earlier split. Added
  that part to the fixture reader and reran the failed handoff test green.

Verification:
- Rerun passed targeted `dart analyze`, focused handoff/line/draft tests,
  source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
