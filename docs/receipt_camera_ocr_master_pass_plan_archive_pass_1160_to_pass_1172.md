# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1160: Local Lower-Section Evidence Codes

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1160: Local Lower-Section Evidence Codes

Status: complete.

What changed:
- Added direct parser local coverage evidence for receipts that have priced item
  lines but no subtotal or total evidence.
- Added a separate local coverage evidence code for receipts that have subtotal
  or tax evidence but no final total.
- Reused the existing lower-section review path so the flow can say why it is
  suggesting another bottom receipt photo without pretending camera bottom-edge
  evidence exists when only text evidence is available.
- Preserved the existing accepted total-only receipt behavior so complete
  total-only fuel receipts are not pushed into a false lower-section warning.
- Added regression coverage for item-only, subtotal-only, and reconciled
  total-only receipt paths.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes item-only receipt text to missing lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes subtotal-only receipt text to final total review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "accepts reconciled total-only fuel receipt without lower section review" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is OCR line sequencing for
  multi-photo receipts: use source section order, duplicate overlap evidence,
  and summary-line placement to decide when stitched/combined receipt text is
  ready for line review versus still needing an overlap/order correction.

### Receipt Camera Reopen Pass 1161: Unified Receipt Sequence Review Status

Status: complete.

What changed:
- Added a derived `receiptSequenceReviewStatus` to parser diagnostics so receipt
  review can use one local status for overlap review, OCR section-order review,
  lower-section-needed review, ready line order, weak evidence, or no evidence.
- Added matching sequence review labels and instructions that reuse the existing
  duplicate-overlap, source-section, and lower-section guidance instead of
  creating another noisy control path.
- Covered the three primary routes with existing fixtures: missing lower
  section, repeated overlap, and complete total-only receipt ready.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes item-only receipt text to missing lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent duplicate lines from possible long receipt overlap" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "accepts reconciled total-only fuel receipt without lower section review" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is local merchant and
  summary placement resilience for gas-station and hardware-store receipts:
  improve merchant/date/summary ordering confidence without relying on a known
  merchant database.

### Receipt Camera Reopen Pass 1162: Direct Merchant Header Ranking

Status: complete.

What changed:
- Replaced first-line direct merchant fallback with a conservative top-header
  scoring pass for direct receipt parsing.
- Skipped generic receipt banners such as `SALE`, `WELCOME`, `CUSTOMER COPY`,
  and `OPEN 24 HOURS` before selecting a merchant.
- Preferred local merchant-name shapes such as fuel marts, markets, hardware
  stores, supply stores, auto parts, and travel stops without requiring a known
  merchant database.
- Preserved road-style merchant names like `RIVER ROAD MART` without treating
  them as addresses, while still rejecting real address/contact rows.
- Prevented fuel detail and money-bearing rows such as `FUEL SALE 67.51` or
  `GALLONS 18.250` from becoming merchant fallback text.
- Added regression coverage for unknown gas-station and hardware-store receipts
  with generic banners before the merchant name.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "merchant ranking skips generic banners before gas station name" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "merchant ranking skips sale header before unknown hardware store" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "generic receipt layout keeps unknown gas station receipts parseable" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "normalizes unknown fuel receipt OCR swaps before parsing" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is summary placement
  resilience for noisy receipts: keep subtotal/tax/total rows distinct from
  tender and item rows when the receipt uses compact or uncommon labels.

### Receipt Camera Reopen Pass 1163: Local Summary And Tender Hardening

Status: complete.

What changed:
- Extended direct receipt summary recognition for common-but-varied receipt
  labels such as `MERCH SUBTOTAL`, `TAXABLE SUBTOTAL`, `PRE-TAX AMOUNT`,
  `TOTAL DUE`, `AMOUNT DUE`, `TOTAL SALE`, `RECEIPT TOTAL`, `NET TOTAL`, and
  `INVOICE TOTAL`.
