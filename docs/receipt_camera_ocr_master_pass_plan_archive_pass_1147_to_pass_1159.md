# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1147: Total-Only Line Math Readiness

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1147: Total-Only Line Math Readiness

Status: complete.

What changed:
- Added OCR handoff coverage for total-only receipts where subtotal and tax are
  missing but parser-ready item lines add up to the receipt total.
- Added explicit privacy-safe parser task buckets for total-only line math:
  `total_only_line_math_reconciled` and `total_only_line_math_needs_review`,
  while preserving the existing `receipt_total_only_ready` behavior.
- Verified total-only receipts can still be local-assisted-review ready when the
  item subtotal reconciles with the primary total, instead of falling back to a
  proof-only experience.
- Verified repeated payment rows and vehicle-supply quantity handoff behavior
  still pass after the added readiness signal.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "total-only receipt is ready when parser item lines reconcile" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "repeated payment totals do not become extra item lines" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "vehicle supply OCR handoff preserves quantity and terminal amount" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving tolerance for
  OCR-swapped money separators and comma/period mistakes in line totals without
  accidentally accepting non-money IDs as prices.

### Receipt Camera Reopen Pass 1148: Separatorless Money OCR Tolerance

Status: complete.

What changed:
- Added conservative local OCR amount recovery for receipt rows where OCR drops
  the cents separator, such as `SHOP TOWELS 1698`, `TAX 140`, and `TOTAL 1838`.
- Kept the recovery guarded by receipt-money context so UPC, barcode, SKU,
  license, auth, terminal, invoice, transaction, serial, and address-like rows
  do not become false prices.
- Routed inferred amounts through the same terminal amount, safe expense amount,
  summary, tax, total, and parser-ready pathways as explicit `12.34` or `12,34`
  money values.
- Added regression coverage proving inferred item/tax/total rows work while UPC
  and SKU rows stay out of price candidates and privacy-safe handoff text.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless OCR money rows are inferred only with safe context" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "total-only receipt is ready when parser item lines reconcile" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "repeated payment totals do not become extra item lines" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not turn barcode or UPC money rows into receipt lines" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving parser handoff
  diagnostics for separatorless amount recovery so the app can explain when OCR
  inferred cents and when the user should review the line.

### Receipt Camera Reopen Pass 1149: Separatorless Money Diagnostics

Status: complete.

What changed:
- Added a `separatorless_money_inferred` OCR parser line trait for rows where
  local OCR safely inferred cents from a terminal amount with a missing separator.
- Added privacy-safe line ids and parser task counts for inferred separatorless
  money rows so review screens and diagnostics can explain that OCR recovered the
  amount without exposing receipt text or prices.
- Added a compact parser summary phrase for inferred cents, for example
  `3 OCR amounts were inferred from missing cents separator`.
- Extended the separatorless money regression to verify item, tax, and total
  inferred line ids, parser task counts, diagnostics summary, and privacy-safe
  contract redaction.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless OCR money rows are inferred only with safe context" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "total-only receipt is ready when parser item lines reconcile" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "repeated payment totals do not become extra item lines" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving OCR tolerance
  for trailing tax-code letters on separatorless item totals such as `799T`
  without treating SKU or UPC rows as money.

### Receipt Camera Reopen Pass 1150: Separatorless SKU Tax-Code Item Totals

Status: complete.

What changed:
- Hardened separatorless OCR amount inference for item rows with trailing tax-code
  letters, such as `SKU 123456 PVC GLUE 799T`.
- Refined SKU/code guards so SKU-prefixed rows can infer cents only when the row
  also contains real expense item-family text; bare UPC, barcode, QR, serial, and
  SKU rows remain protected from false price detection.
- Added OCR handoff regression coverage proving `799T` is interpreted as 7.99
  for the material item row, while UPC text stays out of price candidates.
- Verified the direct expense parser compact-cents/tax-suffix behavior still
  aligns with the OCR handoff behavior.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless SKU item totals allow tax-code suffixes safely" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless OCR money rows are inferred only with safe context" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses compact OCR cents and tax suffixes on item rows" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not turn barcode or UPC money rows into receipt lines" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening receipt
  line confidence for low-light or blurry OCR where `O`, `0`, `I`, `1`, and `S`
  are swapped inside common total/tax/fuel words.

### Receipt Camera Reopen Pass 1151: Summary Keyword OCR Swap Tolerance

Status: complete.

What changed:
- Added OCR handoff tolerance for common summary word character swaps such as
  `SUBT0TAL`, `T4X`, `T0TAL`, and `AM0UNT`.
- Reused the normalized summary keyword text inside separatorless cents recovery
  so rows like `T4X 140` and `T0TAL 1838` become tax/total candidates instead
  of being missed.
- Added regression coverage proving swapped subtotal, tax, and total rows expose
  the right primary amounts, summary math, mixed-classification readiness, and
  separatorless-money diagnostics.
