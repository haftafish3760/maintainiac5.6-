# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 554: Accepted Photo Parser Route Telemetry Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 554: Accepted Photo Parser Route Telemetry Batch

Status: complete.

What changed:
- Added accepted-photo handoff metadata to expense parser telemetry so Command
  One can distinguish whether the parser result came from the saved receipt
  photo review route and how many proof/OCR-source photos were handed forward.
- Added downstream OCR parser-readiness status and counts to the same telemetry
  event so receipt failures can be grouped by exact parser-prep blockers instead
  of generic parse failure.
- Kept telemetry privacy-safe: only route/status/count tokens are recorded, not
  receipt text, merchant names, item descriptions, addresses, phone numbers,
  notes, line IDs, or prices.
- Added assisted-review guard coverage proving the route metadata remains wired
  into the expense receipt review flow.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the accepted-photo route
  so the next visible user step after accepting receipt photos is the filled
  receipt details review, with no fallback to the generic expense entry shell
  unless app assistance is disabled or OCR cannot produce usable text.

### Receipt Camera Reopen Pass 555: Parser Downstream Readiness Batch

Status: complete.

What changed:
- Added parser-side downstream readiness status and counts to
  `ExpenseReceiptParseDiagnostics`.
- The parser now reports whether parsed output is ready for expense-line review,
  inventory/material handoff, vehicle-cost review, total-only proof review, or
  manual proof review.
- Added privacy-safe telemetry fields for parser downstream readiness so
  Command One can group vendor/date/total/priced-line/category failures without
  collecting receipt text or item descriptions.
- Added focused parser coverage for a normal fuel receipt and a Lowe's material
  receipt handoff.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "parses fuel receipt text into editable receipt fields"`
- `flutter test test/expense_receipt_parser_test.dart --name "parser marks material receipt lines ready for inventory handoff"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR/parser only. Next target is connecting parser downstream
  readiness to review-screen labels/actions so the user sees the right next
  step after receipt reading, and Command One sees matching health buckets.

### Receipt Camera Reopen Pass 556: Parser Readiness Review Guidance Batch

Status: complete.

What changed:
- Updated the app-assisted receipt review guidance to use parser downstream
  readiness when OCR readiness is unknown or weaker than the parser result.
- Review chips can now show parser-backed ready lines, lines needing review,
  ordered line count, material readiness, and downstream readiness status.
- Kept the user-facing flow focused on next action: review expense lines,
  inventory/material handoff, vehicle-cost review, total-only fallback, or
  manual proof review.
- Added guard coverage proving the review screen keeps parser downstream
  readiness wiring.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `flutter test test/expense_receipt_parser_test.dart --name "parses fuel receipt text into editable receipt fields"`
- `flutter test test/expense_receipt_parser_test.dart --name "parser marks material receipt lines ready for inventory handoff"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR/parser only. Next target is adding parser downstream
  readiness to telemetry schema expectations and health aggregation so the
  admin command center can trust these buckets.

### Receipt Camera Reopen Pass 557: Parser Readiness Health Aggregation Batch

Status: complete.

What changed:
- Added parser downstream readiness status/count aggregation to the expense
  telemetry health snapshot.
- Added Command One map fields for parser downstream readiness counts, top
  parser downstream readiness status, and top parser downstream readiness
  bucket.
- Added parser downstream readiness fields to telemetry schema expectations as
  privacy-safe maps/status tokens.
- Extended parser-health coverage for completed, needs-review, and failed
  parser events without storing receipt text, merchant names, line descriptions,
  addresses, phone numbers, notes, IDs, or prices.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "summarizes parser category health for Command 1 without receipt content"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR/parser only. Next target is adding privacy-safe parser
  downstream readiness to receipt privacy events so the offline queue and
  Command One rollups agree.

### Receipt Camera Reopen Pass 558: Privacy Queue Parser Readiness Batch

Status: complete.

What changed:
- Added parser downstream readiness status/counts to privacy-safe receipt
  events.
- Added the same parser downstream readiness buckets to the local privacy-event
  health snapshot and Command One map output.
- Extended privacy policy allow-listing for those fields as status/count tokens.
- Hardened parser downstream readiness so material/inventory handoff does not
  report ready when receipt math is badly mismatched.
- Added privacy-event and privacy-event-store coverage proving the fields are
  aggregated without raw receipt text, merchant names, item descriptions,
  amounts, addresses, phone numbers, notes, or OCR line IDs.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart`
