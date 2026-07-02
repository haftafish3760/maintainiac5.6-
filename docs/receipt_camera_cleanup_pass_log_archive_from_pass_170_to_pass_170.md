# Receipt Camera Cleanup Pass Log Archive - Pass 170

This archive keeps the active receipt camera cleanup log under the 500-line
project limit while preserving the full pass history.

## Pass 170 - 06:35:43 EDT to 06:39:22 EDT

Scope:
- Split active receipt-entry line label helpers from
  `expense_receipt_line_models.dart` into `expense_receipt_line_labels.dart`.
- Kept low-use compatibility getters on the private line model to avoid unused
  private extension warnings.
- Restored the source-visible overlap guidance phrase
  `duplicates are not counted twice` in
  `expense_receipt_parse_review_guidance.dart`.

Verification:
- Initial focused `dart analyze` failed on unused private extension getters;
  moved those getters back to the model and reran.
- Focused `dart format`, `dart analyze`, and source audit passed for touched
  line-model and parse-review guidance files.
- Initial assisted overlap test failed because the overlap guidance phrase was
  split across adjacent source strings.
- Fixed that source contract, then `flutter test
  test/expense_receipt_assisted_review_flow_test.dart
  test/expense_receipt_assisted_review_save_guardrails_test.dart
  test/expense_receipt_assisted_review_overlap_native_test.dart -r compact`
  passed.
- `bash tool/receipt_fast_guard_gate.sh` passed after the repair.

Known follow-up:
- Continue reducing receipt-entry files while keeping source-contract phrases
  directly visible to QA.
