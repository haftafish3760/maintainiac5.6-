# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1133: Unknown Fuel OCR Swap Normalization

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1133: Unknown Fuel OCR Swap Normalization

Status: complete.

What changed:
- Added targeted local OCR normalization for fuel receipt terms:
  `PR0DUCT`, `R0AD`, `D1ESEL`, `DIE5EL`, `GALL0NS`, and `GA1`/`GAl`.
- Added an unknown-station fuel regression with O/0 and I/1 OCR swaps across
  merchant, date, time, pump, product, gallons, price per gallon, and total.
- The regression proves the parser still extracts merchant, date, time, fuel
  line, gallons, unit price, diesel subtype, total, generic fuel readiness, and
  reconciled math.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "normalizes unknown fuel receipt OCR swaps before parsing" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving OCR/direct
  parser handling for partial fuel receipts where the fuel sale amount is read
  but gallons or unit price are missing, so the app asks for the right small
  correction instead of generic line review.

### Receipt Camera Reopen Pass 1134: Partial Fuel Detail Review Tokens

Status: complete.

What changed:
- Added local parser task tokens for amount-only or detail-incomplete fuel
  lines:
  `fuel_detail_needs_review`, `fuel_quantity_needs_review`, and
  `fuel_unit_price_needs_review`.
- `fuel_line_ready` now requires a fuel line with usable price plus fuel detail
  evidence, instead of treating plain amount-only fuel lines as fully ready.
- Complete split-row fuel receipts with gallons and unit price evidence still
  produce `fuel_line_ready` and `generic_fuel_receipt_ready`.
- Amount-only total receipts such as `UNLEADED FUEL 35.00` now keep the receipt
  total path but also expose the missing fuel quantity/detail task for a focused
  correction.
- Strengthened the assisted-review source guard for the new fuel-detail review
  helpers and tokens.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "accepts reconciled total-only fuel receipt without lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses split-row truck stop fuel receipts with rewards discounts" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is surfacing the focused
  missing-fuel-detail action label in the receipt review flow, without adding
  another bulky control panel.

### Receipt Camera Reopen Pass 1135: Focused Fuel Detail Review Actions

Status: complete.

What changed:
- Surfaced parser fuel-detail task tokens as compact assisted-review actions:
  `Check fuel gallons`, `Check fuel unit price`, and `Check fuel details`.
- Wired the labels from both direct parse diagnostics and OCR parser task
  counts so amount-only fuel receipts do not collapse into vague generic review
  copy.
- Kept the action layer compact; this does not add another control panel or
  cover the receipt image.
- Strengthened the assisted-review source guard so the fuel-detail labels and
  parser task tokens stay wired into the review screen.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "accepts reconciled total-only fuel receipt without lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses split-row truck stop fuel receipts with rewards discounts" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving fuel receipt
  OCR/parser continuity for receipts that expose gallons and unit price on
  neighboring lines but have noisy labels or incomplete row grouping.

### Receipt Camera Reopen Pass 1136: Noisy Fuel Detail Continuity

Status: complete.

What changed:
- Added fuel-specific local OCR normalization for noisy pump receipt labels such
  as `FUE1`, `PR1CE`, `GA1`, `V0L`, `D1ESEL`, and related short fuel signals.
- Prevented `PRICE / GAL 3.699` from being mistaken for `3.699` gallons when
  the parser is looking for loose quantity evidence.
- Let fuel detail review tokens trust recovered parsed quantity/unit evidence,
  so a locally recovered gallon count does not still trigger a vague missing
  fuel-detail prompt.
- Added an unknown-merchant noisy fuel receipt regression proving gallons, unit
  price, diesel subtype, total, fuel-ready tasking, and reconciled math are
  recovered without a merchant profile or cloud assist.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_fuel_parser.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_fuel_parser.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses noisy neighboring fuel detail labels without merchant profile" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "normalizes unknown fuel receipt OCR swaps before parsing" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the same fuel
  detail continuity visible through OCR parser handoff diagnostics so camera
  review can explain local readiness without exposing receipt text.

### Receipt Camera Reopen Pass 1137: Fuel Detail OCR Handoff Signals

Status: complete.

What changed:
- Added privacy-safe OCR parser line traits for fuel quantity evidence and fuel
  unit-price evidence.
- Added handoff line-id sets and parser task buckets for
  `fuel_quantity_signal`, `fuel_unit_price_signal`, and `fuel_detail_ready`.
- Exposed the new fuel detail handoff fields through the existing
  `privacySafeParserHandoffContract` as line ids/counts only, with no merchant,
  price, address, or receipt text content.
- Updated the compact OCR parser-signal summary so camera/review surfaces can
  report that fuel details are ready without showing private receipt content.
- Strengthened the unknown-fuel OCR regression and assisted-review source guard
  for the new local fuel detail handoff fields.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is carrying the OCR fuel
  detail readiness into the app-assisted review copy/actions without expanding
  the receipt photo control surface.

### Receipt Camera Reopen Pass 1138: Fuel Detail Ready Review Actions

Status: complete.