- `flutter test test/receipt_privacy_event_test.dart --name "parser privacy event reports counts without merchant items or prices"`
- `flutter test test/receipt_privacy_event_store_test.dart --name "builds command center health snapshot without raw event details"`
- `flutter test test/expense_receipt_parser_test.dart --name "parser marks material receipt lines ready for inventory handoff"`
- `flutter test test/expense_receipt_parser_test.dart --name "parses fuel receipt text into editable receipt fields"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR/parser only. Next target is focused review of remaining
  camera route issues: native capture back/close behavior, accepted-photo
  persistence, and no return to the generic expense shell when assisted receipt
  review is active.

### Receipt Camera Reopen Pass 550: Long Receipt OCR Handoff Checklist Batch

Status: complete.

What changed:
- Added explicit long-receipt OCR handoff checklist labels to
  `ReceiptStitchResult` so the review UI can say what must be checked before
  opening app-assisted receipt details.
- Added overlap expectation labels for single-photo, repeated-line match,
  manual overlap, and safe fallback paths.
- Surfaced the checklist and overlap evidence inside the long receipt match
  card without expanding it into a large blocking panel.
- Tightened the copy so a fallback no longer sounds like a broken flow: Next
  reads each section from top to bottom, and the user is told to verify order
  and missing middle sections before continuing.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "long receipt stitch review shows plain decision evidence"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the capture-to-review handoff:
  accepted photos must preserve the original OCR source, never silently discard
  staged captures, and the visible Next path must open parsed receipt details
  instead of returning to the expense entry shell.

### Receipt Camera Reopen Pass 551: Downstream Parser Readiness Handoff Batch

Status: complete.

What changed:
- Audited the shared OCR parser handoff for vendor, date, summary, item-price,
  material, fuel, vehicle-cost, and inventory/material prep signals.
- Added a privacy-safe downstream readiness status to
  `ReceiptOcrParserHandoff` so expenses, materials/inventory, and later
  maintenance can ask whether the receipt is proof-only, expense-line ready,
  inventory/material ready, vehicle-cost ready, or needs review without reading
  raw receipt text.
- Added downstream readiness labels and counts for Command One/admin health and
  future module handoff. These are status/count buckets only; no vendor names,
  receipt text, item descriptions, prices, addresses, or phone numbers are
  included.
- Covered the ready material/inventory path and weak generic-line path in the
  OCR service tests.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "parser handoff"`
- `flutter test test/receipt_ocr_service_test.dart --name "generic"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is promoting downstream readiness into
  expense parse diagnostics and assisted receipt review so the user sees
  concrete review actions while Command One sees only privacy-safe counts.

### Receipt Camera Reopen Pass 552: Expense Review Downstream Readiness Batch

Status: complete.

What changed:
- Promoted OCR downstream readiness into `ExpenseReceiptParseDiagnostics`.
- Carried downstream readiness status/counts from `ReceiptOcrParserHandoff`
  through the OCR-to-expense parser entry point.
- Added a compact assisted-review chip so the expense receipt review can show
  whether OCR produced inventory/material-ready lines, material expense lines,
  vehicle cost lines, ordinary expense lines, proof-only totals, or review
  status.
- Kept the status privacy-safe: no vendor names, receipt text, item
  descriptions, prices, addresses, phone numbers, or notes are included.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes"`
- `flutter test test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "parser handoff"`
- `git diff --check`

