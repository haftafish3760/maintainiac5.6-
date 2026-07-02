# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 546: Assisted Review Parser Family Handoff Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 546: Assisted Review Parser Family Handoff Batch

Status: complete.

What changed:
- Persisted parser expense-family and parser-hint metadata on
  `ExpenseReceiptLineRecord`.
- Threaded those fields through the receipt entry line model, confirm flow,
  expense-only flow, ledger conversion, and parsed-receipt state conversion.
- Added local display labels for parser family/hint tokens so line review can
  show human-readable chips such as `Materials` and `Materials Item Price`.
- Updated the assisted line review row to show compact parser classification
  chips beside OCR evidence.
- Added parser-side family/hint generation for parsed receipt lines so OCR
  output can carry typed handoff metadata into business/personal/mixed review
  and future material/inventory intake.
- Kept admin/privacy boundaries intact: these are safe tokens and local review
  labels, not receipt text, images, vendor names, addresses, phone numbers, or
  notes.

Validation:
- `dart format lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_line_record_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_line_record_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_line_record_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses expense fields from OCR parser-ready receipt signals"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making capture/review interruption
  recovery stronger so accepted receipt photos and parser handoff state survive
  app backgrounding, phone calls, back navigation, and retry paths.

### Receipt Camera Reopen Pass 547: Native Capture Recovery Stage Batch

Status: complete.

What changed:
- Added recovery-stage updates for native receipt captures so the JSON manifest
  and Hive index can record where the user was when interrupted.
- Marked review-opening, review-closed, and review-accepted states from the
  shared receipt capture flow.
- Preserved accepted staged photos until the attachment handoff clears the
  recovery manifest, so a phone call/app background event between review and
  OCR does not silently erase the local recovery path.
- Added allowlisted recovery diagnostics for review opened/closed/accepted,
  OCR pending, reviewed photo count, and OCR source count.
- Added a regression test proving unsafe private receipt text is rejected from
  both the recovery manifest and Hive index.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --name "recovery stage updates"`
- `flutter test test/receipt_native_capture_staging_test.dart --name "clearing accepted recovery"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing recovery-stage diagnostics
  through the receipt attachment/capture diagnostic event path so the expense
  app and Command One can count interruption points without private content.

### Receipt Camera Reopen Pass 548: Recovery Stage Telemetry Bridge Batch

Status: complete.

What changed:
- Added recovery-stage metadata to accepted and closed shared receipt capture
  flow results.
- Forwarded non-failure recovery-stage diagnostics into expense telemetry as
  safe image-attach health events instead of dropping them.
- Reused the existing native recovery status buckets so Command One can later
  count review accepted, review closed, OCR pending, reviewed photo count, and
  multi-section interruption points without seeing receipt content.
- Kept failure telemetry separate: real native camera/capture failures still
  record as image attach failures with confirmed cause and recovery action.
- Added source guards proving the shared flow emits recovery-stage metadata and
  the expense entry screen records the safe recovery buckets.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "accepted shared flow clears"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening the capture review UI
  around accepted-photo retention, back/close behavior, and clear Next/add-photo
  language so the user cannot accidentally lose a receipt photo or miss the
  filled receipt review step.

### Receipt Camera Reopen Pass 549: Review Exit And Next Language Batch

Status: complete.

What changed:
- Made the receipt review primary path explicit: multi-photo stitch/fallback
  paths now end with `Next: Review Receipt Details` instead of plain `Next`.
- Changed long-receipt add-photo language in the review controls to
  `Add Next Section` / `Add Section`, and the overflow menu to
  `Add Next Receipt Section`.
- Tightened the leave-review confirmation copy so users are told that photos
  stay recoverable on the phone, but are not attached or read until they tap
  Next.
- Replaced ambiguous leave labels with `Leave For Later`.
- Kept the existing back/close protection and recovery behavior intact; this
  pass changes the user-facing contract around those actions, not the storage
  engine.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt photo back protects"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the capture-review photo order and
  long-receipt section guidance: make out-of-order, missing-middle, duplicate,
  and overlap recovery paths clearer before OCR/parser handoff.

### Receipt Camera Reopen Pass 535: Category Parser Health Buckets Batch

Status: complete.

What changed:
- Added parser-level category counts for receipt lines using safe category
  tokens such as `fuel`, `materials`, `vehicle_supplies`, `general`, and
  `uncategorized`.
- Added category health counts that separate ready lines from lines needing
  review, plus family buckets for fuel, materials, vehicle, general,
  adjustment, and uncategorized receipt types.
- Added material-specific catalog health counts so Command One can later show
  whether material receipt parsing is failing because the parser saw the line
  but could not match the catalog.
- Threaded the new counts into privacy-safe receipt events without merchant
  names, addresses, receipt text, line descriptions, line IDs, prices, notes, or
  images.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `flutter test test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture control parity and
  focused tests for pinch zoom, tap focus, exposure/reset, settings, and
  back/close diagnostics.

### Receipt Camera Reopen Pass 539: Parser Health Telemetry Store Bridge Batch

