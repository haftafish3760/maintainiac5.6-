# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 627: Client-Proof Review Summary Contract Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 627: Client-Proof Review Summary Contract Batch

Status: complete.

What changed:
- Added `ReceiptClientProofReviewSummary` as a content-free downstream contract
  for client-safe receipt proof review/export screens.
- Derived share readiness, hidden-line count, review-line count, source-section
  count, and recommended next action from the redaction plan.
- Exposed the summary from parsed work-supply receipt drafts so future
  job/estimate/invoice intake can consume one stable contract.
- Added regression coverage proving the summary omits receipt text, merchant
  names, item descriptions, and prices.

Validation:
- `dart format lib/shared/receipts/receipt_processing_contract.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`

### Receipt Camera Reopen Pass 626: Client-Proof Redaction-Plan Privacy Event History Batch

Status: complete.

What changed:
- Added content-free client-proof redaction plan status and line-count fields
  to privacy-safe receipt events.
- Aggregated those fields in receipt privacy event health snapshots.
- Kept local diagnostic history aligned with Command One without storing
  receipt text, merchant names, item descriptions, prices, or customer content.
- Added regression coverage for event payloads and privacy health snapshots.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

### Receipt Camera Reopen Pass 625: Client-Proof Redaction-Plan Command One Telemetry Batch

Status: complete.

What changed:
- Added content-free telemetry keys for client-proof redaction plan status,
  visible line count, hidden line count, and review-required line count.
- Aggregated redaction-plan status/counts into expense telemetry health snapshots
  and Command One maps.
- Kept the new fields privacy-safe: they expose only status/counts, not receipt
  text, merchant names, item descriptions, line prices, or customer content.
- Extended Command One OCR handoff tests and receipt camera metadata allowlist
  coverage for the new redaction-plan fields.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "OCR source handoff buckets|receipt camera health metadata"`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart test/receipt_privacy_event_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/receipts/receipt_processing_contract.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_screen_telemetry_test.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart test/receipt_privacy_event_test.dart`

### Receipt Camera Reopen Pass 624: Client-Proof Redaction Plan Contract Batch

Status: complete.

What changed:
- Added a shared client-proof redaction action contract for `show`, `hide`, and
  `review` line states.
- Added `ReceiptClientProofRedactionLine` and
  `ReceiptClientProofRedactionPlan` so downstream UI/export code can render
  visible, hidden, and review-required receipt lines before anything is shared.
- Derived redaction plans from selected receipt-line bundles while keeping
  privacy-safe maps free of receipt text, merchant names, item descriptions, and
  prices.
- Exposed `clientProofRedactionPlan` from parsed work-supply/material receipt
  drafts.
- Added regression coverage for selected, excluded, review-required, and hidden
  line counts.

Validation:
- `dart format lib/shared/receipts/receipt_processing_contract.dart test/receipt_processing_contract_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart test/receipt_processing_contract_test.dart`
- `flutter test test/receipt_processing_contract_test.dart`
- `dart format lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_processing_contract_test.dart test/work_supply_parsed_receipt_bridge_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`

### Receipt Camera Reopen Pass 623: Parsed Materials Selection Privacy-Event Builders Batch

Status: complete.

What changed:
- Added `inventorySelectionPrivacyEvent` and `clientProofSelectionPrivacyEvent`
  builders to parsed work-supply/material receipt drafts.
- Downstream materials, job, estimate, invoice, and client-proof screens can now
  emit privacy-safe selected-line events directly from the parsed draft without
  duplicating selection-count logic.
- Added regression coverage proving the generated events expose only purpose and
  count fields while keeping merchant names, line descriptions, and receipt text
  out of the payload.

Validation:
- `dart format lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter analyze lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/work_supply_parsed_receipt_bridge_test.dart test/receipt_privacy_event_test.dart`
- `flutter test test/work_supply_parsed_receipt_bridge_test.dart test/receipt_processing_contract_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/work_supply_parsed_receipt_bridge_test.dart test/receipt_processing_contract_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`

### Receipt Camera Reopen Pass 622: Selected-Line Privacy Event History Batch

Status: complete.

What changed:
- Added selected-line purpose, selected-line count, excluded-line count,
  client-proof review count, and redacted-line count to privacy-safe receipt
  events.
- Added `PrivacySafeReceiptEvent.fromLineSelectionBundle` so future job,
  invoice, estimate, inventory, and client-proof flows can record line-selection
  health without receipt text.
- Added privacy event store allowlisting and health aggregation for selected
  receipt-line counts and purposes.
- Added regression coverage proving selected-line privacy events and privacy
  health snapshots do not expose merchant names, item descriptions, or prices.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`

### Receipt Camera Reopen Pass 621: Selected-Line Command One Telemetry Promotion Batch

Status: complete.

What changed:
- Added allowlisted metadata keys for selected receipt-line purpose, selected
  line counts, excluded line counts, client-proof review counts, and redacted
  line counts.
- Aggregated those keys through OCR/parser health snapshots so Command One can
  see selected/excluded/redaction-review line health without private receipt
  content.
- Added Command One map fields for selected-line purpose counts, total selected
  lines, total excluded lines, review-before-share line counts, redacted line
  counts, and top selected-line purpose.
- Extended telemetry tests proving the new fields remain content-free and are
  visible in the admin health summary.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "OCR source handoff buckets"`