Note:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "parser"`
  was attempted and correctly ran no tests because that file currently has only
  the `assisted expense receipt review exposes whole receipt choices` test.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding downstream readiness to
  privacy-safe event aggregation/Command One counts so admin health can show
  whether failures are proof capture, OCR structure, parser line readiness, or
  downstream module readiness problems.

### Receipt Camera Reopen Pass 553: Command One Downstream Readiness Counts Batch

Status: complete.

What changed:
- Added OCR downstream readiness status and readiness count maps to
  privacy-safe receipt events.
- Added downstream readiness aggregation to
  `ReceiptPrivacyEventHealthSnapshot` and exposed it through
  `toCommandCenterMap`.
- Added downstream readiness evidence to parser failure diagnostics so a future
  Command One failure drill-in can distinguish OCR readiness from downstream
  module readiness.
- Updated privacy tests to prove the new fields remain count/status-only and
  do not include receipt images, OCR text, vendor names, line descriptions,
  prices, addresses, phone numbers, or notes.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_privacy_event.dart lib/screens/expenses/data/expense_receipt_privacy_event_store.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart test/receipt_privacy_event_test.dart test/receipt_privacy_event_store_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/receipt_privacy_event_test.dart`
- `flutter test test/receipt_privacy_event_store_test.dart --name "builds command center health snapshot"`
- `flutter test test/expense_parser_failure_diagnostics_test.dart --name "OCR parser-readiness failures"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the actual capture-to-review route:
  after accepting receipt photos, the primary Next path must open parsed receipt
  details, preserve OCR source images, and keep staged recovery available if the
  user is interrupted.

### Receipt Camera Reopen Pass 540: Parser Health Command One Bridge Batch

Status: complete.

What changed:
- Carried parser category health and required-field status counts from local
  expense telemetry into the Command One-facing health snapshot.
- Added top parser health/status buckets so admin health can answer what kind
  of parser issue is most common without reading receipt text.
- Brought existing OCR parser task/readiness maps into the Firestore/admin
  schema contract so generated telemetry is not silently dropped.
- Updated the Firestore sanitizer, schema helper, OCR contract docs, and parity
  tests together to keep the one-summary-document Command One shape stable.
- Kept the data content-free: only safe bucket counts and top tokens are
  exported, not vendor names, receipt text, item descriptions, addresses,
  prices, notes, or customer content.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "summarizes parser category"`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart --name "keeps every Command Center telemetry field"`
- `flutter test test/maintainiac_firestore_documents_test.dart --name "embeds privacy-safe OCR contract"`
- `flutter test test/maintainiac_firestore_documents_test.dart --name "sanitizes expense telemetry maps"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the receipt line parser
  handoff so OCR output is grouped into stable receipt lines before category,
  inventory, business/personal, and mixed-use review decisions.

### Receipt Camera Reopen Pass 541: Local OCR Line Draft Handoff Batch

Status: complete.

What changed:
- Added a local-only `ReceiptOcrParserLineDraft` model for the parser/review
  handoff.
- Each OCR parser line draft now carries a stable line id, visible line number,
  role, parser bucket, amount candidate, confidence, review reason, and traits.
- Added handoff getters for all line drafts, item line drafts, parser-ready item
  drafts, review item drafts, line-id lookup, item amount lookup, item text
  lookup, local review maps, and privacy-safe summary maps.
- Added an inventory-prep trait for priced item lines that have SKU or quantity
  signals without being generic text.
- Added a confidence bucket for privacy-safe summaries so Command One-style
  diagnostics can count line health without carrying private OCR text.
- Kept real OCR line text local-only for the user-facing receipt review flow;
  the privacy-safe summary map excludes receipt words and vendor text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr parser handoff exposes local line drafts"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is feeding local OCR line drafts into
  the expense receipt parse-review screen so app-assisted review can show
  stable line numbers, item amounts, and review state before business,
  personal, or mixed classification.