Status: complete.

What changed:
- Added parser category counts, parser category health counts, and parser
  required-field status counts to the privacy-event allowlist.
- Aggregated those maps into the local Hive health snapshot used by future
  Command One receipt health cards.
- Exported the aggregate maps in `toCommandCenterMap()` so parser failures can
  be grouped by category, category readiness, and required-field stage.
- Added store tests proving the new maps survive local queueing and health
  summary generation without storing private receipt text, merchant names, item
  descriptions, line prices, addresses, phone numbers, notes, images, or line
  IDs.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_store_test.dart --name "queues only privacy-safe"`
- `flutter test test/receipt_privacy_event_store_test.dart --name "builds command center health snapshot"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture control parity and
  focused tests for pinch zoom, tap focus, exposure/reset, settings, and
  back/close diagnostics.

### Receipt Camera Reopen Pass 538: Native Capture OCR Plan Staging Guard Batch

Status: complete.

What changed:
- Audited native capture result and staging diagnostics for local/cloud OCR
  policy propagation.
- Confirmed production code already carries cloud assist plan, local OCR
  availability, local OCR mode, parser depth, local parser scope, catalog
  limit, and inventory cache limit through native capture and recovery staging.
- Added missing test assertions proving parser depth and local parser scope are
  retained in both staged photo diagnostics and the recovery manifest.
- Kept the staged diagnostics content-free: no receipt text, line item text,
  merchant names, prices, images, addresses, phone numbers, or notes.

Validation:
- `dart format test/receipt_native_capture_staging_test.dart`
- `flutter analyze test/receipt_native_capture_staging_test.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --name "accepted native capture is copied"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture control parity and
  focused tests for pinch zoom, tap focus, exposure/reset, settings, and
  back/close diagnostics.

### Receipt Camera Reopen Pass 537: Low-Storage Cloud Assist Guard Batch

Status: complete.

What changed:
- Added a regression guard for high-capacity phones under low-storage pressure.
- Confirmed low storage keeps local OCR available instead of making receipt
  reading cloud-only.
- Confirmed low storage switches to lean local OCR, limits local catalog/cache
  workload, and may offer cloud OCR or cloud inventory matching only as explicit
  optional assist.
- Preserved the privacy/cost contract: cloud assist requires a user choice and
  internet; basic capture, local OCR, review, and manual entry remain usable
  without cloud OCR.

Validation:
- `dart format test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_camera_contract_test.dart lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --name "session honors device storage pressure"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture control parity and
  focused tests for pinch zoom, tap focus, exposure/reset, settings, and
  back/close diagnostics.

### Receipt Camera Reopen Pass 536: Parser Required Field Health Batch

Status: complete.

What changed:
- Added parser-side required field status counts after OCR handoff, covering
  vendor, date, time, subtotal, tax, total, item prices, and item categories.
- Kept this separate from OCR-required-field counts so diagnostics can show
  whether OCR failed to see a field or the parser failed to use the OCR result.
- Added ready, needs-review, and missing totals for parser-required receipt
  fields.
- Added privacy-safe event export for parser field health so Command One can
  later show failure points without receipt text, merchant names, line
  descriptions, prices, addresses, notes, phone numbers, line IDs, or images.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses fuel receipt text"`
- `flutter test test/receipt_privacy_event_test.dart --name "parser privacy event reports counts"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture control parity and
  focused tests for pinch zoom, tap focus, exposure/reset, settings, and
  back/close diagnostics.

### Receipt Camera Reopen Pass 533: OCR Source Handoff Integrity Batch

Status: complete.

What changed:
- Hardened `ReceiptPhotoReviewResult` so accepted receipt review results always
  expose nonblank saved proof paths and OCR source paths.
- Added a defensive fallback: if a caller accidentally omits OCR source paths,
  the receipt reader falls back to the accepted proof paths instead of silently
  handing OCR an empty source list.
- Added privacy-safe receipt-reader handoff counts for saved proof presence,
  OCR source presence, data-saver separation, stitch/fallback routing, partial
  receipt risk, saved-photo parser risks, and scanner quality-guard decisions.
- Added the same handoff integrity label/counts to shared capture-flow
  diagnostics for both fresh camera captures and recovered interrupted captures.
- Added focused regression coverage for separate OCR source copies, fallback
  source behavior, saved-photo parser risk buckets, stitch/fallback routing, and
  scanner operator-review handoff counts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is parser-facing receipt line readiness:
  keep improving how OCR lines flow into vendor/date/tax/total/item-price
  parsing and expose private-safe failure buckets for categories like fuel,
  materials, groceries, and maintenance without touching inventory or
  maintenance implementation.

### Receipt Camera Reopen Pass 534: Required Receipt Field Readiness Batch

Status: complete.

What changed:
- Added shared OCR handoff counts for required receipt field status:
  vendor, date, item prices, subtotal, tax, and total now report ready,
  needs-review, or missing buckets without exposing receipt text or amounts.
- Added a compact required-field status label such as
  `required_receipt_fields:ready=5;review=1;missing=0;...` for operator and
  Command One diagnostics.
- Carried the required-field status counts through OCR diagnostics,
  expense-parser diagnostics, and privacy-safe receipt telemetry.
- Kept the implementation additive: existing parser task counts, field
  readiness counts, line IDs, and receipt parser behavior remain in place.
- Added regression coverage proving the counts survive from OCR handoff to
  expense parsing and privacy-safe telemetry without storing merchant names,
  item descriptions, prices, addresses, phone numbers, or raw OCR line text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `flutter test test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "parser-ready"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is category-aware parser health buckets:
  fuel, materials, grocery/general, and maintenance-like receipt categories need
  private-safe success/failure/readiness buckets while avoiding maintenance or
  inventory implementation changes.

