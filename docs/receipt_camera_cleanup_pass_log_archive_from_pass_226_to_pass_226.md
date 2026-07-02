# Receipt Camera Cleanup Pass Log Archive - Pass 226

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project limit.

## Pass 226 - 08:09:00 EDT to 08:11:06 EDT

Scope:
- Archived active Pass 205 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_205_to_pass_205.md` so the
  active cleanup log stays under the 500-line rule.
- Split native saved-photo warning diagnostics coverage out of
  `receipt_camera_quality_guidance_test.dart` into
  `receipt_camera_saved_photo_warning_diagnostics_test.dart`.
- Kept general receipt quality scoring, soft-vs-critical review guidance,
  action codes, bright-readable-paper handling, framing guidance, and readable
  weak-heuristic source contract coverage in the original quality test.
- Reduced `receipt_camera_quality_guidance_test.dart` from 399 lines to
  268 lines; the new saved-photo diagnostics test is 135 lines.

Verification:
- Passed: `dart format`, targeted `dart analyze`, focused `flutter test`, and
  `git diff --check` for both touched quality-guidance test files.