### Receipt Camera Reopen Pass 542: Parsed Line OCR Source Identity Batch

Status: complete.

What changed:
- Added optional OCR source line identity to `ExpenseReceiptLineRecord`.
- Parsed receipt lines now preserve the OCR source line id and visible OCR line
  number that produced the line item.
- Added local labels such as `OCR line 3` so the review UI can explain where a
  parsed item came from without relying on developer-only ids.
- Persisted the source line identity through receipt line map save/restore.
- Kept the source identity local to the receipt record and parser UI; no OCR
  text, vendor names, prices, or item descriptions were added to admin
  telemetry.

Validation:
- `dart format lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_line_record_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_line_record.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_line_record_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "preserves OCR item review buckets"`
- `flutter test test/expense_receipt_line_record_test.dart --name "receipt line catalog metadata round trips"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is showing OCR source-line labels inside
  app-assisted receipt review rows so users can see exactly which receipt line
  they are classifying.

### Receipt Camera Reopen Pass 543: Assisted Review OCR Line Label Batch

Status: complete.

What changed:
- Threaded OCR source line id and OCR source line number through the private
  receipt entry line model.
- Preserved those fields when lines are copied, confirmed, marked
  expense-only, and converted back into ledger line records.
- Updated app-assisted receipt review rows to show labels such as `OCR line 3`
  beside the local receipt evidence text.
- Kept the display fallback for manual or older lines that do not have OCR
  source identity.
- Added guard coverage proving the assisted review flow includes the OCR source
  line label path.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `flutter test test/expense_receipt_line_record_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening parser line identity for
  multi-section receipts where repeated overlap lines are suppressed, so line
  numbers remain understandable after long-receipt stitching/dedupe.

### Receipt Camera Reopen Pass 544: Multi-Section OCR Source Label Batch

Status: complete.

What changed:
- Added `ReceiptOcrParserLineLocation` so OCR parser lines can carry the
  original receipt section number and section line number after long-receipt
  overlap suppression.
- Threaded source locations through combined OCR text, parser line signals, and
  local parser line drafts.
- Local review maps can now show labels such as `section 2 line 2` for
  multi-photo receipt review.
- Privacy-safe summary maps include only numeric source section/line metadata;
  they still exclude receipt text, vendor words, item descriptions, addresses,
  prices, notes, phone numbers, and images.
- Added focused coverage proving repeated overlap lines are suppressed while
  the retained section line keeps the correct source location.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "source section labels"`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr parser handoff exposes local line drafts"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using these source locations in the
  parser review handoff so long receipts can explain duplicate, missing-middle,
  and out-of-order section problems without exposing private receipt content to
  admin telemetry.

### Receipt Camera Reopen Pass 545: Parser Family Handoff Batch

Status: complete.

What changed:
- Added safe OCR parser expense-family tokens for receipt item lines:
  materials, fuel, vehicle supplies, food/grocery, business supplies, service,
  general expense, and non-item receipt buckets.
- Added parser hints such as `materials_item_price` and `fuel_item_price` so
  downstream expense/materials/inventory flows can consume typed line signals
  instead of scraping raw OCR text.
- Added family/hint lookups by stable line id plus safe count maps for parser
  health and future Command One summaries.
- Expanded material/inventory-prep detection so material-looking item lines can
  be prepared for inventory even when the signal is keyword-based rather than
  only SKU/unit-based.
- Kept private content local: local review maps still include the user's
  receipt line text for review, while privacy-safe summary maps expose only
  tokens/counts and no vendor names, item descriptions, addresses, phone
  numbers, notes, receipt images, or raw OCR text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr parser handoff"`
- `flutter test test/receipt_ocr_service_test.dart --name "parser-ready ordered receipt line signals"`
- `flutter test test/receipt_ocr_service_test.dart --name "source section labels"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is feeding parser family/hint tokens
  into the assisted receipt review screen so business/personal/mixed and future
  materials handoff can start from typed receipt lines instead of generic rows.
