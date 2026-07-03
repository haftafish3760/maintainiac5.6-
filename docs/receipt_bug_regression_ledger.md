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
| `BUG-RECEIPT-0003` | `multi_photo_ordering` | Retake order planning could accept empty replacement paths, duplicate replacement paths, or a replacement path already used by another receipt section. | Replacement path validation only checked that the list was non-empty before rebuilding the ordered photo list. | Reject unsafe replacement path lists before order mutation. | `test/receipt_photo_review_retake_order_test.dart` | `closed` |
| `BUG-RECEIPT-0004` | `multi_photo_ordering` | Malformed native/recovery retake diagnostics with a final section before the original section were counted as ordinary retake metadata. | Section-order metadata counted positive retake section numbers but did not emit a privacy-safe invalid-order bucket. | Added invalid retake order buckets for final-before-original and preserved-slot-moved diagnostics. | `test/receipt_camera_result_stitch_scanner_test.dart` | `closed` |
| `BUG-RECEIPT-0005` | `ghost_overlap_stitching` | Previous-section ghost guide inputs could resolve to a zero-height or invisible/fully opaque overlay after generic 0..1 bounding. | Native session factory bounded values numerically but did not enforce visually usable ghost-slice minimums and maximums. | Added semantic bounds for source slice, overlay placement, overlay height, and opacity. | `test/receipt_native_camera_session_limits_test.dart` | `closed` |
| `BUG-RECEIPT-0006` | `source_preservation` | Duplicate saved proof or OCR source paths could inflate receipt section counts and handoff metadata. | Receipt review results trimmed blank paths but did not de-duplicate repeated paths while preserving order. | Added order-preserving unique path normalization for saved proof and OCR source path lists. | `test/receipt_camera_result_test.dart` | `closed` |
