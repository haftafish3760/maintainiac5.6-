## Pass 227 - 08:09:23 EDT to 08:12:27 EDT

Scope:
- Archived active `Pass 206` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_206_to_pass_206.md`
  so the active cleanup log stays under the 500-line project limit.
- Split the primary photo-review preview action row out of
  `receipt_photo_review_preview_controls.dart` into
  `receipt_photo_review_preview_primary_row.dart`.
- Kept multi-photo action rail, section-position chip, single-photo action row,
  and photo count badge in the original preview-controls file.
- Reduced `receipt_photo_review_preview_controls.dart` from 356 lines to 187
  lines; the new primary-row part is 170 lines.
- Updated source-contract readers that check long-receipt guidance, ghost guide
  copy, photo review layout, and OCR handoff flow to include the new part.

Verification:
- Focused `dart format`, targeted `dart analyze`, and these receipt camera tests
  passed: `receipt_camera_help_flow_test.dart`,
  `receipt_photo_review_quality_handoff_test.dart`,
  `receipt_photo_review_controls_layout_test.dart`,
  `receipt_native_ghost_warning_contract_test.dart`,
  `receipt_capture_flow_handoff_contract_test.dart`, and
  `receipt_camera_long_receipt_guidance_test.dart`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed. Current receipt camera/OCR source footprint is
  248 files, 1.75 MB.