- Verified separatorless item and SKU/tax-code behavior still works, and direct
  parser noisy fuel regressions remain green.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr summary word swaps still expose subtotal tax and total" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless OCR money rows are inferred only with safe context" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless SKU item totals allow tax-code suffixes safely" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves split-row fuel OCR detail readiness through parser handoff" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses noisy neighboring fuel detail labels without merchant profile" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving OCR amount
  parsing when the decimal point is read as a space, such as `SUBTOTAL 41 87`,
  while preserving barcode and receipt-id protections.

### Receipt Camera Reopen Pass 1152: Split-Cents OCR Amount Tolerance

Status: complete.

What changed:
- Added local OCR amount recovery for rows where the decimal separator is read
  as a space, such as `SHOP TOWELS 16 98`, `SUBTOTAL 16 98`, `TAX 1 40`, and
  `TOTAL 18 38`.
- Kept split-cent recovery separate from separatorless-cent recovery so
  separatorless diagnostics remain accurate and do not fire for `41 87` style
  rows.
- Reused the same safe inferred-money context guard so UPC, barcode, SKU-only,
  license, auth, terminal, invoice, transaction, serial, and address-like rows
  do not become false prices.
- Added regression coverage proving split-cent item, subtotal, tax, and total
  rows work while a UPC row with nearby numbers remains out of price candidates.
- Verified separatorless cents, SKU tax-code suffixes, direct parser compact OCR
  cents, and barcode/UPC protections still pass.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "split OCR cents rows are inferred without accepting UPC numbers" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr summary word swaps still expose subtotal tax and total" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless OCR money rows are inferred only with safe context" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless SKU item totals allow tax-code suffixes safely" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses compact OCR cents and tax suffixes on item rows" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not turn barcode or UPC money rows into receipt lines" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding privacy-safe
  diagnostics for split-cent amount recovery so review and telemetry can
  distinguish missing separators from spaced separators.

### Receipt Camera Reopen Pass 1153: Split-Cents Money Diagnostics

Status: complete.

What changed:
- Added a `split_cents_money_inferred` OCR parser line trait for rows where the
  decimal separator was read as a space, such as `16 98`.
- Added privacy-safe split-cent line ids and parser task counts so diagnostics
  can distinguish spaced-cent recovery from missing-separator recovery.
- Added a compact parser summary phrase for split-cent recovery, for example
  `4 OCR amounts were inferred from spaced cents`.
- Extended the split-cent regression to verify item, subtotal, tax, and total
  split-cent line ids, parser task counts, diagnostics summary, and privacy-safe
  handoff redaction.
- Verified separatorless money and OCR summary word-swap regressions still pass.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "split OCR cents rows are inferred without accepting UPC numbers" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless OCR money rows are inferred only with safe context" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr summary word swaps still expose subtotal tax and total" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is reducing false item
  positives from receipt footer lines that contain ordinary words plus amounts,
  such as loyalty/reward/savings lines.

### Receipt Camera Reopen Pass 1154: Footer Reward Noise Exclusion

Status: complete.

What changed:
- Expanded local OCR item-candidate filtering so loyalty, reward, rewards,
  promo, promotion, rebate, markdown, and survey footer rows do not become
  expense item lines just because they contain words and amounts.
- Added regression coverage with a real item plus loyalty/reward, promo discount,
  and survey bonus rows, proving only the purchased item is exposed as an item
  candidate.
- Verified footer amount rows remain non-item parser signals while the receipt
  total, total-only reconciliation, and privacy-safe handoff behavior stay intact.
- Verified existing fuel loyalty/reward summary handling and repeated payment
  total separation still pass.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "loyalty reward promo and survey footer amounts stay out of items" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "fuel receipt summary labels do not swallow pump item lines" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "repeated payment totals do not become extra item lines" -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is recognizing return,
  refund, and store-credit footer rows as non-purchased item evidence while
  preserving legitimate negative/return expense parser behavior for direct text.

### Receipt Camera Reopen Pass 1155: Return Refund Footer Noise Exclusion

Status: complete.

What changed:
- Added local OCR handoff filtering for return, refund, credit balance, and
  store-credit rows so those footer/adjustment amounts do not become purchased
  item evidence.
- Prevented refund/return/store-credit total-like rows from becoming the primary
  receipt total, so `REFUND TOTAL 2.00` does not replace the actual final total.
- Tightened line-sequence review so store-credit/return adjustment rows before
  the final total do not make an otherwise clean receipt look out of order.
- Added regression coverage proving a receipt with one real item, return credit,
  store-credit balance, refund total, and a final total still exposes only the
  real item and final total to the assisted receipt handoff.
- Verified direct parser return and store-credit behavior still passes, including
  CR/trailing-minus returns and store-credit tenders.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "return refund and store credit footer amounts stay out of items" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "loyalty reward promo and survey footer amounts stay out of items" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses CR and trailing minus returns without treating them as payments" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores gift card and store credit tenders but keeps item totals" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is merchant/header recovery
  for receipts where OCR captures the store name with logo spacing, apostrophe
  loss, or split all-caps fragments before the date and line items.

### Receipt Camera Reopen Pass 1156: Damaged Merchant Header Recovery

Status: complete.

What changed:
- Added a conservative local OCR merchant-header recognizer for common receipt
  vendors where OCR damages logo text, including spaced letters and common
  character swaps such as `L 0 W E S`.
