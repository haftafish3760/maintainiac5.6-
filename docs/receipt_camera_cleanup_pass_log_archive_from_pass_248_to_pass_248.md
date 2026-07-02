# Receipt Camera Cleanup Pass Log Archive - Pass 248

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 248 - 08:42:13 EDT to 08:44:53 EDT

Scope:
- Archived active Pass 227 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_227_to_pass_227.md` so the
  active cleanup log stays under the 500-line rule.
- Split camera/snackbar fallback copy, scanner fallback notice copy, native
  camera open-error copy, and storage-space dialog rendering out of
  `receipt_photo_review_capture_actions.dart` into
  `receipt_photo_review_capture_feedback.dart`.
- Kept add-photo, retake-photo, native camera, document scanner, and phone
  camera fallback flow in the original capture-actions file.
- Reduced `receipt_photo_review_capture_actions.dart` from 347 lines to 278
  lines; the new capture-feedback part is 72 lines.
- Updated receipt camera source readers that manually concatenate photo review
  save/capture action parts to include the new feedback part.

Verification:
- Passed: `dart format`, targeted `dart analyze`, and focused `flutter test
  test/receipt_camera_capture_layout_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_native_shell_recovery_contract_test.dart
  test/receipt_photo_review_exit_completion_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
