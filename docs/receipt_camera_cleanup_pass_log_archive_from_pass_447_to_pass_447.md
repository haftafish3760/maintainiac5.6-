# Receipt Camera Cleanup Pass Log Archive - Pass 447

Times are local to the development machine.

## Pass 447 - 15:14:50 EDT to 15:22:06 EDT

Scope:
- Stayed on pure Dart receipt QA hardening for damaged-image OCR readiness.
- Added a `damaged_ocr` QA fixture pack covering blur, glare/overbright source
  risk, partial crop, and weak low-contrast receipt text.
- Extended the QA runner so capture scoring checks real
  `ReceiptPhotoQualityCheck` outputs: primary issue, review action, retake gate,
  continue-with-review gate, needs-review gate, and warning presence.
- Updated `receipt_qa_runner_contract_test.dart` so the damaged OCR pack and
  photo-quality check names cannot be silently removed.
- Fixed a production photo-quality bug where a high numeric score could bypass
  review even when quality warnings such as poor framing were present.

Failures fixed during this pass:
- First damaged OCR runner pass failed because Pilot normalized to
  `Pilot Flying J`; updated the fixture expectation to the current parser output.
- The partial-crop fixture failed because `ReceiptPhotoQualityCheck.needsReview`
  ignored warning conditions after a high score. Changed the model so any
  quality warning requires review before the score shortcut can continue.

Verification:
- Passed targeted format and analyzer for the quality model, QA runner, and
  contract.
- Passed `dart run tool/receipt_qa_runner.dart --pack=damaged_ocr
  --fail-under=1.0 --summary-json`.
- Passed focused Flutter tests for receipt quality guidance, best-shot OCR
  quality behavior, and `receipt_qa_runner_contract_test.dart`.
- Passed full pure Dart runner summary with 23 fixtures, 613 checks, 613 passed,
  and 0 failed.
- Passed targeted source audit and `git diff --check`.
- Touched files remain under 500 lines.
