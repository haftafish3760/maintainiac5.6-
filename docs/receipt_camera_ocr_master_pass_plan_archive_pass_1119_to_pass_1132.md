# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1119: Item-Only Receipt Missing Lower Section Review

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1119: Item-Only Receipt Missing Lower Section Review

Status: complete.

What changed:
- The direct local parser now detects priced receipt lines with no explicit
  subtotal or total as a likely partial receipt / missing lower-section case.
- Added a compact warning that tells the user to add the lower receipt section
  if this is a long receipt, or enter the total manually if it is complete.
- Parser task counts now include:
  - `receipt_missing_totals_manual_review`
  - `receipt_totals_text_missing_review`
  - `receipt_possible_lower_section_missing`
- Downstream readiness now stays in `expense_lines_need_review` for item-only
  receipt text instead of calling the receipt ready just because a category or
  material line was recognizable.
- Added parser regression coverage for a top-of-receipt Lowe's-style capture
  with item prices but no subtotal/total, plus source guards so the assisted
  receipt flow keeps the missing-lower-section task path.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes item-only receipt text to missing lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parser marks material receipt lines ready for inventory handoff" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "generic receipt layout keeps unknown gas station receipts parseable" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the OCR-source
  diagnostics expose the same possible-lower-section task when OCR handoff has
  item lines but subtotal/total candidates are absent.

### Receipt Camera Reopen Pass 1120: OCR Possible Lower Section Task Alignment

Status: complete.

What changed:
- OCR diagnostics now add `receipt_possible_lower_section_missing` when OCR
  found item/price candidates but no subtotal, tax, or total candidate lines.
- This aligns OCR-source diagnostics with the direct parser behavior from Pass
  1119: item lines without summary totals are not treated as ready without
  review.
- Strengthened OCR service regressions for:
  - missing totals with no bottom-edge coverage risk,
  - missing bottom-edge plus totals coverage risk,
  - user-confirmed-complete receipts that still need totals review.
- Strengthened the assisted-review source guard so the OCR service coverage
  hook and lower-section task token stay present.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr totals evidence can trigger missing bottom coverage decision" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics exposes receipt totals coverage evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "user confirmed complete receipt separates review from continuation" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Notes:
- An initial focused test command used a stale `--plain-name`; no tests ran for
  that command. The corrected test names above passed.

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is exposing the
  possible-lower-section task in user-facing parser action labels without
  adding visual clutter.

### Receipt Camera Reopen Pass 1121: Compact Lower-Section Review Action

Status: complete.

What changed:
- The assisted receipt review action list now recognizes
  `receipt_possible_lower_section_missing`.
- When totals are missing but OCR/parser found item lines, the compact next
  checks include `Check lower receipt section` before the generic totals/manual
  entry actions.
- User-confirmed receipts with the same signal keep `Check lower receipt lines`
  in the action list so the app does not silently trust a user-confirmed full
  receipt when local OCR still says the bottom may be missing.
- Added source guard coverage for the task token and action label so the local
  flow keeps the receipt-specific guidance without adding a new control panel.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr totals evidence can trigger missing bottom coverage decision" -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a direct
  parse-result diagnostic label for possible lower-section missing so parser
  tests can assert the user-facing wording without relying on source guards.

### Receipt Camera Reopen Pass 1122: Direct Parser Lower-Section Diagnostic Label

Status: complete.

What changed:
- `ExpenseReceiptParseDiagnostics` now exposes
  `hasParserPossibleLowerSectionMissing` from local parser task counts.
- `shouldSuggestLowerReceiptSection` now also listens to direct parser evidence,
  not just OCR-source section/coverage signals.
- The existing lower-section label/instruction contract now works for plain
  parsed receipt text that has priced item lines but no subtotal/total:
  `Totals may be lower down`.
- Strengthened the item-only parser regression to assert the model label and
  instruction directly.
- Strengthened the assisted-review source guard so the model keeps this
  diagnostics-level API.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes item-only receipt text to missing lower section review" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making lower-section
  review guidance prefer the direct parser label in the review summary chip
  before falling back to generic parser task summaries.

### Receipt Camera Reopen Pass 1123: Lower-Section Review Summary Priority

Status: complete.

What changed:
- The assisted receipt review guidance now promotes the direct parser
  lower-section label before generic parser task summaries.
- Math review and duplicate-overlap review still take priority, but when the
  issue is simply priced lines with missing subtotal/total, the summary can use
  `Totals may be lower down`.
- This keeps the guidance compact and receipt-specific without adding new UI
  controls.