- Kept explicit subtotal/tax/total rows ahead of tender rows so hardware-store
  and market receipts with uncommon wording still reconcile without requiring a
  known merchant profile.
- Stopped using multiple tender/payment rows as a fake receipt total when the
  receipt never provides a real total; the parser now routes those receipts into
  lower-section/final-total review instead of confidently saving the last
  payment amount.
- Preserved the existing single-tender fallback for simple receipts that only
  show one card/cash payment amount and no explicit total.
- Added regression coverage for uncommon hardware summary labels and mixed
  tender rows without a final total.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not use multiple tender rows as the receipt total" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses uncommon hardware summary labels before tender rows" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "uses tender amount only when explicit receipt total is missing" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores gift card balance rows so Lowes tender blocks stay out of items" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is receipt bottom/summary
  completeness: combine missing-bottom evidence with detected summary terms so
  long receipt capture can ask for another photo only when the local text really
  looks incomplete.

### Receipt Camera Reopen Pass 1164: Footer-Aware Bottom Completeness

Status: complete.

What changed:
- Split local missing-total recovery into two safer paths: missing lower receipt
  section versus footer/barcode seen but totals still missing.
- When priced lines exist but subtotal/total are missing and no footer or
  barcode evidence is present, the parser still suggests adding the lower
  receipt section.
- When footer/barcode evidence is present but subtotal/total are missing, the
  parser now routes to OCR/crop/manual-total review instead of telling the user
  to add another photo that may not exist.
- Applied the same footer-aware behavior to subtotal/tax-without-final-total
  receipts: no footer means lower section may be missing; footer seen means
  review OCR/crop or confirm the inferred total.
- Added derived diagnostics so `shouldSuggestLowerReceiptSection` is false when
  the parser has footer-seen missing-total evidence instead of real lower
  section evidence.
- Added regression coverage for footer-seen receipts with no summary totals and
  footer-seen receipts with subtotal/tax but no final total, while preserving
  the original missing-lower-section behavior for genuinely incomplete text.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes footer-seen receipt without totals to OCR total review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes footer-seen subtotal receipt without final total to OCR review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes item-only receipt text to missing lower section review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes subtotal-only receipt text to final total review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not use multiple tender rows as the receipt total" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is OCR summary label parity:
  align local direct-parser total/subtotal wording with OCR candidate wording so
  unusual store receipts get the same summary interpretation whether text comes
  from live OCR, recovered capture, or imported photos.

### Receipt Camera Reopen Pass 1165: Direct Parser Summary Label Parity

Status: complete.

What changed:
- Brought direct text parsing closer to OCR summary candidate behavior for total
  labels such as `SALE AMOUNT`, `FUEL TOTAL`, `FUEL SALE`, `FUEL AMOUNT`,
  `PUMP TOTAL`, `TRANSACTION TOTAL`, `TRANSACTION AMOUNT`, and
  `TRANSACTION AMT`.
- Fixed a direct-parser double-counting bug where an explicit summary row such
  as `FUEL SALE 35.00` could be recognized as the receipt total and still be
  kept as a purchased item line.
- Kept existing total-only fuel behavior intact: a one-line fuel purchase with a
  matching total is ready for review without asking for another lower receipt
  photo.
- Added direct-parser regression coverage for fuel sale totals, transaction
  totals, and transaction amount wording, and validated it against the OCR-side
  wording test.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "direct parser recognizes OCR parity fuel and transaction totals" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "accepts reconciled total-only fuel receipt without lower section review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr recognizes common subtotal and total wording variants" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is OCR-damaged summary word
  parity for direct parsing: recognize common zero/letter substitutions in
  `subtotal`, `total`, `tax`, and `amount` without turning identifiers into
  receipt totals.

### Receipt Camera Reopen Pass 1166: Direct Parser OCR-Damaged Summary Words

Status: complete.

