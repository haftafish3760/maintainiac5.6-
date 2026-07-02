# Receipt Camera Cleanup Pass Log Archive - Pass 289

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 289 - 09:56:21 EDT to 09:56:21 EDT

Scope:
- Split OCR source risk flag generation out of
  `receipt_attachment_ocr_source_signals.dart` into
  `receipt_attachment_ocr_source_risk_flags.dart`.
- Kept OCR source document-signal, coverage-decision, and continuation-signal
  builders in the original OCR source signals part.
- Added the new risk flag part to `receipt_attachment_panel.dart` and updated
  source-contract bundles that read OCR source signal files directly.
- Reduced `receipt_attachment_ocr_source_signals.dart` from 291 lines to 188
  lines; the new risk flag part is 108 lines.

Failures fixed during this pass:
- First focused Flutter run failed because handoff/source-contract tests still
  read only the old OCR source signal file and an old photo review surface
  bundle. Added `receipt_attachment_ocr_source_risk_flags.dart` and
  `receipt_photo_review_surface_controls.dart` to the relevant bundles, then
  reran.

Verification:
- Rerun passed `dart format`, targeted `dart analyze`, focused camera-help,
  capture-flow recovery, capture-flow handoff, and OCR source handoff tests.
- Passed `bash tool/receipt_fast_guard_gate.sh`, `git diff --check`, and the
  standalone `dart run tool/receipt_camera_footprint_audit.dart`; footprint
  remains `total_receipt_camera_ocr_source` at 1.75 MB.
