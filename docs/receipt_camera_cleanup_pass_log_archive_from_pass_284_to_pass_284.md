## Pass 284 - 09:46:06 EDT to 09:46:06 EDT

Scope:
- Split receipt photo review bottom-control wiring, bottom-control height,
  continue-label logic, coverage-decision lookup, and bottom-padding helpers out
  of `receipt_photo_review_surfaces.dart` into
  `receipt_photo_review_surface_controls.dart`.
- Kept empty-review recovery and crop surface rendering in
  `receipt_photo_review_surfaces.dart`.
- Added the new surface-controls part to source-reader helpers so source
  contract tests still cover the moved max-height and bottom-control code.
- The surfaces file remains 119 lines after a concurrent stitch-surface split;
  the new surface-controls part is 117 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused camera-help,
  photo-review exit/completion, and native bridge layout tests.
- Passed `bash tool/receipt_fast_guard_gate.sh`, `git diff --check`, and the
  standalone `dart run tool/receipt_camera_footprint_audit.dart`; footprint
  remains `total_receipt_camera_ocr_source` at 1.75 MB.