What changed:
- Added direct-parser summary keyword normalization for common OCR substitutions:
  `T0TAL` -> `TOTAL`, `SUBT0TAL` -> `SUBTOTAL`, `AM0UNT` -> `AMOUNT`, and
  `T4X`/`TAX` variants -> `TAX`.
- Routed subtotal, tax, total, tender, and ignored-summary checks through the
  normalized summary keyword text so direct parsing behaves closer to the OCR
  handoff on imperfect receipt text.
- Preserved the identifier guard and ignored balance/savings behavior so
  damaged summary-word recovery does not blindly promote receipt IDs, gift-card
  balances, savings rows, or tenders into false totals.
- Added direct-parser regression coverage for damaged subtotal/tax/total wording
  and damaged `AM0UNT DUE`, and validated against the existing OCR damaged-word
  summary test.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "direct parser recovers OCR damaged summary words" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "direct parser recognizes OCR parity fuel and transaction totals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr summary word swaps still expose subtotal tax and total" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tender/summary ambiguity
  diagnostics: keep `AMOUNT PAID`, `TRANSACTION AMT`, gift card, and split
  tender receipts accurate without losing final-total evidence.

### Receipt Camera Reopen Pass 1167: Payment-Style Total Fallback Guard

Status: complete.

What changed:
- Split direct-parser total evidence into stronger receipt totals and weaker
  payment-style total candidates.
- Strong totals such as `TOTAL`, `TOTAL DUE`, `INVOICE ... TOTAL`, and
  `TRANSACTION TOTAL` now win over later payment rows.
- Payment-style rows such as `AMOUNT PAID`, `TRANSACTION AMOUNT`, and
  `TRANSACTION AMT` are now fallback total evidence only when no stronger
  receipt total is present.
- Single payment-style totals still work for receipts that only show
  `TRANSACTION AMT` or `AMOUNT PAID`; multiple tender/payment rows remain review
  evidence instead of becoming a fake total.
- Added regression coverage for cash-back/card amount rows that are larger than
  the receipt total, Lowe's gift-card transaction blocks, single transaction
  amount fallback, existing single-tender fallback, and multiple-tender review.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not let payment-style totals override stronger receipt totals" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "uses single payment-style total when no stronger total is present" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "uses tender amount only when explicit receipt total is missing" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores gift card balance rows so Lowes tender blocks stay out of items" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not use multiple tender rows as the receipt total" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is split-tender evidence:
  when multiple tender rows exactly reconcile to item subtotal/explicit
  subtotal, classify the receipt as payment-split evidence for review instead of
  missing-bottom evidence.

### Receipt Camera Reopen Pass 1168: Split-Tender Visible-Line Evidence

Status: complete.

What changed:
- Added privacy-safe split-tender evidence to local receipt totals: tender row
  count and summed tender amount only.
- Multiple tender rows still do not become an entered receipt total by
  themselves.
- When multiple tender rows reconcile to the visible item lines or explicit
  subtotal, the parser now routes the receipt to split-payment review instead of
  telling the user to add a lower receipt photo.
- When multiple tender rows do not reconcile, the existing missing-total/lower
  section review behavior remains.
- Added regression coverage for matching split tenders, non-matching multiple
  tenders, and the payment-style total override guard from the previous pass.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_support_models.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_support_models.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes split tender matching visible lines to payment review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not use multiple tender rows as the receipt total" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not let payment-style totals override stronger receipt totals" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is direct parser tender
  privacy diagnostics: distinguish payment summary rows, card/auth rows, and
  customer-private tender details with content-free counters for Command One.

### Receipt Camera Reopen Pass 1169: Tender Privacy Diagnostic Subtypes

Status: complete.

What changed:
- Added content-free direct-parser subtype counters for excluded tender and
  private receipt rows.
- New local parser task counters distinguish payment summary rows, card tender
  rows, cash tender rows, stored-value/gift-card tender rows, tender balance
  detail rows, fleet/fuel-card tender rows, auth/approval rows, and
  reference/order/terminal/trace rows.
