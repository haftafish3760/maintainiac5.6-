# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 508: Photo Review Next Contract Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 508: Photo Review Next Contract Batch

Status: complete.

What changed:
- Continued receipt camera/OCR flow work only.
- Tightened the photo-review contract so the post-capture screen makes the
  next action clear: Next opens the filled receipt review, where the user checks
  store, date, tax, total, item prices, and Business/Personal/Mixed.
- Added visible single-photo review copy that says `Tap Next for filled receipt
  review` instead of leaving the user to infer what happens after accepting a
  photo.
- Extended the layout source guard so single-photo, multi-photo, saved-photo,
  and accepted-photo import paths must keep the same filled-review handoff
  language and OCR-read startup order.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "post-capture quality copy leads with action and evidence"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening the actual accepted-photo
  route so pressing Next after photo review starts OCR/read status and lands on
  filled receipt review, not the add-expense attachment start.

### Receipt Camera Reopen Pass 509: Persistent Filled Review Handoff Batch

Status: complete.

What changed:
- Continued receipt camera/OCR flow work only.
- Added `_shouldShowReceiptReadHandoffPanel` so the accepted-photo handoff does
  not disappear immediately when OCR/parser work finishes.
- Kept the handoff panel visible after accepted-photo OCR when it has saved
  proof counts, OCR source counts, a route decision, an action label, or a
  coverage warning.
- Updated the handoff panel to switch from `Reading Receipt Details` to
  `Filled Receipt Review Ready` once the receipt review is ready.
- Added ready-state copy telling the user to review what Maintainiac filled in:
  store, date, total, tax, item prices, and Business/Personal/Mixed choices.
- Added assisted-review source guards proving the handoff panel is not tied
  only to `_scanningReceiptPhotos` and that ready-state copy stays in place.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is parser line identity and line-item
  readiness: vendor/date/tax/total/item-price lines need stable local IDs and
  review flags so inventory/material parsing can reuse the same OCR foundation
  later without touching inventory implementation now.

### Receipt Camera Reopen Pass 510: Parser Task Line-ID Handoff Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser foundation work only.
- Added `parserTaskLineIds` to the OCR parser handoff so downstream parsers can
  tell which stable local OCR lines are vendor candidates, date candidates,
  subtotal/tax/total candidates, ready item-price lines, item-price review
  lines, material/inventory prep candidates, parser-ready fields, and
  parser-review fields.
- Added `parserTaskCounts` and carried those counts into OCR diagnostics.
- Kept the data privacy-safe: the new diagnostics expose bucket counts and
  local line IDs only, not receipt text, vendor text, addresses, prices, notes,
  or customer/private content.
- Updated the OCR parser-ready test to prove multi-line store/header candidates
  are supported while item price and material candidate line IDs stay stable.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "parser-ready ordered receipt line signals"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying parser task counts into the
  expense parse diagnostics and privacy-safe event layer so Command One can
  eventually report what the parser had enough evidence to attempt.

### Receipt Camera Reopen Pass 511: Parser Task Telemetry Bridge Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser foundation work only.
- Added `ocrParserTaskCounts` to expense receipt parse diagnostics.
- Wired OCR parser task counts from `ReceiptOcrParserHandoff` into
  `parseExpenseReceiptOcrResult`, so vendor/date/total/item-price/material
  readiness survives into the expense parser result.
- Added `ocrParserTaskCounts` to privacy-safe receipt events and the local Hive
  privacy event store allow-list.
- Aggregated parser task counts into the Command One health snapshot map so the
  admin app can eventually show what the parser had enough evidence to attempt
  without receipt text.
