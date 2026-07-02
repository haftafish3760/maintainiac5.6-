# Receipt Camera Cleanup Pass Log Archive - Pass 239

Archived from the active receipt camera cleanup pass log so the active file
stays under the 500-line rule.

## Pass 239 - 08:28:47 EDT to 08:31:28 EDT

Scope:
- Archived active Pass 217 into
  `receipt_camera_cleanup_pass_log_archive_from_pass_217_to_pass_217.md` so the
  active cleanup log stays under the 500-line rule.
- Split preview action-tray status, source, memory policy, edited-photo, match,
  coverage, and native warning logic out of
  `receipt_photo_review_preview_action_tray.dart` into
  `receipt_photo_review_preview_action_status.dart`.
- Reduced `receipt_photo_review_preview_action_tray.dart` from 349 lines to 168
  lines; the new status extension part is 184 lines.
- Updated camera/OCR source readers and review-control tests so they include the
  new status part instead of missing moved copy and diagnostic logic.

Failures fixed during this pass:
- First focused run failed because source readers still expected moved copy in
  the tray file and one test still expected `_isPhoneCameraBackupCapture`.
- Rerun then failed on stale private getter expectations for
  `_captureMemoryPolicyCopy`, `_editedPhotoCopy`, and
  `_multiPhotoMatchStatusCopy`.
- Updated the source bundles and expectations to the new extension getter names,
  then reran the same focused verification successfully.

Verification:
- Rerun passed: `dart format`, targeted `dart analyze`, and `flutter test
  test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart
  test/receipt_photo_review_controls_layout_test.dart
  test/receipt_capture_flow_handoff_contract_test.dart
  test/receipt_native_ghost_warning_contract_test.dart
  test/expense_receipt_assisted_review_handoff_native_test.dart -r compact`.
- Source audit, `bash tool/receipt_fast_guard_gate.sh`, and `git diff --check`
  passed after the split.