- Preserved existing broad `payment_line_excluded`,
  `transaction_line_excluded`, and `private_receipt_line_protected` counters.
- Added regression assertions to the Lowe's gift-card block and split-tender
  tests so diagnostics prove private rows were excluded without storing receipt
  text, card details, auth codes, or customer content.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores gift card balance rows so Lowes tender blocks stay out of items" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "routes split tender matching visible lines to payment review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "ignores tender rows so payment lines do not become expenses" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is fuel receipt parser
  resilience for unknown stations: keep pump/product/gallons/price-per-gallon
  rows together even when the total and payment rows are noisy.

### Receipt Camera Reopen Pass 1170: Unknown Fuel Label Resilience

Status: complete.

What changed:
- Expanded local unknown-fuel receipt detection for noisy labels including
  `GALNS`, `VOL`, `PRICE/G`, `$/GAL`, `FUEL AMT`, and `FUEL AMOUNT`.
- Fixed fuel unit-price extraction so `PRICE/G 3.699` is treated as unit price,
  not gallons.
- Added a narrow fallback fuel-line builder for separated-row fuel receipts
  where no normal item line survives but the receipt has strong pump/product,
  quantity, price-per-gallon, and total evidence.
- The fallback does not turn arbitrary totals into items; it only fires for
  strong fuel receipt evidence with a positive total.
- Added regression coverage for unknown station receipts using `PRICE/G`,
  `$/GAL`, `GALNS`, `VOL`, and noisy fuel total wording while preserving
  existing unknown split-row and abbreviated fuel tests.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_fuel_parser.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_fuel_parser.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses unknown fuel receipts with noisy abbreviated fuel labels" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses unknown split-row fuel receipts without a merchant profile" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses abbreviated fuel price and quantity rows in either order" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is fuel math diagnostics:
  warn when gallons times unit price does not match the fuel amount/total within
  tolerance, without blocking manual review.

### Receipt Camera Reopen Pass 1171: Fuel Amount Math Review

Status: complete.

What changed:
- Added local fuel math review detection for parsed fuel lines with quantity and
  unit price.
- Fuel lines now need detail review when `quantity * unit price` does not match
  the parsed fuel amount within tolerance.
- Added a content-free `fuel_amount_math_needs_review` parser task count.
- Preserved ready behavior for correctly reconciled unknown fuel receipts.
- Added regression coverage for a deliberately mismatched fuel amount while
  keeping the unknown-station noisy-label and split-row fuel tests green.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "flags fuel amount math mismatch for review" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses unknown fuel receipts with noisy abbreviated fuel labels" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses unknown split-row fuel receipts without a merchant profile" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is parser recovery for
  grocery/club/fuel hybrid receipts where convenience-store item lines and fuel
  lines appear on the same receipt.

### Receipt Camera Reopen Pass 1172: Hybrid Fuel And Store Item Coverage

Status: complete.

What changed:
- Added regression coverage for mixed convenience receipts where separated fuel
  rows and normal store items appear on the same receipt.
- Added regression coverage for club receipts where fuel and grocery items share
  one receipt.
- Verified the parser keeps fuel lines categorized as Fuel while coffee/snack
  lines remain Meals and case-water/snack-pack lines remain Groceries.
- Verified hybrid totals reconcile and fuel diagnostics still report one ready
  fuel line without swallowing non-fuel items.
- This pass hardened behavior through focused coverage; the existing local
  parser logic already handled these hybrid shapes after the prior fuel passes.
- This pass is local OCR/parser only; no cloud, PDF, Firebase, inventory,
  maintenance, or 5.5 work was touched.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_fuel_parser.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "keeps convenience fuel and store items separate on hybrid receipts" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "keeps club fuel and grocery items separate on one receipt" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "uses fuel signals for grocery and club fuel receipts" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is receipt date/time and
  merchant resilience on hybrid and fuel receipts with noisy register headers.
