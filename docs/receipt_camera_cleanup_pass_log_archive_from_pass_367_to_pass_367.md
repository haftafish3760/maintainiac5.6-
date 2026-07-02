# Receipt Camera Cleanup Pass Log Archive - Pass 367

Archived from the active cleanup log to keep the active file under the
500-line limit.

## Pass 367 - 11:53:43 EDT to 11:58:55 EDT

Scope:
- Split receipt entry line display/allocation/evidence computed fields out of
  `expense_receipt_line_models.dart` into
  `expense_receipt_line_computed_fields.dart`.
- Kept construction, ledger-line hydration, stored fields, `copyWith`, and
  rarely used source-contract labels in the original line model part.
- Reduced `expense_receipt_line_models.dart` from 343 lines to 229 lines; the
  new computed-fields extension is 117 lines.

Failures fixed during this pass:
- First analyzer run warned on unused private extension getters. Moved those
  source-contract getters back onto the class and reran analyzer green.
- First focused Flutter run exposed a fixture omission for
  `expense_receipt_entry_imported_text_parse_actions.dart`. Added that file to
  the assisted-review source fixture and reran the exact failed tests green.

Verification:
- Passed `dart format`, targeted `dart analyze`, focused assisted-review
  handoff/save-guardrail/receipt-line model tests, source audit, `bash
  tool/receipt_fast_guard_gate.sh`, and `git diff --check`.
- Footprint remains `total_receipt_camera_ocr_source` at 1.74 MB.
