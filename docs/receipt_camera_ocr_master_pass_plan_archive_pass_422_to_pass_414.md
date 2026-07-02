# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 422 / Total Pass 502: Expense Parser Safe Line Identity Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 422 / Total Pass 502: Expense Parser Safe Line Identity Batch

Status: complete.

What changed:
- Carried OCR stable line identity into expense parser diagnostics as local
  parser data.
- Added parser diagnostics for stable OCR line ID count, ready item line ID
  count, review item line ID count, grouped line IDs by role, and parser bucket
  counts.
- Fed those fields from the OCR parser handoff when parsing a
  `ReceiptOcrResult`.
- Kept Command One/privacy telemetry content-free: event payloads and health
  snapshots receive aggregate counts and bucket totals only, not the individual
  `ocr_line_*` IDs and not receipt text, vendor names, item descriptions,
  addresses, or prices.
- Added privacy-safe health snapshot aggregation for stable line count,
  ready-item ID count, review-item ID count, and parser bucket counts.
- Added tests proving OCR parse diagnostics preserve safe local line identity,
  review-needed lines are counted, and privacy event payloads do not leak line
  IDs or receipt content.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "OCR|ocr"`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using the local line identity in the
  receipt review UI so ordered lines, review-needed lines, and business /
  personal / mixed classification can be shown and edited without confusing the
  user.

### Receipt Camera Reopen Pass 423 / Total Pass 503: Receipt Review Line Readiness UI Batch

Status: complete.

What changed:
- Updated the app-assisted receipt review intro panel to show practical OCR
  line-readiness guidance.
- Added chips for ready parser lines, lines that need checking, and ordered OCR
  line count.
- Kept the copy user-facing: the UI says ready/check/ordered lines instead of
  exposing internal parser IDs.
- The underlying parser can still use stable local OCR line identity from the
  previous passes, while Command One continues to receive aggregate counts and
  bucket statuses only.
- Added source guard coverage so the assisted review panel keeps the new line
  readiness labels tied to parser-ready, parser-review, and ordered-line
  diagnostics.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the business / personal /
  mixed classification controls line-aware so simple price-only mode and
  detailed mode can both classify OCR-filled lines cleanly.

### Receipt Camera Pass 495: Saved-Photo Parser Risk Health Aggregation

Status: complete.

What changed:
- Added `savedPhotoParserRiskCounts` to `ReceiptPhotoReviewResult` so saved
  photo warnings now produce parser-facing risk buckets such as
  `ocr_text_may_need_review`, `ocr_text_or_total_may_fail`,
  `ocr_item_prices_may_fail`, `ocr_bottom_total_may_fail`, and
  `ocr_bottom_lines_may_fail`.
- Added those parser-risk counts to the expense OCR-start metadata emitted from
  the receipt entry flow.
- Added `savedPhotoParserRiskCounts` and `topSavedPhotoParserRisk` to the
  expense telemetry health snapshot for future Command One visibility.
- Added the same fields to the Firestore summary sanitizer and redaction map so
  Command One can receive the aggregate without private receipt text, vendor
  names, prices, addresses, or notes.
- Updated focused tests for receipt result aggregation, camera layout source
  guards, local telemetry snapshots, and Firestore document schema parity.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`

Next camera/OCR focus:
- Continue parser handoff hardening by expanding line-level readiness signals:
  vendor/date/total/tax summary, priced-line extraction, parser-ready line
  counts, and inventory/material candidate readiness. Keep this privacy-safe:
  fixed codes and counts only, no raw receipt content.

### Receipt Camera Pass 496: OCR Parser Line Role Buckets

Status: complete.

What changed:
- Added grouped line-role counts to `ReceiptOcrParserHandoff`:
  `vendor`, `date`, `item`, `summary`, `tender`, `metadata`, and `other`.
- Added `dominantLineRole` to the parser handoff so downstream review and
  diagnostics can tell which kind of receipt line dominated the OCR output.
