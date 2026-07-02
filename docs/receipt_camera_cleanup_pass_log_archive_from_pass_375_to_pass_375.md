# Receipt Camera Cleanup Pass Log Archive - Pass 375

Archived from `receipt_camera_cleanup_pass_log.md` to keep the active cleanup
log under the 500-line file-size guard.

## Pass 375 - 12:09:00 EDT to 12:11:13 EDT

Scope:
- Strengthened the QA runner contract so every fixture must include exact
  merchant normalization checks.
- Added a contract rule that every line-item fixture must pin line
  descriptions, categories, parser families, and business/personal line use.
- This turns the recent fixture hardening into an ongoing standard for future
  receipt QA fixtures.

Verification:
- Passed `dart format`, focused
  `flutter test test/receipt_qa_runner_contract_test.dart -r compact`, and full
  `dart run tool/receipt_qa_runner.dart --fail-under=1.0` at 100.0% across 16
  fixtures.
- Passed `bash tool/receipt_fast_guard_gate.sh`, including source audit over
  497 receipt-scope files with no 500-line violations.
- Passed `git diff --check`; footprint remains
  `total_receipt_camera_ocr_source` at 1.74 MB.
