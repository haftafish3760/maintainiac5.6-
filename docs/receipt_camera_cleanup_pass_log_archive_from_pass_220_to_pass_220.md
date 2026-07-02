## Pass 220 - 07:58:19 EDT to 08:00:56 EDT

Scope:
- Archived active Pass 200 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_200_to_pass_200.md` so the
  active cleanup log stays under the 500-line rule.
- Split receipt crop handle hit targets, visible handle styling, and semantic
  labels out of `receipt_edge_cropper.dart` into
  `receipt_edge_cropper_handles.dart`.
- Kept image fitting, crop rectangle drag math, post-layout display callbacks,
  and crop overlay painting in the original cropper file.
- Reduced `receipt_edge_cropper.dart` from 361 lines to 211 lines; the new
  handle part is 153 lines.

Failures fixed during this pass:
- First focused test run failed because the cropper source-contract test read
  only `receipt_edge_cropper.dart`. Updated it to include the new handle part
  and reran the same focused checks.

Verification:
- Rerun passed: `dart format`, targeted `dart analyze`, and `flutter test
  test/receipt_photo_review_controls_layout_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the reader fix.