- Added the role-count buckets into `ReceiptOcrResult.parserSignalCounts` using
  fixed keys such as `itemRoleLineCount`, `summaryRoleLineCount`, and
  `metadataRoleLineCount`.
- Added `parserLineRoleCounts` and `dominantParserLineRole` to
  `ReceiptOcrDiagnostics`, so future expense/material/inventory parsing can use
  one shared receipt-line classification signal instead of rebuilding it.
- Extended OCR service tests to prove the Lowe's fixture produces item,
  summary, and metadata role counts without exposing receipt content in
  diagnostics.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue parser handoff hardening around line-item readiness: improve
  business/personal/mixed prep, price-only versus detailed-line mode handoff,
  and material/inventory candidate readiness without pulling inventory module
  code into the camera lane.

### Receipt Camera Pass 497: Expense Parser Role-Count Handoff

Status: complete.

What changed:
- Carried OCR parser line-role counts into `ExpenseReceiptParseDiagnostics`.
  The expense parser now receives role buckets for `vendor`, `date`, `item`,
  `summary`, `tender`, `metadata`, and `other`.
- Added `ocrDominantParserLineRole` and helper accessors so receipt review,
  future business/personal/mixed prep, and material/inventory parsing can use a
  shared classification signal.
- Propagated the role-count map from OCR results into privacy-safe receipt
  events and local Hive health summaries.
- Added `ocrParserLineRoleCounts` and `ocrDominantParserLineRoleCounts` to the
  privacy-safe Command One health snapshot. Empty dominant-role values are
  omitted rather than stored.
