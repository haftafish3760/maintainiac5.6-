# Receipt Camera Cleanup Pass Log Archive - Pass 275

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line source guard.

## Pass 275 - 09:27:00 EDT to 09:28:37 EDT

Scope:
- Split staged-proof deletion, orphan proof cleanup, and old staged-file cleanup
  out of `receipt_proof_storage.dart` into `receipt_proof_storage_cleanup.dart`.
- Kept attachment persistence, staging, staged promotion, PDF validation, and
  immutable proof metadata updates in the original proof storage file.
- Reduced `receipt_proof_storage.dart` from 318 lines to 252 lines; the new
  cleanup part is 70 lines.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused native staging,
  recovery cleanup/index, and PDF proof-storage torture tests.
- Passed `bash tool/receipt_fast_guard_gate.sh` and `git diff --check`; the
  footprint audit still reports `total_receipt_camera_ocr_source` at 1.75 MB.
- The PDF torture storage fixture still prints known Helvetica font warnings,
  but exited green.
