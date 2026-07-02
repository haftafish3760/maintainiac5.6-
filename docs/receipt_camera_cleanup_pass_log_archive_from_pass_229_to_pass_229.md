## Pass 229 - 08:12:28 EDT to 08:16:53 EDT

Scope:
- Archived active `Pass 208` into
  `docs/receipt_camera_cleanup_pass_log_archive_from_pass_208_to_pass_208.md`
  so the active cleanup log stays under the 500-line project limit.
- Split native capture recovery record parsing, freshness, storage-status, and
  privacy-safe recovery evidence labels out of
  `receipt_native_capture_staging.dart` into
  `receipt_native_capture_staging_recovery_record.dart`.
- Reduced `receipt_native_capture_staging.dart` from 352 lines to 74 lines; the
  new recovery-record part is 280 lines.
- Updated source readers for staging and interrupted-capture banner contracts.
- Fixed recovery close-action copy back to user-facing `Next` wording instead
  of `Done`, preserving the no-silent-discard review contract.

Verification:
- Focused `dart format`, targeted `dart analyze`, and these tests passed after
  reader/copy fixes: `receipt_native_capture_staging_test.dart`,
  `receipt_native_capture_recovery_index_test.dart`,
  `receipt_native_capture_recovery_record_test.dart`,
  `receipt_native_shell_recovery_contract_test.dart`,
  `receipt_photo_review_exit_completion_test.dart`, and
  `receipt_native_ghost_warning_contract_test.dart`.
- Focused source audit, `bash tool/receipt_fast_guard_gate.sh`, and
  `git diff --check` passed. Current receipt camera/OCR source footprint is
  249 files, 1.75 MB.
