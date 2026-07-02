## Pass 218 - 07:52:53 EDT to 07:58:12 EDT

Scope:
- Archived active Pass 198 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_198_to_pass_198.md` so the
  active cleanup log stays under the 500-line rule.
- Split stitch-preview async work out of `receipt_photo_review_async_work.dart`
  into `receipt_photo_review_stitch_preview_async.dart`.
- Kept review lifecycle tokens, storage previews, quality checks, and data-saver
  preview work in the original async file.
- Updated shared source readers so source-contract tests include the new stitch
  async part and the previously split native staging safe-key part.
- Reduced `receipt_photo_review_async_work.dart` from 361 lines to 214 lines;
  the new stitch async part is 151 lines.

Failures fixed during this pass:
- First focused test run failed because source-contract readers did not include
  `receipt_photo_review_stitch_preview_async.dart`. Added the new part to both
  receipt photo review source readers and reran the same focused checks.

Verification:
- Rerun passed: `dart format`, targeted `dart analyze`, and `flutter test
  test/receipt_photo_review_async_lifecycle_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_photo_review_exit_completion_test.dart
  test/receipt_stitching_test.dart
  test/receipt_stitching_manual_overlap_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the reader fix.
