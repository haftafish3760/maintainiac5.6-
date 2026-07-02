# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1185: Root-Cause Assisted Review Copy

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1185: Root-Cause Assisted Review Copy

Status: complete.

What changed:
- Added local parser root-cause action labels and instructions for the assisted
  receipt review flow.
- Root-cause guidance now gives a concrete next step for:
  - capture coverage and long receipt sections,
  - camera/source photo quality,
  - multi-photo overlap,
  - receipt math review,
  - missing OCR-required fields,
  - optional parser-pack limits,
  - parser category confidence,
  - parser-ready receipts.
- Assisted review now uses root-cause instructions before falling back to the
  generic parser task summary, so users get clearer guidance when OCR text was
  read but the parser still needs help.
- Parser root-cause labels can appear as compact assisted-review chips when
  higher priority math, overlap, lower-section, and photo-quality chips do not
  already explain the problem.
- Added regression coverage for camera/source-quality root-cause action copy
  and assisted-review wiring.
- This pass is local assisted review copy only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes saved bottom photo quality into assisted review guidance" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening required
  field diagnostics so vendor/date/total/tax/item-price gaps produce more
  precise local parser tasks and clearer review actions.

### Receipt Camera Reopen Pass 1186: Required Field Issue Specificity

Status: complete.

What changed:
- Added field-specific OCR required-field issue labels to parser diagnostics.
- Required-field review can now say exactly what needs attention, such as:
  - `missing subtotal`
  - `missing total`
  - `check store`
  - `check item prices`
- Root-cause instructions for `ocr_required_fields` now include the exact
  missing/review fields instead of a generic "one or more fields" message.
- Tightened receipt address/contact detection so address and phone rows do not
  get misclassified as item-price lines just because a phone number or zip code
  looks like a money amount.
- Corrected the state-abbreviation detector so item lines like `14-OZ` do not
  get mistaken for address metadata.
- Updated parser regressions to preserve the corrected address/item behavior
  and the new required-field issue copy.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "summarizes OCR required field issues by field" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving item-line
  filtering and candidate confidence so receipt metadata, tender rows, and
  true item rows stay separated across more store formats.

### Receipt Camera Reopen Pass 1187: Tender Reference And Address Row Separation

Status: complete.

What changed:
- Added a Lowe's regression proving address and phone rows stay in receipt
  metadata instead of becoming item-price candidates.
- Preserved the material item row as the single item candidate on the same
  receipt, so real expense lines are not lost while metadata is filtered out.
- Split tender reference evidence from money extraction:
  - gift-card/authcode/reference rows can remain tender evidence,
  - auth/reference identifiers no longer invent fake dollar amounts from plain
    ID digits such as `AUTHCODE 370`.
- Updated the parser-ready handoff test so tender evidence, metadata evidence,
  and item evidence use separate buckets and counts.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "receipt address phone rows stay metadata not item prices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening
  receipt-line role confidence and review reasons so totals, tenders,
  metadata, and true item rows remain separated on fuel, hardware, grocery,
  and general expense receipts.

### Receipt Camera Reopen Pass 1188: Amountless Tender IDs And Local Merchant Headers

Status: complete.

What changed:
- Added a tender-reference classifier path for payment/auth/reference rows that
  should remain receipt evidence even when they do not carry a dollar amount.
- Prevented inferred-cents parsing from turning authorization/reference digits
  into fake money. Examples protected by tests:
  - `AUTHCODE 370`
  - `AUTH 87654321`
  - `AUTH 1314`
- Prevented local merchant headers with store numbers from becoming inferred
  money rows. Example protected by tests:
  - `RIVER ROAD MART 418`
- Reordered local merchant detection ahead of address metadata detection so
  merchant names containing street-like words such as `ROAD` can still rank as
  vendor candidates when the rest of the line looks like a store header.
- Updated date/time false-positive regressions so auth and transaction IDs do
  not become dates, times, item prices, totals, or fake primary amounts.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt dates are recovered without numeric id false positives" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt times are tracked without transaction id false positives" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "receipt address phone rows stay metadata not item prices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is expanding store-format
  regressions around generic gas, grocery, and hardware receipt rows so the
  local parser can keep improving without cloud help.

### Receipt Camera Reopen Pass 1189: Generic Fuel Grocery Hardware Role Matrix

Status: complete.

What changed:
- Added a local parser regression matrix for generic, non-brand-specific
  receipts:
  - fuel station receipt,
  - grocery/market receipt,
  - neighborhood hardware receipt.
- Protected generic fuel parsing:
  - `QUICK FUEL 27` stays the vendor,
  - `PUMP 04` no longer becomes a vendor candidate,
  - fuel item, fuel sale total, card tender, and auth reference stay separated.
- Protected generic grocery parsing:
  - `CORNER MARKET 52` stays the vendor,
  - normal item rows remain item candidates,
  - EBT/SNAP/food-stamp tender rows stay out of item candidates.