- Added tests proving parser task counts flow through OCR parsing, parse
  diagnostics, privacy events, and health snapshots.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "OCR|ocr"`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using parser task counts in the
  app-assisted receipt review UI so the user sees which exact areas are ready
  versus need review: vendor, date, tax, total, item prices, and material
  candidates.

### Receipt Camera Reopen Pass 512: Parser Task Review UI Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser review work only.
- Updated the app-assisted receipt review guidance to use
  `diagnostics.parserTaskCounts` alongside field readiness counts.
- Added parser-task fallback chips for vendor, date, subtotal, tax, total,
  item-price-ready, item-price-needs-review, and material/inventory candidates.
- Added a subtotal review chip so receipt math readiness is visible beside tax
  and total.
- Kept the UI content-safe: the review screen shows readiness labels and counts,
  not private receipt text or item descriptions.
- Added source guards proving the review UI remains wired to parser task counts
  and the field-specific task keys.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a focused combined validation pass
  across OCR handoff, parse diagnostics, privacy telemetry, and review UI before
  moving into the next parser-hardening batch.

### Receipt Camera Reopen Pass 513: Parser Task Evidence Summary Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser diagnostics work only.
- Added parse-diagnostic getters for OCR task evidence:
  vendor, date, subtotal, tax, total, item prices, and material-prep
  candidates.
- Added `parserTaskSummaryLabel`, which explains what OCR prepared for the
  parser without exposing receipt text.
- Added parser tests proving the OCR task summary reports vendor/date/totals,
  item prices, and material candidates when the Lowe receipt fixture contains
  those signals.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "OCR|ocr"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is exposing the parser task summary in
  the app-assisted review flow once parse diagnostics are available, then
  tightening line classification behavior for mixed Business/Personal receipts.

### Receipt Camera Reopen Pass 514: Parser Task Review Handoff Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser review work only.
- Stored the latest `ExpenseReceiptParseDiagnostics` on the receipt entry state
  after app-assisted parsing succeeds or produces an unusable parse result.
- Cleared stored parse diagnostics when loading/applying a different receipt
  draft so stale parser evidence cannot appear on a later receipt.
- Passed parse diagnostics into the app-assisted review intro panel.
- Added a content-safe parser task summary chip to the filled receipt review
  screen so the user can see whether OCR prepared store/date/totals, line
  prices, and material-prep signals without exposing receipt text.
- Updated assisted-review source guards so this parser task handoff stays wired
  from entry state into review UI.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is mixed Business/Personal line
  classification readiness: make sure OCR price lines, tax, and totals can feed
  a clear split-review path before save.

### Receipt Camera Reopen Pass 515: Receipt Classification Readiness Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser review work only.
- Added parser diagnostics for receipt classification readiness:
  ready priced line count, mixed-receipt math basis, and a compact
  classification summary label.
- The summary distinguishes totals-only fallback, ready priced lines, lines
  needing review, tax readiness for mixed splits, and missing receipt math.
- Surfaced that summary in the app-assisted review panel as a
  Business/Personal/Mixed readiness chip.
- Kept the handoff privacy-safe: it uses counts and readiness labels only, not
  vendor names, raw receipt text, line descriptions, or prices.
- Added parser and assisted-review tests for the readiness summary and UI wiring.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses fuel receipt text|light parser depth"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening parser line identity for
  inventory/material handoff without editing the inventory app: line IDs,
  receipt order, priced-line roles, and review reasons must stay consistent.

### Receipt Camera Reopen Pass 516: OCR Line Identity Map Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser handoff work only.
- Added content-free OCR parser handoff maps:
  `roleByLineId` and `parserBucketByLineId`.
- Added ordered parser-ready and parser-review line ID lists so downstream
  parsers can preserve receipt order without carrying receipt text.
- Reused those ordered lists for parser task handoff buckets.
- Added OCR service tests proving item/total roles, ready/review buckets, and
  ordered ready/review IDs stay stable.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "parser line signals|generic priced"`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr result exposes parser-ready ordered receipt line signals"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying the new content-free line ID
  maps into parse diagnostics/telemetry summaries where useful, without storing
  private receipt text.

### Receipt Camera Reopen Pass 517: Parse Diagnostic Line Identity Bridge Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser handoff work only.
- Carried OCR handoff line identity into `ExpenseReceiptParseDiagnostics`.
- Added content-free diagnostic maps for OCR line ID to role and OCR line ID to
  parser bucket.
- Added ordered parser-ready and parser-review OCR line ID lists to diagnostics.
- Added helpers for downstream code to look up a line ID role or bucket without
  touching receipt text.
- Added parser tests proving OCR role/bucket identity and ordered ready/review
  IDs survive the OCR-to-expense-parser bridge.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses expense fields from OCR parser-ready receipt signals|preserves OCR item review buckets"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the app-assisted review panel
  show line identity health in plain language: ordered lines, ready lines,
  review lines, and material-prep lines.

### Receipt Camera Reopen Pass 518: Review Line Identity Health UI Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser review work only.
- Added `ocrLineIdentitySummaryLabel` to parse diagnostics.
- The label summarizes mapped OCR line IDs, parser-ready lines, lines needing
  review, and material-prep lines without exposing receipt content.
- Added a line identity health chip to the app-assisted review panel.
- The chip stays count/status based, so it can support Command One and future
  inventory/material parsing without storing vendor, address, line text, or
  price values.
- Added parser and assisted-review source tests for the new label and UI wiring.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses expense fields from OCR parser-ready receipt signals"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is parser quality around real receipt
  lines: handle more split/compact price rows and avoid turning receipt metadata
  into line items.

