# Receipt Camera Cleanup Pass Log Archive - Pass 236

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line limit enforced by `tool/receipt_cleanup_log_gate.sh`.

## Pass 236 - 08:23:42 EDT to 08:25:43 EDT

Scope:
- Archived active `Pass 214` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_214_to_pass_214.md`
  so the active cleanup log stays under the 500-line project limit.
- Split previous-section long-receipt ghost guide policy getters out of
  `receipt_native_camera_session_config.dart` into
  `receipt_native_camera_session_ghost_guide.dart`.
- Kept general native camera session limits, storage safety, workload, exposure,
  focus, zoom, and control contract policy in the original session config.
- Reduced `receipt_native_camera_session_config.dart` from 350 lines to 282
  lines; the new ghost-guide extension is 72 lines.
- Updated the native camera contract source reader to include the new part.

Verification:
- Focused `dart format`, targeted `dart analyze`, and these tests passed:
  `receipt_native_camera_session_contract_test.dart`,
  `receipt_native_camera_session_limits_test.dart`,
  `receipt_native_camera_previous_section_channel_test.dart`,
  `receipt_native_ghost_warning_contract_test.dart`, and
  `receipt_native_camera_storage_contract_test.dart`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed. Current receipt camera/OCR source footprint is
  252 files, 1.75 MB.
