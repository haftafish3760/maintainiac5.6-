# Receipt Camera Cleanup Pass Log Archive - Pass 201

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project rule.

## Pass 201 - 07:28:41 EDT to 07:30:34 EDT

Scope:
- Archived active `Pass 181` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_181_to_pass_181.md`
  so the active cleanup log stays under the 500-line project limit.
- Split the attachment summary card out of `receipt_attachment_list.dart` into
  `receipt_attachment_summary.dart`.
- Updated the multi-photo section-label source contract so it still includes
  the summary wording after the split.
- Reduced `receipt_attachment_list.dart` from 388 lines to 283 lines; the new
  summary part is 106 lines.

Verification:
- Focused verification passed on the first run: `dart format`, targeted
  `dart analyze`, and `flutter test test/receipt_photo_section_labels_test.dart
  test/receipt_attachment_panel_actions_test.dart
  test/receipt_attachment_panel_recovery_contract_test.dart -r compact`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed.
