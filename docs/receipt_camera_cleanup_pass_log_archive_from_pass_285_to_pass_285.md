# Receipt Camera Cleanup Pass Log Archive - Pass 285

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 285 - 09:46:07 EDT to 09:48:45 EDT

Scope:
- Split parser-facing OCR result getters out of `receipt_ocr_result.dart` into
  `receipt_ocr_result_parser_views.dart`.
- Kept raw/parser text fields, warning priority, review messages, diagnostics,
  and processing snapshot on the core `ReceiptOcrResult` model.
- Preserved public getter usage such as `result.parserLineSignals`,
  `result.itemCandidateLines`, and `result.parserSignalCounts`.
- Reduced `receipt_ocr_result.dart` from 294 lines to 125 lines; the new parser
  views part is 132 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, and focused OCR result,
  parser-ready, line-signal, best-shot warning, and read-warning tests.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`; footprint remains `total_receipt_camera_ocr_source` at
  1.75 MB.