- `flutter test test/expense_screen_telemetry_test.dart --name "receipt camera health metadata"`
- `flutter test test/expense_screen_telemetry_test.dart`

### Receipt Camera Reopen Pass 620: Parsed Materials Receipt Selection Bundles Batch

Status: complete.

What changed:
- Added ready-made `inventorySelectionBundle` and `clientProofSelectionBundle`
  fields to parsed work-supply/material receipt drafts.
- Inventory bundles include only actual inventory/material lines so stock,
  vehicle inventory, job costing, or estimate flows do not need to rebuild line
  selection rules.
- Client-proof bundles use the shared default redaction rules: personal lines are
  excluded, split lines require review, and business/inventory lines remain
  reviewable for proof.
- Added regression coverage proving parsed materials receipts expose selected
  line counts, excluded-line counts, and privacy-safe client-proof maps without
  leaking merchant/item content.

Validation:
- `dart format lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter analyze lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/work_supply_parsed_receipt_bridge_test.dart test/receipt_processing_contract_test.dart`
- `flutter test test/receipt_processing_contract_test.dart test/receipt_line_models_test.dart test/work_supply_parsed_receipt_bridge_test.dart test/work_supply_receipt_staging_test.dart test/expense_materials_receipt_bridge_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart lib/shared/receipts/receipt_line_models.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_processing_contract_test.dart test/receipt_line_models_test.dart test/work_supply_parsed_receipt_bridge_test.dart`

### Receipt Camera Reopen Pass 619: Selected Receipt-Line Bundle Contract Batch

Status: complete.

What changed:
- Added shared receipt-line selection purposes for expense, inventory, estimate,
  job, invoice, and client-proof workflows.
- Added `ReceiptSelectedLineReference` so downstream flows can carry selected
  receipt ids, stable line ids, proof labels, visibility rules, business use,
  and local totals.
- Added `ReceiptLineSelectionBundle` so multi-receipt job/invoice/materials
  workflows can track selected lines, excluded lines, redaction defaults,
  review-before-share counts, and local selected totals.
- Added privacy-safe bundle maps that expose line references and status/count
  flags without receipt text, merchant names, item descriptions, or prices.
- Added regression coverage for local totals versus privacy-safe line-reference
  output.

Validation:
- `dart format lib/shared/receipts/receipt_processing_contract.dart test/receipt_processing_contract_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart test/receipt_processing_contract_test.dart`
- `flutter test test/receipt_processing_contract_test.dart`
- `flutter test test/receipt_processing_contract_test.dart test/receipt_line_models_test.dart test/work_supply_parsed_receipt_bridge_test.dart test/work_supply_receipt_staging_test.dart test/expense_materials_receipt_bridge_test.dart`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart lib/shared/receipts/receipt_line_models.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_processing_contract_test.dart test/receipt_line_models_test.dart test/work_supply_parsed_receipt_bridge_test.dart`

### Receipt Camera Reopen Pass 618: Receipt-Line Proof Selection Contract Batch

Status: complete.

What changed:
- Added a shared client-proof visibility contract to `ReceiptLineDraft` so
  downstream modules can tell whether a line is reviewed for proof, reviewed
  before sharing, or hidden by default.
- Added stable proof labels, source-section labels, and privacy-safe proof
  reference maps that expose line ids, labels, visibility, and status flags
  without exposing receipt text, merchant names, item descriptions, or prices.
- Wired parsed work-supply/material receipt drafts so business/inventory lines
  default to client-proof review, split lines require review before sharing, and
  personal lines are hidden by default.
- Added regression coverage for privacy-safe proof references and parsed
  materials line visibility.

Validation:
- `dart format lib/shared/receipts/receipt_line_models.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_line_models_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter analyze lib/shared/receipts/receipt_line_models.dart lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart test/receipt_line_models_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/receipt_line_models_test.dart test/work_supply_parsed_receipt_bridge_test.dart`
- `flutter test test/expense_materials_receipt_bridge_test.dart test/work_supply_receipt_staging_test.dart test/work_supply_parsed_receipt_bridge_test.dart test/receipt_line_models_test.dart`

### Receipt Camera Reopen Pass 617: Parser-Pack Command One Telemetry Promotion Batch

Status: complete.

What changed:
- Promoted parser-pack disclosure fields into expense telemetry health snapshots
  and Command One maps.
- Added content-free buckets for parser-pack codes, optional local download pack
  codes, cloud fallback pack codes, parser-pack accuracy bands, and optional
  local pack byte totals.
- Kept the admin surface privacy-safe: no receipt text, merchant names, item
  descriptions, prices, addresses, or customer data are exposed.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "receipt camera health metadata"`
- `flutter test test/expense_screen_telemetry_test.dart --name "builds command center summary"`

### Receipt Camera Reopen Pass 616: Local/Cloud Parser-Pack Disclosure Policy Batch

Status: complete.