What changed:
- Carried OCR `fuel_detail_ready` into the assisted receipt review action layer.
- Added compact positive fuel actions: `Review fuel gallons/price` and
  `Classify fuel expense`.
- Kept missing-detail actions stronger; receipts with missing gallons or unit
  price still surface `Check fuel gallons`, `Check fuel unit price`, or
  `Check fuel details`.
- Added readiness copy for ready fuel receipts:
  `Parser readiness: fuel gallons and unit price are ready for app-assisted
  review.`
- Strengthened the assisted-review source guard for the new fuel-ready action
  path.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving local OCR
  handoff for fuel receipts where quantity and unit price live on separate
  neighboring OCR lines, so the review can still understand fuel readiness.

### Receipt Camera Reopen Pass 1139: Split-Row Fuel OCR Detail Evidence

Status: complete.

What changed:
- Broadened OCR fuel evidence detection so split fuel rows such as `GALLONS`,
  `PRICE/GAL`, `PRODUCT DIESEL`, `PUMP`, and OCR-damaged variants can be treated
  as fuel parser evidence even when they are not normal priced item lines.
- `fuel_quantity_signal` and `fuel_unit_price_signal` now collect evidence from
  all OCR parser lines, while `fuel_detail_ready` requires a priced ready fuel
  line plus quantity and unit-price evidence.
- Applied fuel-specific OCR normalization to the fuel-family classifier so
  variants like `PR1CE / GA1` still feed the local handoff.
- Added a split-row unknown fuel receipt OCR regression proving neighboring
  detail rows produce privacy-safe fuel detail readiness without merchant
  content, receipt text, or prices in the handoff contract.
- Kept the existing single-line unknown fuel regression working while allowing
  extra fuel evidence rows such as pump/detail lines.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "split-row fuel OCR handoff keeps neighboring detail evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making split-row fuel
  OCR readiness feed the direct expense parser handoff consistently when OCR
  text is converted into the assisted receipt form.

### Receipt Camera Reopen Pass 1140: Split-Row Fuel OCR-To-Parser Continuity

Status: complete.

What changed:
- Added a direct `parseExpenseReceiptOcrResult` regression for split-row fuel
  receipts where product, gallons, unit price, sale total, and tender appear on
  neighboring OCR lines.
- Proved the expense parser still extracts merchant, fuel line, gallons, unit
  price, diesel subtype, total, direct parser fuel readiness, and reconciled
  math from that OCR result.
- Proved OCR-specific parser task counts such as `fuel_quantity_signal`,
  `fuel_unit_price_signal`, and `fuel_detail_ready` survive into
  `ExpenseReceiptParseDiagnostics.ocrParserTaskCounts`.
- Kept the validation local-only and privacy-safe; no cloud, Firebase, PDF,
  inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `dart analyze test/expense_receipt_parser_test.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves split-row fuel OCR detail readiness through parser handoff" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "split-row fuel OCR handoff keeps neighboring detail evidence" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving fuel parser
  tolerance for receipts that show unit price before gallons or with abbreviated
  `PPG`/`QTY` labels across separate rows.

### Receipt Camera Reopen Pass 1141: Abbreviated Fuel Row Regression

Status: complete.

What changed:
- Added a local parser regression for fuel receipts where abbreviated unit price
  and quantity rows appear separately and in unit-price-first order:
  `PPG 3.699` followed by `QTY 12.349`.
- Proved the existing local fuel parser extracts merchant, fuel line, gallons,
  unit price, gasoline subtype, total, fuel readiness, no detail-review prompt,
  generic fuel receipt readiness, and reconciled math.
- No production parser code was needed for this pass; the value is locking down
  a real-world fuel receipt shape so future receipt/camera work cannot regress
  it.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `dart analyze test/expense_receipt_parser_test.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_fuel_parser.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses abbreviated fuel price and quantity rows in either order" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses noisy neighboring fuel detail labels without merchant profile" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves split-row fuel OCR detail readiness through parser handoff" -r compact`