- Added tests proving the role-count handoff survives OCR result, expense parse
  diagnostics, privacy event payloads, and health snapshot aggregation without
  storing receipt text.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart --name "parser-ready|parser line signals|parser diagnostics|OCR parser|Lowe|privacy"`

Known validation note:
- A broader focused run of `test/receipt_ocr_service_test.dart`,
  `test/expense_receipt_parser_test.dart`, `test/receipt_privacy_event_test.dart`,
  and `test/receipt_privacy_event_store_test.dart` initially failed only because
  empty dominant parser roles were emitted. That was fixed by omitting empty
  dominant-role payload values, then the targeted privacy/parser validations
  passed.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is converting the role-count and
  readiness signals into clearer app-assisted receipt review decisions:
  price-only review, detailed review, business/personal/mixed prep, and
  material/inventory candidate readiness without touching the inventory module.

### Receipt Camera Pass 498: App-Assisted Review Readiness Guidance

Status: complete.

What changed:
- Added `_ReceiptAssistedReviewGuidance` to the expense receipt review UI.
- The app-assisted receipt review intro now derives review guidance from OCR
  diagnostics instead of showing only generic review copy.
- The intro can now surface:
  - `Price-first review` for simple amount-first review.
  - `Full-line review` for detailed item review.
  - `Business/Personal/Mixed ready` when line/price signals are safe enough.
  - `Classify receipt total` when only receipt summary signals are safe.
  - `Material review ready` or `Item signals found` when OCR line signals are
    useful for later material/inventory review.
- The no-line fallback copy now explicitly says to use the receipt total, add
  lines manually, or retake/add a clearer photo.
- Added source-level assisted review tests to guard the new labels and the
  parser-signal inputs (`parserReadinessStatus`, `pricedLineCount`).

Validation:
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue the receipt flow handoff by connecting the guidance to concrete
  state transitions: after accepted photo and OCR, land directly in review with
  the correct default mode and preserve unsaved photo/review state during
  interruptions.

### Receipt Camera Pass 499: Accepted Photo Review State Handoff

Status: complete.

What changed:
- Accepted receipt photo review now schedules a draft save before telemetry and
  scroll handoff. This helps preserve the accepted-photo review state if the
  user is interrupted after accepting a photo.
- Added `_receiptReviewModeChangedByUser` so parser-driven defaults do not
  override a review mode the user selected manually.
- Added `_applyDefaultReviewModeForParsedReceipt`.
- The parser now keeps normal receipts in simple price-first review by default,
  but automatically switches to detailed item review when:
  - the receipt flow is specialized, such as materials or maintenance/repair,
  - OCR found inventory/material prep signals,
  - parsed material lines exist,
  - maintenance hints exist.
- Existing scroll behavior remains intact: accepted photo and OCR completion
  continue to land the user in the app-assisted receipt review area.
- Added assisted-review guard tests for the draft save, manual-mode protection,
  and parser-driven detailed-review default.

Validation:
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue interruption hardening: verify which draft fields are actually
  restored after app restart/phone call interruption, then persist any missing
  accepted-photo and review-handoff fields needed to resume the receipt flow
  cleanly.

### Receipt Camera Reopen Pass 408 / Total Pass 488: Long Receipt Reason Handoff

Status: complete.

What changed:
- Added explicit long-receipt add-section reason fields to the shared native
  camera session contract:
  - `previousSectionReasonCode`
  - `previousSectionGuidance`
- Propagated the selected photo coverage decision from receipt photo review into
  the native camera relaunch path, so Add Another Photo carries why the user is
  adding a section instead of only carrying the previous photo path.
- Added the same reason/guidance fields to the reusable
  `ReceiptCaptureFlowOptions` path so materials, maintenance, and other future
  modules can call the shared receipt camera without duplicating camera logic.
- Sent the reason/guidance through the method-channel arguments and echoed a
  privacy-safe request-side reason into capture diagnostics even if a native
  platform does not echo it back.
- Added Android CameraX and iOS AVFoundation bridge storage for the reason code,
  plus diagnostics fields:
  - `previousSectionReasonCode`
  - `previousSectionGuidanceAvailable`

Privacy rule:
- The handoff stores reason codes and boolean guidance availability only. It
  does not store receipt text, item names, vendor text, addresses, phone numbers,
  or private receipt content.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening parser-ready line
  extraction evidence so vendor, total, tax, priced lines, and line-review
  reasons remain visible to the review screen and Command One without exposing
  private receipt content.

### Receipt Camera Reopen Pass 409 / Total Pass 489: Parser Readiness Status Buckets

Status: complete.

What changed:
- Added `ocrParserReadinessStatus` to the OCR parser handoff. It classifies the
  OCR-to-parser handoff without storing receipt content:
  - `no_text`
  - `missing_vendor`
  - `missing_total`
  - `no_priced_lines`
  - `no_item_lines`
  - `no_parser_ready_items`
  - `needs_review`
  - `receipt_ready`
  - `inventory_ready`
- Propagated the readiness status through expense parse diagnostics so the
  receipt review layer can explain why OCR output is or is not ready for
  assisted review.
- Added the status to privacy-safe receipt telemetry and local Hive health
  snapshots as aggregate counts, not raw receipt text.
- Preserved existing line-count diagnostics for vendor, priced lines, parser
  ready item lines, item review lines, subtotal, tax, total, tender, and metadata
  candidates.

Privacy rule:
- The new status is a safe bucket label. It does not contain vendor names, item
  descriptions, receipt text, addresses, phone numbers, notes, or prices.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using the parser readiness status in
  the assisted receipt review UI so the user sees clear next steps after OCR:
  review fields, add a missing section, retake, use total only, or classify
  business/personal/mixed.

### Receipt Camera Reopen Pass 410 / Total Pass 490: Parser Readiness Review UI

Status: complete.

What changed:
- Added parser-readiness summary copy to the OCR review box on the assisted
  receipt review screen.
- Merged parser-readiness action chips with receipt-structure action chips so
  the user gets concrete next steps after OCR:
  - review filled fields
  - classify Business/Personal/Mixed
  - check material matches
  - use receipt total
  - add line manually
  - retake or add photo
  - check store/total
  - review line prices
- Kept the labels content-free. They explain what failed or what needs review
  without exposing vendor names, item descriptions, prices, addresses, phone
  numbers, or receipt text.

Validation:
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is improving parser-readiness failure
  action routing so each action chip opens the most useful existing tool:
  capture panel, receipt total helper, manual line entry, or filled field review.

### Receipt Camera Reopen Pass 411 / Total Pass 491: Parser Readiness Action Routing

Status: complete.

What changed:
- Routed the new parser-readiness review chips to existing receipt-review
  actions:
  - `Review item lines`
  - `Check material matches`
- Both labels now scroll the user to the filled receipt review area instead of
  rendering as passive chips.
- Kept the behavior shared and non-inventory-specific. The camera/OCR flow
  still only exposes a generic material-match review action; inventory-specific
  import/update behavior remains outside this expense camera pass.

Validation:
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding parser-readiness status to
  failure diagnostics and operator-facing explanations so Command One can answer
  what failed: vendor, total, priced lines, item confidence, receipt order, or
  summary math.

### Receipt Camera Reopen Pass 412 / Total Pass 492: Parser Readiness Failure Causes

Status: complete.

What changed:
- Added exact parser-failure causes for OCR-to-parser readiness failures:
  - `receipt_ocr_missing_vendor`
  - `receipt_ocr_missing_total`
  - `receipt_ocr_no_priced_lines`
  - `receipt_ocr_no_item_lines`
  - `receipt_ocr_no_parser_ready_items`
  - `receipt_ocr_parser_readiness_review`
- Added matching `failedAt` workflow locations so Command One can show where the
  failure happened:
  - vendor handoff
  - total handoff
  - price handoff
  - item handoff
  - item confidence handoff
  - parser-readiness handoff
- Added privacy-safe evidence tokens for OCR readiness, ready-line count,
  review-signal count, priced-line count, and receipt-structure status.
- Added operator-facing recommended actions for the new causes inside expense
  telemetry. The recommendations explain what to fix without exposing receipt
  text, vendor names, line descriptions, prices, addresses, or phone numbers.

Validation:
- `flutter analyze lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_parser_failure_diagnostics_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is verifying these parser-readiness
  causes reach telemetry/Firestore/Command One summaries through the existing
  failure-diagnostic recorder without leaking private receipt content.