### Receipt Camera Reopen Pass 504: Line Classification Review Guidance Batch

Status: complete.

What changed:
- Continued the camera/OCR receipt flow without touching inventory, Firebase,
  maintenance, or PDF.
- Strengthened the app-assisted receipt review panel so OCR/parser line output
  is not treated as a vague receipt total. The screen now summarizes whether
  lines are OCR-filled, need parser review, or need split-percent decisions.
- Added a focused line-classification checklist below the Business, Personal,
  and Mixed receipt controls so the user can see what must be checked before
  trusting business/personal totals.
- Kept the logic content-safe: the UI uses line counts and status labels, not
  private receipt text.
- Updated the assisted receipt review source guard so future edits keep the
  line-aware review guidance, OCR-filled language, split-percent handling, and
  business/personal total warning in place.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_recap.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_recap.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying the OCR parser line roles
  into a stronger review-ready handoff for vendor, date, tax, total, line-price,
  and inventory/material candidate preparation without collecting private
  receipt text in telemetry.

### Receipt Camera Reopen Pass 505: Parser Field Readiness Handoff Batch

Status: complete.

What changed:
- Continued camera/OCR/parser work only. No inventory, maintenance, Firebase,
  or PDF implementation was touched.
- Added line-level OCR handoff readiness for receipt fields:
  vendor, date, subtotal, tax, total, item price, and inventory/material
  candidates.
- Added privacy-safe primary field line IDs inside the local parser handoff so
  the app can keep internal line references stable without sending line text to
  diagnostics or Command One telemetry.
- Added material/inventory prep line counts based on item lines that have a
  price plus quantity/unit or SKU-like signals.
- Carried the new aggregate counters into expense parser diagnostics:
  inventory-prep line count, parser-ready field count, parser-review field
  count, and field-readiness bucket counts.
- Carried the same values into local privacy-safe telemetry and health snapshot
  aggregation as counts only. No receipt text, prices, vendor names, addresses,
  or stable `ocr_line_*` IDs are exported in telemetry.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "parser-ready ordered receipt line signals"`
- `flutter test test/expense_receipt_parser_test.dart --name "OCR|ocr"`
- `flutter test test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the receipt review screen use
  field-readiness counts to guide the user through exact missing/review fields
  before saving: vendor, date, tax, total, line prices, and material candidates.

### Receipt Camera Reopen Pass 506: Field-Specific Review UI Batch

Status: complete.

What changed:
- Continued camera/OCR/parser work only.
- Exposed field-readiness counts on `ReceiptOcrDiagnostics` so the review UI
  can react to vendor, date, tax, total, item-price, and material-candidate
  readiness without depending on private text.
- Added app-assisted review chips for:
  store ready/needs review, date ready/needs review, total ready/needs review,
  tax ready/needs review, ready item prices, item prices needing review, and
  material candidates.
- Kept the UI compact: these are small instruction chips inside the existing
  review intro panel, not a new blocking screen.
- Added source guards proving the assisted review flow keeps field-specific
  status chips and material candidate guidance.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`
- `flutter test test/receipt_ocr_service_test.dart --name "parser-ready ordered receipt line signals"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening the exact post-photo
  handoff path so accepted receipt photos reliably advance to the filled receipt
  review screen, preserving multi-photo/stitch readiness and avoiding return to
  the add-expense home state.

### Receipt Camera Reopen Pass 507: Accepted Photo Review Handoff Label Batch

Status: complete.

What changed:
- Continued receipt camera/OCR flow work only.
- Made successful receipt reads explicitly point to the filled receipt review
  target with the decision label `Open filled receipt review`.
- Added a concrete action label for the successful handoff:
  review store, date, tax, total, item prices, and Business/Personal/Mixed.
- Made unusable parser results explicitly point to a manual receipt review path
  instead of leaving the handoff ambiguous.
- Ensured attachment scans mark the receipt review flow as started before OCR
  work begins, so the user sees the review/handoff area instead of thinking
  they were sent back to the attachment start.
- Added source guards proving the filled-review and manual-review handoff
  labels stay wired into the expense receipt flow.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "app assisted|assisted|review"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding stronger runtime/guard
  coverage for the photo-review continue button and accepted-photo result so
  multi-photo, fallback stitch, and single-photo receipts all have the same
  “Next opens filled review” contract.
