# Receipt Camera Cleanup Pass Log Archive - Pass 546

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
within the project line-count cap while preserving the pass history.

## Pass 546 - 05:17:20 EDT to 05:23:05 EDT

Scope:
- Hardened edited-photo review metadata so source-selection counts no longer
  duplicate the edit action bucket.
- Added regression coverage proving edited receipt copies report
  `edited_copy_selected` while edit actions still report `manual_crop`.
- Recorded `BUG-RECEIPT-0063` under `source_preservation`.
- Archived Pass 529 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer for native review signal aggregation and
  recovery metadata regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_recovery_metadata_test.dart`.
