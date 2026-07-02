# Receipt Camera Cleanup Pass Log Archive - Pass 426

Archived from `docs/receipt_camera_cleanup_pass_log.md` to keep the active log
under the 500-line project file limit.

## Pass 426 - 14:06:38 EDT to 14:09:25 EDT

Scope:
- Stayed on receipt/OCR-adjacent Firebase documentation and guardrails.
- Split oversized `docs/firebase_sync_schema_spec.md` into a 468-line main spec
  and a 344-line `firebase_sync_receipt_expense_schema_spec.md` for receipt,
  proof, expense, and OCR Command Center telemetry sync details.
- Added Firebase sync schema specs to `tool/receipt_doc_size_gate.sh` so this
  oversized-doc regression is guarded.
- Updated doc/source contract tests to read the split Firebase spec and the
  split Firestore document-builder parts.
- Restored compact active-contract coverage in
  `expense_command_center_ocr_contract.md` for OCR source buckets,
  `_ExpenseTelemetryFirestoreRedactor`, `actionSummary`, and the redacted token
  and count-map field sets.

Failures fixed during this pass:
- First focused contract run failed because the active OCR contract no longer
  contained the redactor name or OCR source bucket tokens. Added the compact
  redaction/source summary and reran the same batch green.

Verification:
- Passed `bash tool/receipt_doc_size_gate.sh` across 90 scoped docs.
- Passed targeted `dart analyze`, tests-only source audit, and targeted
  `git diff --check` for the split docs and contract tests.
- Passed focused OCR source, Firestore data model, redaction contract, and
  Firestore schema Flutter tests with 16 tests passing.