- Strengthened the assisted-review source guard for the new summary-priority
  variable.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart lib/screens/expenses/data/expense_receipt_parse_models.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is expanding local parser
  coverage for receipt snippets that include subtotal but no final total, so
  partial summary sections get a clear review path too.

### Receipt Camera Reopen Pass 1124: Partial Summary Missing Final Total Review

Status: complete.

What changed:
- The local receipt parser now distinguishes itemized receipts with subtotal
  and/or tax evidence but no explicit final total from receipts with no summary
  totals at all.
- Added the warning: `Final receipt total was not found. Check the lower receipt
  section or confirm the inferred total before saving.`
- Added parser task coverage for `receipt_partial_totals_review`,
  `receipt_final_total_missing_review`, and
  `receipt_possible_lower_section_missing`.
- Kept downstream readiness in `expense_lines_need_review` when a final total
  was inferred from subtotal plus tax instead of explicitly read from the
  receipt.
- OCR diagnostics now emits the same final-total-missing task when subtotal/tax
  candidates exist but no total candidate exists.
- Assisted review actions now include `Check final receipt total` so the next
  step is clearer than a generic manual-total review.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes subtotal-only receipt text to final total review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics flags partial totals when final total is missing" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is recognizing receipts
  where a final total exists but subtotal/tax are missing, so simple gas station
  and small-store receipts can proceed with a lighter review path instead of
  being treated like broken long receipts.

### Receipt Camera Reopen Pass 1125: Total-Only Receipt Math Readiness

Status: complete.

What changed:
- Replaced the broad `Receipt total found, but subtotal and tax need review`
  warning with a math-aware total-only path.
- Total-only receipts with item lines that reconcile to the final total now get
  `receipt_total_only_ready` instead of a lower-section/manual-totals warning.
- Total-only receipts whose parsed item amounts do not reconcile now get
  `receipt_total_only_line_math_review` and remain in
  `expense_lines_need_review`.
- Receipt math confidence now explains clean total-only receipts as:
  `Receipt total matches parsed line amounts; subtotal and tax were not printed
  separately.`
- OCR parser handoff now exposes the same total-only ready/review task tokens
  and routes mismatched total-only receipts to review before vehicle/fuel-ready
  handoff.
- Added parser and OCR regressions for reconciled and mismatched total-only fuel
  receipts.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "accepts reconciled total-only fuel receipt without lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes mismatched total-only receipt lines to math review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant routes mismatched total-only math to review" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving the camera
  review action wording for total-only receipts so users see a compact
  `Use receipt total only` path for clean short receipts and a stronger math
  review path when item lines do not reconcile.

### Receipt Camera Reopen Pass 1126: Total-Only Review Action Labels

Status: complete.

What changed:
- The assisted receipt review action list now surfaces `Use receipt total only`
  when OCR/parser diagnostics mark a short total-only receipt as ready.
- Total-only receipts whose item amounts do not reconcile now surface
  `Review total-only math` plus the existing `Use receipt total only` fallback.
- Action priority now keeps total-only math review near subtotal/tax checks
  instead of burying it under generic labels.
- Strengthened the assisted-review source guard for the new action label and
  total-only task tokens.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "accepts reconciled total-only fuel receipt without lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes mismatched total-only receipt lines to math review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant routes mismatched total-only math to review" -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a local
  receipt-shape diagnostic for tender/card/change lines so gas-station and
  hardware receipts do not accidentally treat payment or balance lines as item
  purchases.

### Receipt Camera Reopen Pass 1127: Tender Balance Line Hardening

Status: complete.

What changed:
- Strengthened the direct receipt parser's administrative/tender vocabulary for
  gift-card and payment balance blocks.
- `BEGIN BAL`, `BEGINNING BAL`, `ENDING BAL`, `END BAL`, `TRANSACTION AMT`,
  and `AUTHCODE` now stay out of item parsing.
- Added a Lowe's-style regression that keeps `MERCH/GIFT`, auth code, begin
  balance, transaction amount, and ending balance lines from becoming expenses.
- Kept the existing OCR handoff aligned with its current tender/metadata model;
  the Lowe's OCR fixture now expects the current vendor-review task bucket
  instead of incorrectly expecting no review tasks.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores gift card balance rows so Lowes tender blocks stay out of items" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores tender rows so payment lines do not become expenses" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding privacy-safe
  parser task evidence for tender/balance rows so review telemetry can explain
  why payment rows were excluded without storing receipt text.

### Receipt Camera Reopen Pass 1128: Privacy-Safe Tender Exclusion Evidence

