# Receipt Camera Cleanup Pass Log Archive - Pass 172

This archive keeps the active receipt camera cleanup log under the 500-line
project limit while preserving the full pass history.

## Pass 172 - 06:39:27 EDT to 06:42:05 EDT

Scope:
- Split receipt recap line-classification guidance/checklist out of
  `expense_receipt_recap_classification.dart` into
  `expense_receipt_recap_classification_guidance.dart`.
- Updated the assisted-review source fixture so recap source assertions include
  the new guidance part.
- Reduced the recap classification file from 434 lines to 268 lines; the new
  guidance file is 167 lines.

Verification:
- `dart format`, focused `dart analyze`, and source audit passed for touched
  recap classification files and the assisted-review source fixture.
- `flutter test test/expense_receipt_assisted_review_flow_test.dart
  test/expense_receipt_assisted_review_save_guardrails_test.dart -r compact`
  passed.
- `bash tool/receipt_fast_guard_gate.sh` passed after the split.

Known follow-up:
- Continue reducing near-limit receipt/OCR entry files before adding more
  camera behavior.
