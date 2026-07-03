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
| `BUG-RECEIPT-0007` | `qa_harness` | Pipeline failure tasks could ask for a regression without requiring a bug ledger category or ledger row. | Regression task generation named a failure family but did not connect the task to the permanent categorized bug ledger. | Added suggested ledger categories and required `BUG-RECEIPT-####` ledger work to Dart and shell failure-task generators. | `test/receipt_pipeline_failure_to_regression_test.dart` | `closed` |
| `BUG-RECEIPT-0008` | `native_bridge` | Android and iOS auto-capture readiness thresholds could drift from the shared Flutter receipt camera session contract. | Stable-frame, motion, brightness, and cooldown thresholds were hardcoded in native camera code instead of being sent as session arguments. | Added shared auto-capture readiness thresholds to the Dart session contract, passed them through the native bridge, and made Android/iOS use the configured values. | `test/receipt_native_camera_session_contract_test.dart`; `test/receipt_native_android_bridge_auto_capture_test.dart`; `test/receipt_native_ios_bridge_settings_close_test.dart` | `closed` |
| `BUG-RECEIPT-0009` | `receipt_line_numbering` | OCR parser line drafts did not expose a source-first receipt line label for multi-section receipt review. | Draft labels kept parser index labels primary even when section/line source metadata was available. | Added `sourceFirstLineLabel` to parser line drafts and included it in local review and privacy-safe summary maps. | `test/receipt_ocr_service_parser_handoff_structure_test.dart` | `closed` |
| `BUG-RECEIPT-0010` | `privacy_redaction` | Client proof redaction plans that requested totals context could still hide subtotal lines. | Redaction planning added tax and total lines for totals context but skipped subtotal candidates. | Keep subtotal, tax, and total lines together whenever totals context is requested, while still hiding unselected item and payment lines. | `test/expense_receipt_parser_direct_parity_test.dart` | `closed` |
| `BUG-RECEIPT-0011` | `receipt_line_review_mode` | Multi-photo receipt handoff could downgrade detailed line review intent to prices-only when an earlier section reported `pricesOnly`. | Native review depth returned the first valid section diagnostic instead of preserving the most detailed requested review depth across sections. | Prefer `detailedLines` when any captured section requests it and expose review-depth counts in privacy-safe handoff metadata. | `test/receipt_camera_result_frozen_brain_install_test.dart` | `closed` |
| `BUG-RECEIPT-0012` | `business_personal_split` | Malformed in-memory split receipt percentages could produce impossible allocation totals such as more than 100% business or negative personal amounts. | Storage hydration clamped `businessPercent`, but direct model construction from parsers, adapters, or future sync could still feed unbounded values into derived totals and serialized maps. | Bound split percentages at derived math and serialization boundaries while keeping business/personal fixed at 100%/0%. | `test/expense_receipt_line_record_test.dart` | `closed` |
| `BUG-RECEIPT-0013` | `business_personal_split` | The active receipt entry review model could preview impossible split allocation totals before saving. | The entry draft line model used raw `businessPercent` in review labels and subtotal allocation math even though editor input and saved ledger records were bounded elsewhere. | Added bounded split percentage math to receipt entry computed fields so preview labels, business totals, and personal totals stay in range. | `test/expense_receipt_assisted_review_flow_test.dart` | `closed` |
| `BUG-RECEIPT-0014` | `business_personal_split` | A negative split percentage typed into the receipt line editor could be treated as a positive value. | The editor stripped every non-digit/non-decimal character before parsing, which removed the minus sign before range checks ran. | Preserve the sign while normalizing percent text, then clamp negative percentages to 0 and percentages above 100 to 100. | `test/expense_receipt_assisted_review_flow_test.dart` | `closed` |
| `BUG-RECEIPT-0015` | `camera_capture_quality` | Bogus non-finite native camera diagnostics could suppress bottom-of-receipt quality warnings. | Saved-photo warning diagnostics accepted `Infinity`/non-finite numeric values as readable luma or edge scores. | Treat non-finite native diagnostic numbers as missing evidence so bottom-dark and other quality warnings remain conservative. | `test/receipt_camera_saved_photo_warning_diagnostics_test.dart` | `closed` |
| `BUG-RECEIPT-0016` | `ocr_handoff_contract` | Saved-photo glare warnings could fall through to generic scanner-prep review instead of a specific glare action. | OCR source handoff review classified bottom, dark, and blur risks but did not map glare/washed-out saved-photo flags to a source-quality review status/action. | Added saved glare review detection and `reduce_glare_or_retake` handoff action. | `test/receipt_ocr_service_test.dart` | `closed` |
| `BUG-RECEIPT-0017` | `multi_photo_ordering` | Retake replacement paths with leading/trailing whitespace could bypass duplicate/current-section checks. | Replacement validation checked blank strings with `trim()` but compared raw paths for duplicate and current-photo collisions. | Reject unnormalized replacement paths before mutating receipt section order. | `test/receipt_photo_review_retake_order_test.dart` | `closed` |
| `BUG-RECEIPT-0018` | `ghost_overlap_stitching` | Non-finite manual overlap fractions could turn an unsafe stitch request into a generic stitch exception. | Manual overlap fraction conversion multiplied image height by untrusted non-finite values before the safe-range fallback check. | Treat non-finite manual overlap fractions as unsafe overlap input so stitching returns `manual_overlap_unsafe` and preserves ordered OCR sources. | `test/receipt_stitching_manual_overlap_test.dart` | `closed` |
| `BUG-RECEIPT-0019` | `source_preservation` | Stitched receipt handoff metadata said original sections were preserved but did not expose privacy-safe source counts to prove the stitched OCR artifact came from the expected section set. | The privacy-safe handoff metadata included source-preservation labels and pair counts, but omitted original-input count, OCR-source count, and overlap pixel totals. | Added privacy-safe stitch source counts and overlap totals without leaking raw file paths. | `test/receipt_camera_result_stitch_scanner_test.dart` | `closed` |
| `BUG-RECEIPT-0020` | `privacy_redaction` | Privacy-safe receipt line review/proof metadata could leak generated line IDs that contain item description text. | The line editor can build source IDs from typed descriptions, and privacy-safe contracts reused the raw source-of-truth `id`. | Use the deterministic redaction anchor as the privacy-safe line identifier while leaving the saved record ID unchanged. | `test/expense_receipt_line_record_test.dart` | `closed` |