- Protected generic hardware parsing:
  - `NEIGHBOR HARDWARE 104` stays the vendor,
  - material item rows remain item candidates,
  - order/reference rows stay metadata,
  - card approval rows stay amountless tender evidence.
- Added `PUMP`/register-style vendor exclusions.
- Added EBT/SNAP/food-stamp tender detection and item-line exclusion.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "generic fuel grocery and hardware receipts keep local parser roles" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt dates are recovered without numeric id false positives" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt times are tracked without transaction id false positives" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "receipt address phone rows stay metadata not item prices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using the generic
  matrix to improve local parser category/family confidence and review prompts
  for fuel, grocery, hardware/material, and mixed receipts without relying on
  cloud OCR.

### Receipt Camera Reopen Pass 1190: Generic Receipt Expense Family Hints

Status: complete.

What changed:
- Extended the generic fuel/grocery/hardware receipt matrix so it verifies
  local expense-family hints, not just line roles.
- Added common produce/grocery tokens to the local food/grocery detector so
  normal rows like `BANANAS 4011 1.29` classify as food/grocery instead of
  falling back to generic expense.
- Protected these local family outcomes:
  - fuel rows classify as `fuel`,
  - produce/grocery rows classify as `food_or_grocery`,
  - shop-towel rows classify as `vehicle_supplies`,
  - PVC/material rows classify as `materials`.
- This pass strengthens downstream app-assisted receipt review because mixed
  business/personal flows can start with better local family hints before any
  cloud/parser-pack work exists.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "generic fuel grocery and hardware receipts keep local parser roles" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is converting these local
  family hints into clearer review prompts and privacy-safe diagnostics for the
  assisted expense receipt screen.

### Receipt Camera Reopen Pass 1191: Privacy-Safe Item Family Review Contract

Status: complete.

What changed:
- Added privacy-safe item-family handoff evidence to the local OCR parser:
  - item line IDs grouped by expense family,
  - present expense-family list,
  - dominant expense family,
  - single-family versus mixed-family status,
  - compact family summary label,
  - family diagnostics map with counts and line IDs only.
- Added parser task buckets for local family review:
  - `expense_family_fuel_item`
  - `expense_family_food_or_grocery_item`
  - `expense_family_vehicle_supplies_item`
  - `expense_family_materials_item`
  - `expense_family_single_receipt`
  - `expense_family_mixed_receipt`
- Added the family summary to the OCR parser signal summary so assisted review
  can say things like:
  - `Receipt family: fuel`
  - `Receipt family: materials`
  - `Mixed receipt families: food/grocery, vehicle supplies`
- Strengthened the generic fuel/grocery/hardware matrix so it proves those
  family diagnostics are available without exposing receipt text.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "generic fuel grocery and hardware receipts keep local parser roles" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt dates are recovered without numeric id false positives" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt times are tracked without transaction id false positives" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "receipt address phone rows stay metadata not item prices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is carrying the privacy-safe
  family status from OCR diagnostics into expense parse diagnostics and the
  assisted review copy, while keeping raw receipt text out of telemetry.

### Receipt Camera Reopen Pass 1192: OCR Family Mix Into Expense Parse Diagnostics

Status: complete.

What changed:
- Carried the OCR item-family status, summary label, and family counts from the
  local OCR handoff into `ExpenseReceiptParseDiagnostics`.
- Added `hasOcrMixedItemExpenseFamilies` so assisted review and telemetry can
  detect mixed receipt families without raw receipt text.
- Included the OCR family summary in `parserTaskSummaryLabel`, so parse review
  can surface labels such as `Mixed receipt families: food/grocery, vehicle supplies`.
- Added regression coverage for OCR-to-expense parse propagation on a generic
  market receipt with grocery and vehicle-supply lines.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves OCR item family mix through parser diagnostics" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "generic fuel grocery and hardware receipts keep local parser roles" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using mixed-family status
  in assisted review copy and line classification affordances without adding a
  noisy control panel or exposing raw receipt text.

### Receipt Camera Reopen Pass 1193: Assisted Review Family Guidance Chip

Status: complete.

What changed:
- Surfaced the OCR-derived item-family summary in the assisted receipt review
  as a compact chip, instead of burying it in diagnostics.
- Used the mixed-family status to mark receipts that likely need closer
  Business, Personal, or Mixed classification review.
- Kept the guidance privacy-safe: only family labels/count-derived status are
  shown, not raw receipt text.
- Added a regression contract so the assisted review layer continues to expose
  `ocrItemExpenseFamilySummaryLabel` and `hasOcrMixedItemExpenseFamilies`.
- This pass is local OCR/parser/review guidance only; no cloud, PDF, Firebase,
  inventory, maintenance, native camera backend, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local OCR/parser only. Next target is strengthening family-aware line
  review in the parse model so mixed-family receipts can produce clearer
  Business/Personal/Mixed defaults and warnings without forcing cloud help.

