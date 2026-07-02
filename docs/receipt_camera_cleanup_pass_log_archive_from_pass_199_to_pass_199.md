# Receipt Camera Cleanup Pass Log Archive - Pass 199

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active log under
the 500-line project limit.

## Pass 199 - 07:24:52 EDT to 07:28:40 EDT

Scope:
- Archived active `Pass 178` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_178_to_pass_178.md`
  so the active cleanup log stays under the 500-line project limit.
- Split photo preview rendering and zoom helpers out of
  `receipt_photo_review_surfaces.dart` into
  `receipt_photo_review_photo_surface.dart`.
- Updated review-screen source readers so source-contract tests still inspect
  the full review-screen library after the split.
- Reduced `receipt_photo_review_surfaces.dart` from 389 lines to 297 lines; the
  new photo-surface part is 95 lines.

Verification:
- First focused run failed on stale source-reader/assertion coverage after the
  split.
- Fixed settings/review source readers and adjacent-string assertions, then
  reran focused analyzer and tests successfully:
  `test/receipt_photo_review_controls_layout_test.dart`,
  `test/receipt_photo_review_exit_completion_test.dart`,
  `test/receipt_camera_help_flow_test.dart`,
  `test/receipt_camera_long_receipt_guidance_test.dart`, and
  `test/receipt_capture_settings_store_test.dart`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed.