### Receipt Camera Reopen Pass 519: Barcode Metadata Line Filter Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser quality work only.
- Added a narrow line-item guard for UPC, barcode, QR-code, GTIN/EAN, and serial
  identifier rows that contain money-like values.
- The guard avoids turning receipt metadata identifiers into expense line items.
- Kept the filter narrow so legitimate item rows with SKU-like numbers, sizes,
  material names, and prices still parse as receipt lines.
- Added a parser regression proving barcode/UPC/QR rows with amounts are ignored
  while the real item line remains and receipt math reconciles.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "barcode|UPC|uses tender amount"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is compact and split-row price hardening:
  preserve real item lines when OCR puts description, quantity, and amount across
  adjacent rows while rejecting metadata-only rows.

### Receipt Camera Reopen Pass 520: Split-Row Quantity Price Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser quality work only.
- Improved split-row parsing when OCR reads the item description on one row and
  quantity/each/at-price/extended amount on the next row.
- Cleaned `2 EA @ ...` style quantity markers out of the final item
  description.
- Taught the material quantity parser to read `2 EA @ 18.49 36.98` even when it
  follows the item name instead of starting the row.
- Added a regression proving the parser keeps the pending description, reads
  quantity and unit price, and reconciles the receipt total.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_material_parser.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_material_parser.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "pending description|quantity and at-price|spaced OCR prices"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is more real-world parser hardening:
  mixed grocery/retail rows, duplicate overlap rows from long receipts, and
  clearer review causes when line totals do not reconcile.

### Receipt Camera Reopen Pass 521: Duplicate Overlap Review Warning Batch

Status: complete.

What changed:
- Continued receipt camera/OCR/parser quality work only.
- Added a parser warning for adjacent duplicate priced lines that may come from
  long-receipt overlap or stitched/multi-photo OCR repetition.
- Did not silently remove duplicate-looking lines because a user can
  legitimately buy the same item twice; the app now flags the risk for review
  instead of undercounting.
- Added a regression proving adjacent duplicates are preserved, receipt math can
  still reconcile, and the overlap warning is shown.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "duplicate lines|line totals|explicit subtotal"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making duplicate/overlap review
  causes visible in parser telemetry and app-assisted review, without exposing
  line descriptions or prices.

### Receipt Camera Reopen Pass 420 / Total Pass 500: Accepted Photo Draft Recovery Batch

Status: complete.

What changed:
- Added local draft persistence for the accepted-photo receipt review handoff
  state after a user captures or accepts receipt photos.
- Drafts now keep whether the assisted receipt review had started, whether a
  read was attempted without usable text, saved proof/source counts, next-step
  decision/action labels, current handoff stage, coverage warning, selected
  receipt review mode, and whether the user manually changed that mode.
- Restoring an expense receipt draft now restores that review handoff state
  instead of rebuilding it only from raw OCR text and parsed lines.
- Kept the draft format backward-compatible. Older drafts without these fields
  still load with safe defaults.
- Added regression coverage proving the accepted-photo review handoff state
  round-trips through the draft store.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_draft_record.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_draft_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_draft_record.dart lib/screens/expenses/data/expense_draft_store.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_draft_store_test.dart`
- `flutter test test/expense_draft_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is OCR line identity and parser handoff
  strength: preserve line order, role, price candidate state, vendor/date/total
  candidates, and inventory/material readiness without exposing private receipt
  content to telemetry.

### Receipt Camera Reopen Pass 421 / Total Pass 501: OCR Line Identity Handoff Batch

Status: complete.

What changed:
- Added content-free stable line IDs to OCR parser line signals. Downstream
  parsers can now refer to ordered lines such as item/summary/tender/metadata
  candidates without using vendor names, item descriptions, addresses, or
  prices in telemetry.
- Added parser bucket IDs for ready-vs-review line state.
- Added handoff helpers for all stable line IDs, parser-ready item line IDs,
  review-needed item line IDs, grouped line IDs by role, and parser bucket
  counts.
- Grouped subtotal, tax, and total candidates under a shared `summary` role
  while preserving their specific line IDs.
- Grouped receipt metadata and barcode/id-style lines under a shared
  `metadata` role where downstream consumers need one noise/context bucket.
- Added full OCR service coverage proving the Lowe's sample preserves ordered
  line IDs, ready item IDs, review item IDs, grouped summary IDs, and bucket
  counts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying these safe OCR line IDs into
  the expense parser result so the receipt review UI can show ordered lines and
  parser confidence while Command One still receives only counts/statuses.
