# Receipt Camera Cleanup Pass Log Archive - Pass 271

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 271 - 09:20:52 EDT to 09:23:00 EDT

Scope:
- Split user-facing OCR warning labels, actions, review messages, and review target copy out of `receipt_ocr_warnings.dart` into `receipt_ocr_warning_labels.dart`.
- Kept warning kind, severity classification, priority ranking, and message parsing in the original warning model.
- Reduced `receipt_ocr_warnings.dart` from 322 lines to 108 lines; the new warning-labels part is 123 lines.

Verification:
- Passed focused `dart format`, targeted `dart analyze`, focused OCR warning/result/overlap tests, source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