### Receipt Camera Reopen Pass 413 / Total Pass 493: Command One Readiness Propagation

Status: complete.

What changed:
- Added Firestore bridge coverage proving parser-readiness failure diagnostics
  are included in the queued expense health summary document.
- Verified the Command One summary can carry:
  - `receipt_ocr_no_parser_ready_items`
  - `ocr_to_parser_item_confidence_handoff`
  - the operator action explaining that OCR found item lines but none were safe
    enough to trust automatically.
- Verified the summary remains privacy-safe and does not include private receipt
  strings, vendor names, item names, or prices.
- Kept the summary as one bounded Firestore write, preserving the cost-control
  design for Command One health telemetry.

Validation:
- `flutter analyze test/expense_screen_telemetry_firestore_bridge_test.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart`
- `flutter test test/expense_screen_telemetry_firestore_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is capture-quality evidence: strengthen
  how bottom blur/darkness, exposure mismatch, and full-receipt coverage feed
  into OCR/parser readiness and user retake/add-section guidance.

### Receipt Camera Reopen Pass 414 / Total Pass 494: Saved Photo Parser Impact Guidance

Status: complete.

What changed:
- Added parser-impact guidance to native saved-photo review warnings.
- Bottom-dark and bottom-soft saved photos now explain the OCR/parser risk:
  - bottom total/tax/barcode/final lines may fail
  - lower item prices may be fuzzy
  - add a clearer bottom section before OCR review when needed
- Added safe risk codes for saved-photo warnings:
  - `ocr_bottom_total_may_fail`
  - `ocr_bottom_lines_may_fail`
  - `ocr_item_prices_may_fail`
  - `ocr_text_or_total_may_fail`
  - `ocr_washed_out_text_may_fail`
- Updated the photo review warning panel so the visible detail includes the
  parser-impact guidance, not just a generic quality warning.

Validation:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is connecting saved-photo parser-impact
  risk codes into telemetry/health counts so Command One can see bottom-dark,
  bottom-soft, glare, blur, and exposure-mismatch trends.
