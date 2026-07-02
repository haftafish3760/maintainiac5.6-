# Receipt Camera Cleanup Pass Log Archive - Pass 232

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project limit.

## Pass 232 - 08:16:54 EDT to 08:20:50 EDT

Scope:
- Archived active `Pass 211` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_211_to_pass_211.md`
  so the active cleanup log stays under the 500-line project limit.
- Split long-receipt native ghost overlay guidance out of
  `receipt_native_camera_shell_guidance.dart` into
  `receipt_native_camera_shell_ghost_guidance.dart`.
- Kept the main native camera guidance card and capability chips in the original
  guidance file.
- Reduced `receipt_native_camera_shell_guidance.dart` from 351 lines to 172
  lines; the new ghost-guidance part is 180 lines.
- Updated native shell/ghost source-contract tests to read the new part.

Verification:
- Focused `dart format`, targeted `dart analyze`, and these tests passed:
  `receipt_native_shell_recovery_contract_test.dart`,
  `receipt_native_ghost_warning_contract_test.dart`, and
  `receipt_native_camera_shell_test.dart`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed. Current receipt camera/OCR source footprint is
  250 files, 1.75 MB.
