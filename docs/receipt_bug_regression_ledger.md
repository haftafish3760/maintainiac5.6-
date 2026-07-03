# Receipt Bug Regression Ledger

Every confirmed receipt camera, OCR, parser, fixture, or review-flow bug gets a
ledger row before the fix is considered closed. Keep entries privacy-safe: no
raw receipt text, no customer data, no VINs, no plates.

Required fields for each entry:
- `Bug ID`
- `Category`
- `Symptom`
- `Root cause`
- `Fix`
- `Regression coverage`
- `Status`

Allowed categories:
- `camera_capture_quality`
- `multi_photo_ordering`
- `ghost_overlap_stitching`
- `source_preservation`
- `ocr_handoff_contract`
- `receipt_line_numbering`
- `receipt_line_review_mode`
- `business_personal_split`
- `parser_totals_math`
- `fixture_generation`
- `qa_harness`
- `privacy_redaction`
- `native_bridge`
- `storage_recovery`

| Bug ID | Category | Symptom | Root cause | Fix | Regression coverage | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `BUG-RECEIPT-0001` | `qa_harness` | Focused review-copy test looked for readiness copy in the wrong source bundle. | Static test assertion mixed the controls source bundle with the context-controls helper file. | Moved assertions to the source file that owns the readiness copy and reran the focused test. | `test/receipt_photo_review_quality_handoff_test.dart` | `closed` |
| `BUG-RECEIPT-0002` | `fixture_generation` | Contractor supply fixture expected compact item labels `Line 1..3` even though parser review labels preserve source receipt row numbers. | Fixture expectation treated parsed item index as receipt source line number and ignored merchant/date/continuation rows. | Updated contractor fixtures to expect source-line labels and added review-mode/line-label QA checks. | `tool/receipt_qa_runner.dart --pack=contractor_supply --fail-under=1.0 --summary-json`; `test/receipt_qa_runner_contract_test.dart` | `closed` |
