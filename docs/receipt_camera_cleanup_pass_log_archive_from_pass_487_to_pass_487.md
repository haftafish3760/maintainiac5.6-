# Receipt Camera Cleanup Pass Log Archive - Pass 487

Archived out of `docs/receipt_camera_cleanup_pass_log.md` during Pass 500 to
keep the active cleanup log under the project line-count cap.

## Pass 487 - 00:07:47 EDT

Scope:
- Hardened receipt review source preservation so saved proof paths and OCR
  source paths are normalized with order-preserving de-duplication.
- Added a permanent source-preservation regression for duplicate saved proof and
  OCR source paths inflating receipt section counts and handoff metadata.
- Recorded `BUG-RECEIPT-0006` under `source_preservation` in the regression
  ledger.

Verification:
- Passed `dart format --set-exit-if-changed` for touched receipt model/test
  files.
- Passed targeted analyzer for the receipt review model, focused test, and bug
  ledger gate.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
- Passed focused `flutter test test/receipt_camera_result_test.dart --plain-name
  "photo review result removes duplicate saved and OCR source paths" -r compact`.
- Passed full focused `flutter test test/receipt_camera_result_test.dart -r
  compact`.

