# Receipt Camera Cleanup Pass Log Archive - Pass 565

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active pass
log under the project line-count cap.

## Pass 565 - 08:02:25 EDT to 08:04:01 EDT

Scope:
- Hardened PDF receipt import duplicate checks so padded existing hashes or
  paths still match the newly staged PDF proof.
- Added source regression coverage for normalized current-form PDF duplicate
  hash and path comparisons.
- Recorded `BUG-RECEIPT-0081` under `source_preservation`.
- Archived Pass 515 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for PDF import actions and focused PDF
  import regression coverage.
- Passed focused Flutter regression
  `test/receipt_pdf_import_copy_test.dart --plain-name "PDF import copy keeps
  proof-only and app-fill choices clear"`.
