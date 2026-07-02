# Receipt Camera Cleanup Pass Log Archive - Pass 281

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 281 - 09:38:22 EDT to 09:41:01 EDT

Scope:
- Split parser line hints, confidence scoring, and review-reason copy out of
  `receipt_ocr_parser_line_signals.dart` into
  `receipt_ocr_parser_line_review.dart`.
- Kept line normalization, parser-line signal construction, and trait
  extraction in the original line-signals part.
- Reduced `receipt_ocr_parser_line_signals.dart` from 299 lines to 137 lines;
  the new parser-line review part is 163 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, and focused OCR parser-line,
  parser-ready, item-family, totals-coverage, and diagnostics-summary tests.
- Passed source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check`; footprint remains `total_receipt_camera_ocr_source` at
  1.75 MB.