- Marked recognized damaged merchant headers with a privacy-safe
  `known_merchant_header_candidate` trait and line-id bucket, without exposing
  merchant text, receipt amounts, addresses, or item descriptions in the handoff
  contract.
- Let known damaged merchant headers become vendor candidates before fallback
  weak-header recovery, so app-assisted receipt review can keep the header line
  attached to the receipt instead of treating it as unknown text.
- Added regression coverage proving a damaged Lowe's-style header is recovered
  as the vendor line, carries only line IDs/counts through diagnostics, and still
  allows the item and final total to reconcile.
- Verified return/refund/store-credit filtering and separatorless money recovery
  still pass, and verified the direct parser's existing damaged Lowe's merchant
  profile normalization still passes.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "damaged logo-style merchant headers are recovered as vendor candidates" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "return refund and store credit footer amounts stay out of items" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "separatorless OCR money rows are inferred only with safe context" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "normalizes damaged Lowe OCR merchant text before matching profile" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving unknown-merchant
  header recovery for non-chain stores by ranking top-of-receipt text against
  date/item/total structure without turning metadata, address, cashier, or
  transaction rows into store names.

### Receipt Camera Reopen Pass 1157: Unknown Local Merchant Header Ranking

Status: complete.

What changed:
- Added a conservative unknown/local merchant header signal for store-name-like
  top receipt rows such as `RIVER ROAD MART 418`, including local terms like
  market, mart, road, stop, supply, hardware, parts, and store.
- Prevented road-style local merchant names from being swallowed by address
  metadata before vendor ranking runs, while still rejecting numbered street
  addresses, phone numbers, ZIP codes, cashier rows, transaction rows, and other
  metadata labels.
- Added privacy-safe `unknown_merchant_header_candidate` line-id and count
  diagnostics to the OCR parser handoff contract, matching the known merchant
  header recovery pattern without exposing store text, receipt amounts, or item
  descriptions.
- Added regression coverage proving an unknown local merchant header is recovered
  as the vendor line while cashier and transaction rows remain metadata.
- Verified damaged known-merchant header recovery, return/refund/store-credit
  filtering, and the direct parser address-row protection still pass.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown local merchant headers are ranked without metadata rows" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "damaged logo-style merchant headers are recovered as vendor candidates" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "return refund and store credit footer amounts stay out of items" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not attach merchant or address rows to first priced item" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is receipt date recovery for
  OCR variants where date separators, year length, or nearby time strings are
  damaged but the date still appears near the top of the receipt.

### Receipt Camera Reopen Pass 1158: Damaged Receipt Date Recovery

Status: complete.

What changed:
- Hardened local OCR date detection so damaged receipt dates such as
  `O7.O9.2I 13:14` are recognized as date evidence after OCR character
  normalization.
- Added plausible date validation for OCR handoff date candidates so loose
  numeric IDs, auth codes, transaction IDs, and impossible month/day/year groups
  do not become date evidence.
- Extended the direct expense receipt parser date pattern to accept dot-separated
  receipt dates such as `07.09.21`.
- Prevented direct parser line-item extraction from turning date rows into false
  priced receipt lines when dot-separated dates contain money-shaped fragments
  like `09.21`.
- Added regression coverage for OCR damaged dates and direct parser dot-separated
  dates.
- Verified unknown local merchant header recovery and baseline fuel parsing still
  pass.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_support_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_support_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt dates are recovered without numeric id false positives" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses dot separated OCR receipt dates" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown local merchant headers are ranked without metadata rows" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses fuel receipt text into editable receipt fields" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is OCR time recovery and
  time/transaction separation so receipt times are kept when useful but do not
  make transaction/auth rows look like dates, totals, or item lines.

### Receipt Camera Reopen Pass 1159: OCR Time Recovery And Transaction Separation

Status: complete.

What changed:
- Added local OCR time evidence detection for receipt timestamp rows, including
  damaged OCR variants such as `13.I4`.
- Added privacy-safe `timeCandidateLineIds`, `time_candidate` parser task
  counts, and parser signal counts to the OCR handoff contract so diagnostics
  can see whether a receipt time was detected without exposing receipt text.
- Tightened time detection so transaction, auth, terminal, trace, invoice, and
  reference rows do not become false timestamp evidence.
- Extended the direct expense receipt parser to normalize OCR-damaged date/time
  rows before extracting dates and times.
- Allowed dot-separated receipt times only when there is receipt date context or
  an explicit AM/PM marker, preventing ordinary prices such as `5.00` from
  being treated as clock times.
- Added regression coverage for damaged OCR time recovery, transaction/auth time
  false-positive suppression, dot-date regression safety, and Lowe's receipt ID
  protection.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_support_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parser_support_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt times are tracked without transaction id false positives" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses damaged OCR receipt time without transaction false positives" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses dot separated OCR receipt dates" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr damaged receipt dates are recovered without numeric id false positives" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not turn Lowe invoice identifiers into compact receipt totals" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is receipt sequence
  completeness: combine bottom-edge/total/subtotal evidence so long receipts can
  warn that another photo may be needed without blocking a readable receipt.