- `git diff --check -- test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding OCR handoff
  coverage for the same `PPG`/`QTY` abbreviated fuel layout so camera OCR and
  direct parser behavior stay aligned.

### Receipt Camera Reopen Pass 1142: Abbreviated Fuel OCR Handoff Evidence

Status: complete.

What changed:
- Added OCR handoff coverage for abbreviated fuel receipts with `PPG` and `QTY`
  on separate lines.
- Added fuel-context-aware OCR evidence collection so generic quantity rows such
  as `QTY 12.349` count as fuel quantity evidence only when the surrounding OCR
  result has fuel context.
- Preserved privacy-safe behavior: the handoff exposes fuel quantity/unit-price
  signal counts and line ids, not merchant names, prices, addresses, or receipt
  text.
- Verified the abbreviated OCR handoff, split-row OCR handoff, OCR-to-parser
  split-row continuity, and direct parser abbreviated fuel regression together.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "abbreviated fuel OCR handoff keeps PPG and QTY detail evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "split-row fuel OCR handoff keeps neighboring detail evidence" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves split-row fuel OCR detail readiness through parser handoff" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses abbreviated fuel price and quantity rows in either order" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening non-fuel
  receipt parsing with the same local-first pattern, starting with vehicle
  supply receipts that include item quantity and unit price evidence.

### Receipt Camera Reopen Pass 1143: Vehicle Supply Quantity OCR Handoff

Status: complete.

What changed:
- Added direct parser coverage for non-maintenance vehicle-supply receipt rows
  with quantity and unit-price evidence, including `2 @ 8.49 16.98` and
  `QTY 3 4.50` styles.
- Added OCR handoff coverage for the same vehicle-supply shape so local camera
  OCR can pass quantity, terminal amount, parser task, and privacy-safe line-id
  evidence downstream without leaking receipt text.
- Expanded OCR vehicle-supply family matching to preserve existing behavior for
  legacy vehicle-supply rows while adding shop-towel and microfiber-style supply
  evidence.
- Taught OCR quantity traits to recognize raw `quantity @ unit price total` rows
  even when normalized OCR parser text strips the `@` character.
- Tightened fuel OCR classification so store headers such as `FUEL STOP` remain
  vendor evidence instead of being swallowed as fuel item lines, while real fuel
  product, pump, quantity, unit-price, and amount rows stay available as fuel
  detail evidence.
- Kept this pass local-only and out of maintenance flows; it only preserves
  existing OCR family behavior and adds non-maintenance vehicle-supply coverage.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart`
- `dart analyze test/receipt_ocr_service_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "vehicle supply OCR handoff preserves quantity and terminal amount" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser handoff classifies item families for downstream apps" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals use terminal amount for quantity rows" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses vehicle supply quantity and unit price rows" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "split-row fuel OCR handoff keeps neighboring detail evidence" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving merchant and
  header robustness for common receipt names that look like categories, so OCR
  does not confuse store identity with item evidence before the parser runs.

### Receipt Camera Reopen Pass 1144: Fuel-Named Merchant Header Guard

Status: complete.

What changed:
- Added OCR handoff regression coverage for a merchant named `FUEL STOP` so
  store names that contain a fuel/category word remain vendor evidence instead
  of becoming item lines.
- Verified the actual fuel purchase row still becomes a single parser-ready fuel
  item with quantity/unit/terminal amount evidence.
- Verified line order remains `expected_order`, mixed classification readiness
  stays `ready`, and merchant-independent fuel receipt readiness stays active.
- Verified the privacy-safe handoff contract exposes only parser task line ids
  and does not leak the merchant name or receipt amount.
- This pass reinforces the local OCR/parser boundary only; no cloud, PDF,
  Firebase, inventory, maintenance, or 5.5 work was touched.

Validation:
- `dart format test/receipt_ocr_service_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart`
- `dart analyze test/receipt_ocr_service_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "fuel-named merchant stays vendor while fuel line stays parser-ready" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals use terminal amount for quantity rows" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening merchant
  header detection for noisy receipt headers with phone/address/license metadata
  between the merchant and item rows.

### Receipt Camera Reopen Pass 1145: Noisy Fuel Header Metadata Guard

Status: complete.

What changed:
- Added OCR handoff coverage for a noisy fuel receipt header with merchant,
  business-license row, street/city address rows, phone row, terminal row, date,
  fuel item, fuel sale total, and card tender.
- Expanded local OCR metadata detection so business-license, license-number, and
  tax-id style rows stay metadata instead of being promoted to vendor or item
  evidence.
- Verified the merchant remains the primary vendor, noisy header rows remain
  metadata, the fuel item remains parser-ready, line order remains expected, and
  mixed classification readiness stays ready.
- Verified privacy-safe parser handoff output does not leak merchant, license,
  phone, or amount text.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "noisy fuel header keeps license address and terminal as metadata" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "fuel-named merchant stays vendor while fuel line stays parser-ready" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "address and phone rows are not promoted to vendor on damaged headers" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is hardening item/summary
  separation when receipt footers and tender rows repeat the same total amount.

### Receipt Camera Reopen Pass 1146: Repeated Payment Total Separation

Status: complete.

What changed:
- Added OCR handoff coverage for receipts that repeat the same amount across
  `TOTAL`, `AMOUNT PAID`, card tender, and change rows.
- Kept repeated payment rows from creating extra expense item lines while
  preserving the real receipt item, primary total, tender evidence, and summary
  math reconciliation.
- Extended OCR confidence and review-reason logic so raw `quantity @ unit price
  line total` rows are trusted the same way as word-based quantity/unit rows
  when they have a safe terminal line amount.
- Tightened fuel evidence so pump-only rows such as `PUMP 04` remain context
  instead of inflating fuel item counts; actual fuel product, quantity,
  unit-price, and amount rows still provide fuel detail evidence.
- Verified privacy-safe handoff output does not leak payment labels or amounts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "repeated payment totals do not become extra item lines" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "vehicle supply OCR handoff preserves quantity and terminal amount" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals use terminal amount for quantity rows" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "fuel receipt summary labels do not swallow pump item lines" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "split-row fuel OCR handoff keeps neighboring detail evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr recognizes common subtotal and total wording variants" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening low-detail
  merchant-independent receipts where subtotal/tax are missing but total and
  parser-ready line items reconcile within tolerance.