What changed:
- Added parser-pack disclosure objects for the receipt OCR/parser policy so the
  app can identify included local packs, optional local downloads, cloud
  fallbacks, estimated local pack size, and target accuracy bands.
- Kept the baseline receipt OCR local by default while making heavier line-item,
  materials, inventory, regional, and cloud assist paths explicit choices.
- Preserved structured parser-pack diagnostics through native capture staging
  instead of flattening accuracy-band maps into one string.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart`

### Receipt Camera Reopen Pass 615: Client-Proof Redaction Diagnostics Handoff Batch

Status: complete.

What changed:
- Connected the OCR redaction contract to receipt diagnostics and privacy-safe
  receipt events.
- Carried client-proof redaction status and visibility counts into parser
  telemetry so Command One can summarize redaction readiness without receipt
  text.
- Kept local customer-proof line contracts separate from Command One-safe
  client-proof telemetry vocabulary.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr parser handoff exposes local line drafts"`
- `flutter test test/receipt_privacy_event_test.dart`
- `flutter test test/receipt_privacy_event_store_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "OCR source handoff buckets"`

### Receipt Camera Reopen Pass 614: Client-Proof Redaction Telemetry And Accuracy-Pack Rule Batch

Status: complete.

What changed:
- Added privacy-safe Command One aggregation for client-proof redaction status
  and redaction visibility buckets.
- Kept telemetry vocabulary free of private receipt terms that existing privacy
  tests reject, using `clientProof...` status/count fields instead of customer
  content language.
- Captured the local baseline, optional heavy local OCR/parser packs, cloud OCR
  assist, regional/vendor packs, and category accuracy-disclosure rule in the
  master receipt/OCR plan.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "OCR source handoff buckets"`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 613: Customer-Proof Redaction Line Reference Contract Batch

Status: complete.

What changed:
- Added privacy-safe OCR line-reference metadata for customer proof/redaction
  flows: stable line ids, line numbers, source section labels, and default
  customer-proof visibility buckets.
- Added a `receipt_customer_proof_redaction_v1` contract so jobs, invoices,
  estimates, inventory/materials, and expenses can reference exact receipt lines
  without exposing receipt text in Command One summaries.
- Marked tender/payment and metadata lines as redact-by-default candidates while
  leaving item/header/summary lines as review-for-customer-proof candidates.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr parser handoff exposes local line drafts"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 612: Scanner-Prep Command One Handoff Telemetry Coverage Batch

Status: complete.

What changed:
- Added Command One/expense health coverage for the
  `scanner_prep_review_needed` OCR-source handoff status.
- Verified scanner-prep review status, cleanup-skipped scanner decisions, and
  cleanup-skipped OCR-source risk counts aggregate into the health snapshot
  without receipt content.
- Captured the multi-receipt job/invoice/inventory customer-redaction edge case
  as a formal camera/OCR/parser requirement.

Validation:
- `dart format test/expense_screen_telemetry_test.dart`
- `flutter analyze test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "OCR source handoff buckets"`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 611: Scanner-Prep Handoff Status Batch

Status: complete.

What changed:
- Added a dedicated `scanner_prep_review_needed` OCR-source handoff status for
  quality-guard, decode-failed, and skipped-cleanup scanner preparation risks.
- Kept stitched and fallback receipt states higher priority, but prevented
  scanner-prep risk cases from being summarized as a plain ready receipt.
- Reused the same scanner-prep risk classifier for user-facing OCR warnings and
  privacy-safe handoff status so diagnostics stay consistent.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "scanner prep"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 610: Scanner-Prep Decode/Skipped Warning Coverage Batch

Status: complete.

What changed:
- Added focused OCR coverage for scanner preparation risks beyond
  quality-guard cases.
- Verified `ocr_source_decode_failed_*` and `ocr_source_*_skipped_*` risks both
  surface the same user-facing image-cleanup review warning.
- Verified those risks remain privacy-safe OCR source counts and classify as
  photo-quality review warnings.

Validation:
- `dart format test/receipt_ocr_service_test.dart`
- `flutter analyze test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "scanner prep"`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 609: Scanner-Prep OCR Review Guidance Batch

Status: complete.

What changed:
- Scanner preparation risks from receipt image cleanup now surface as
  user-review OCR warnings instead of staying only as hidden OCR-source risk
  flags.
- Added guidance for quality-guard, decode-failed, and skipped-cleanup
  OCR-source risks: OCR uses the safest available source, but the saved receipt
  text should be checked before saving.
- Classified the new scanner-prep guidance as a photo-quality warning and added
  focused coverage proving the warning and privacy-safe risk count are emitted.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "scanner prep"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 608: Native Camera Diagnostic Naming Cleanup Batch

Status: complete.

What changed:
- Removed misleading `flutter_camera_native_backend` and stale
  `camerax_native_bridge` fixture labels from receipt camera result tests.
- Aligned diagnostic fixtures with the actual native bridge payload names:
  `maintainiac_native_android` and `maintainiac_native_ios`.
- Added a source guard so the old Flutter-camera engine label cannot quietly
  return to receipt camera result coverage.

Validation:
- `dart format test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt import uses Maintainiac native camera"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`