### Receipt Camera Reopen Pass 1194: Parser-Side Item Family Diagnostics

Status: complete.

What changed:
- Added parser-side item-family counts, status, and summary labels to
  `ExpenseReceiptParseDiagnostics`.
- Added parser task buckets for parsed receipt families:
  - `parser_expense_family_<family>_item`
  - `parser_expense_family_single_receipt`
  - `parser_expense_family_mixed_receipt`
- Let OCR source evidence upgrade only generic/unknown parser families, so a
  line like `BANANAS 4011 1.29` can carry the OCR `food_or_grocery` family
  instead of staying stuck as `general_expense`.
- Recomputed OCR-backed parser-family diagnostics from enriched parsed lines,
  keeping direct parser and OCR parser review guidance aligned.
- Updated the assisted review chip to fall back from OCR family summary to
  parser family summary and to use the combined mixed-family flag.
- This pass is local OCR/parser/review guidance only; no cloud, PDF, Firebase,
  inventory, maintenance, native camera backend, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves OCR item family mix through parser diagnostics" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local OCR/parser only. Next target is category-family defaulting for
  common receipt lines so more generic food, vehicle-supply, material, and fuel
  rows become useful without cloud parser packs.

### Receipt Camera Reopen Pass 1195: Generic Market Family Classification

Status: complete.

What changed:
- Expanded the local grocery keyword rule so common market rows like
  `BANANAS 4011 1.29` classify as groceries instead of generic expense.
- Added grocery/category family mapping so `Groceries` rows carry the
  `food_or_grocery` parser family.
- Added a direct parser regression for a generic market receipt containing
  grocery and vehicle-supply lines.
- Confirmed the parser-side family status becomes `mixed_item_families` with
  the summary `Parser mixed families: food/grocery, vehicle supplies`.
- Confirmed the OCR-backed parser family-mix regression still passes after the
  local category improvement.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, native camera backend, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_category_keywords.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_category_keywords.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "classifies generic market grocery and vehicle supply families locally" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves OCR item family mix through parser diagnostics" -r compact`

Next camera/OCR focus:
- Continue local OCR/parser only. Next target is expanding local category-family
  coverage for common fuel/convenience and hardware receipts while keeping
  tender/reference rows from becoming fake item prices.

### Receipt Camera Reopen Pass 1196: Hybrid Travel Mart Family Health

Status: complete.

What changed:
- Added a local parser regression for a hybrid travel-mart receipt containing:
  - split-row diesel fuel,
  - convenience food/grocery lines,
  - a hardware/material line,
  - card tender and auth/reference rows.
- Proved tender/auth/reference rows stay excluded instead of becoming fake
  expense item prices.
- Proved the receipt reconciles locally with merchant subtotal, tax, and total.
- Aligned parser category-family health diagnostics so grocery/meal categories
  report under `food_or_grocery` instead of generic family buckets.
- Confirmed the previous generic market mixed-family regression still passes.
- This pass is local OCR/parser intelligence only; no cloud, PDF, Firebase,
  inventory, maintenance, native camera backend, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_category_keywords.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "keeps travel mart fuel food and hardware lines local without tender fakes" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "classifies generic market grocery and vehicle supply families locally" -r compact`

Next camera/OCR focus:
- Continue local OCR/parser only. Next target is strengthening OCR-to-parser
  handoff for hybrid fuel/convenience receipts so source line roles, family
  hints, and tender exclusion agree before assisted review.

### Receipt Camera Reopen Pass 1197: Hybrid Travel Mart OCR Handoff

Status: complete.

What changed:
- Added an OCR handoff regression for a hybrid travel-mart receipt with:
  - split-row diesel fuel evidence,
  - food/grocery lines,
  - a material line,
  - merchandise subtotal, tax, total due,
  - card/auth/reference tender evidence.
- Added `MERCH TOTAL` as a local OCR subtotal alias alongside
  `MERCHANDISE TOTAL`.
- Proved card/auth/reference rows stay out of OCR item lines while remaining
  available as tender evidence.
- Proved OCR family hints include fuel, food/grocery, and materials on the same
  receipt, producing mixed-family handoff evidence before assisted review.
- Confirmed the previous generic fuel/grocery/hardware OCR matrix still passes.
- This pass is local OCR/parser handoff intelligence only; no cloud, PDF,
  Firebase, inventory, maintenance, native camera backend, or 5.5 work was
  touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze test/receipt_ocr_service_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "hybrid travel mart OCR handoff keeps families and tenders separated" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "generic fuel grocery and hardware receipts keep local parser roles" -r compact`

Next camera/OCR focus:
- Continue local OCR/parser only. Next target is connecting this hybrid OCR
  family evidence through `parseExpenseReceiptOcrResult` so the final assisted
  expense review gets the same mixed-family and tender-exclusion proof.
