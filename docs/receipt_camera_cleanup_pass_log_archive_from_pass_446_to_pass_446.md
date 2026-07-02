# Receipt Camera Cleanup Pass Log Archive - Pass 446

Archived from the active cleanup pass log so
`docs/receipt_camera_cleanup_pass_log.md` stays under the 500-line cap.

## Pass 446 - 14:57:19 EDT to 15:13:43 EDT

Scope:
- Stayed on pure Dart receipt QA hardening for the camera/OCR device-storage
  requirement.
- Added a `device_tiers` QA fixture pack covering older-phone and critical
  storage receipt behavior.
- Extended `tool/receipt_qa_runner.dart` and `tool/receipt_qa_scoring_checks.dart`
  so device/storage scoring verifies real assistance-policy outputs: tier,
  parser depth, data-saver level, local photo count/bytes, assisted/best-shot
  limits, stitch pixel/height limits, optional pack bytes, cloud assist options,
  and auto-capture gating.
- Updated `receipt_qa_runner_contract_test.dart` so the new pack and budget
  check names cannot be silently removed.

Failures fixed during this pass:
- First analyzer wrapper failed because the shell used zsh's reserved `status`
  variable; reran with `rc`.
- First analyzer run found `ReceiptDataSaverLevel` was not imported by the
  runner; added the direct `receipt_capture_models.dart` import.
- Initial device-tier fixture expectations overreached into unrelated material
  category/family behavior; pinned the parser's current category/family output
  instead while keeping device budget checks strict.

Verification:
- Passed targeted format and `dart analyze` for the QA runner and contract.
- Passed `dart run tool/receipt_qa_runner.dart --pack=device_tiers
  --fail-under=1.0 --summary-json`.
- Passed `flutter test test/receipt_qa_runner_contract_test.dart -r compact`.
- Passed full pure Dart runner summary with 19 fixtures, 527 checks, 527 passed,
  and 0 failed.
- Passed targeted source audit, `git diff --check`, and trailing-whitespace
  check for the new device-tier fixture file.
- Touched files remain under 500 lines.
