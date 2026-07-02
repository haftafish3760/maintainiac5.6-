# Receipt Camera Cleanup Pass Log Archive - Pass 287

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 287 - 09:52:00 EDT to 09:53:01 EDT

Scope:
- Split async PDF proof preview/raster work out of
  `receipt_pdf_viewer_body.dart` into `receipt_pdf_viewer_preview_async.dart`.
- Kept proof warning, preview-plan notice, preview-limit notice, and rendered
  page widget layout in the viewer body.
- Updated `receipt_camera_io_guard.dart` so the approved PDF preview
  `readAsBytes()` site follows the new async preview part.
- Reduced `receipt_pdf_viewer_body.dart` from 293 lines to 222 lines; the new
  preview async part is 75 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused PDF viewer hardening
  and PDF hardening tests, and `dart run tool/receipt_camera_io_guard.dart`.
- Passed `bash tool/receipt_fast_guard_gate.sh`, `git diff --check`, and the
  standalone `dart run tool/receipt_camera_footprint_audit.dart`; footprint
  remains `total_receipt_camera_ocr_source` at 1.75 MB.
- The focused PDF fixture tests still print the known Helvetica warning, but
  exited green.