Status: complete.

What changed:
- Added parser-native excluded-line counts for payment, transaction, barcode,
  and private receipt proof rows.
- Parser task counts now expose privacy-safe evidence tokens:
  `payment_line_excluded`, `transaction_line_excluded`,
  `barcode_line_excluded`, `footer_line_excluded`, and
  `private_receipt_line_protected`.
- The parser combines generic layout analyzer signals with parser-native
  exclusion counts, using the stronger count where the layout analyzer is more
  conservative.
- Strengthened the Lowe's gift-card balance regression so it proves payment
  lines were excluded and counted without storing raw receipt text in
  diagnostics.
- Strengthened the assisted-review source guard for the new privacy-safe task
  tokens.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores gift card balance rows so Lowes tender blocks stay out of items" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening generic
  gas-station receipt parsing around pump, gallons, unit price, and tender lines
  so unknown fuel merchants work without a store-specific parser pack.

### Receipt Camera Reopen Pass 1129: Direct Parser Generic Fuel Readiness

Status: complete.

What changed:
- The direct local parser now exposes `fuel_line_ready` for parser-ready fuel
  item lines.
- When at least one ready fuel line and an explicit total are present, parser
  task counts now include `generic_fuel_receipt_ready`.
- This lines up direct parser diagnostics with the OCR handoff's existing
  generic fuel receipt readiness vocabulary.
- Strengthened the split-row truck-stop fuel regression so gallons, price per
  gallon, fuel sale, reward adjustment, and total evidence prove the new
  direct-parser readiness tokens.
- Strengthened the assisted-review source guard for the new fuel readiness
  tokens.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses split-row truck stop fuel receipts with rewards discounts" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening OCR handoff
  diagnostics so total-only fuel readiness and direct parser fuel readiness
  share the same privacy-safe reporting shape.

### Receipt Camera Reopen Pass 1130: OCR Fuel Readiness Reporting Alignment

Status: complete.

What changed:
- Added `fuelReadyLineIds` to the OCR parser handoff as the safe subset of fuel
  item lines that do not need review.
- OCR parser task line IDs and task counts now include `fuel_line_ready`,
  matching the direct parser token added in pass 1129.
- The privacy-safe OCR handoff contract now includes `fuelReadyLineIds` so
  diagnostics can report readiness without storing receipt text.
- Strengthened the unknown-fuel merchant regression so OCR handoff,
  diagnostics, and the privacy-safe contract all prove the same fuel-readiness
  shape.
- Strengthened the assisted-review source guard for `fuelReadyLineIds` and
  `fuel_line_ready`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a compact
  OCR/direct-parser readiness label for generic fuel receipts so review UI can
  distinguish a usable unknown gas-station receipt from a generic expense line
  review.

### Receipt Camera Reopen Pass 1131: Generic Fuel Readiness Labels

Status: complete.

What changed:
- `ExpenseReceiptParseDiagnostics` now recognizes direct parser and OCR fuel
  readiness through `hasParserGenericFuelReceiptReady`.
- `downstreamReadinessSummaryLabel` now returns `Fuel receipt review ready`
  when local parser/OCR evidence says the receipt is a usable fuel receipt.
- OCR parser task summaries now include `fuel ready` evidence when fuel-ready
  task counts are present.
- OCR diagnostic summary text now includes the compact phrase
  `1 fuel line ready` for ready unknown gas-station receipts.
- Strengthened direct parser, OCR handoff, and assisted-review guard tests for
  the fuel-ready label path.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses split-row truck stop fuel receipts with rewards discounts" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_parser_test.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening local
  parser confidence for unknown fuel receipts where OCR reads pump or product
  lines separately from the final fuel sale amount.

### Receipt Camera Reopen Pass 1132: Unknown Split-Row Fuel Regression

Status: complete.

What changed:
- Added a local parser regression for an unknown gas-station receipt with fuel
  details split across separate `PUMP`, `PRODUCT`, `GALLONS`, `PRICE/GAL`, and
  `FUEL SALE` rows.
- Proved the existing local parser can parse that shape without a merchant
  profile.
- The regression verifies merchant, fuel category, gallons, unit price, diesel
  subtype, fuel readiness task tokens, the compact fuel-ready review label, and
  reconciled receipt math.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses unknown split-row fuel receipts without a merchant profile" -r compact`
- `git diff --check -- test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is hardening OCR typo
  tolerance for unknown fuel receipts where `GAL`, `TOTAL`, or pump numbers are
  misread with common O/0 and I/1 substitutions.
