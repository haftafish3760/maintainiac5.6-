# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1014: OCR Bottom-Continuation Action Label

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1014: OCR Bottom-Continuation Action Label

Status: complete.

What changed:
- Local OCR diagnostics now return `Add the bottom receipt section with
  overlap` when missing totals are combined with bottom-coverage risk.
- The softer OCR case where totals are missing but bottom coverage risk is not
  present still says to check the bottom section or enter the total manually.
- Added OCR evidence coverage proving the bottom-risk case carries the
  bottom-specific action label in `receiptTotalsCoverageEvidenceDiagnostics`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is exposing a clearer
  privacy-safe evidence label that says whether bottom-edge evidence,
  subtotal/total evidence, or both drove the continuation request.

### Receipt Camera Reopen Pass 1015: Privacy-Safe Bottom/Totals Evidence Label

Status: complete.

What changed:
- Added `receiptBottomTotalsEvidenceLabel` to local OCR diagnostics.
- The label distinguishes `bottom_edge_and_totals_missing`,
  `totals_missing_edge_ok`, `totals_ready_edge_risk`,
  `partial_totals_evidence`, `no_text`, and `totals_ready_edge_ok`.
- `receiptTotalsCoverageEvidenceDiagnostics` now includes that label so later
  review screens and Command One health can reason about the failure type
  without receipt text, merchant names, addresses, totals, or photos.
- Added tests for complete totals evidence, missing totals without bottom-edge
  risk, and missing totals with bottom-edge risk.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics exposes receipt totals coverage evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr totals evidence can trigger missing bottom coverage decision" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is feeding this
  bottom/totals evidence label into the receipt review handoff summary so the
  app-assisted receipt-details screen can show the right review state without
  exposing private receipt content.

### Receipt Camera Reopen Pass 1016: Bottom/Totals Evidence Review Handoff

Status: complete.

What changed:
- Expense receipt OCR completion metadata now includes
  `receiptBottomTotalsEvidenceLabel`.
- The receipt entry state-action path now routes the
  `receiptMissingBottomEdgeAndTotals` case to the bottom-edge/totals route
  result instead of the generic missing-totals route result.
- The assisted receipt review structure actions now say `Add bottom receipt
  section` for the bottom-edge-plus-missing-totals case.
- The structure summary now says to add the bottom receipt section with
  overlap when the bottom edge and subtotal/total lines were not found
  together.
- Added assisted review source guards for the metadata, route result split, and
  bottom-specific action copy.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is consolidating the user
  visible missing-bottom guidance so the camera ghost guide, OCR completion
  action, and assisted review summary all use the same bottom-section language.

### Receipt Camera Reopen Pass 1017: Bottom-Section Guidance Copy Consolidation

Status: complete.

What changed:
- Assisted receipt review now labels the bottom-edge-plus-missing-totals action
  as `Add bottom receipt section`.
- The bottom-edge alert now says to add the bottom receipt section and keep the
  last few readable lines visible for matching.
- Parser task action labels now use `Add bottom receipt section` for the
  `receipt_bottom_section_continuation_needed` and
  `receipt_missing_bottom_edge_and_totals` tasks.
- The capture coverage decision guidance now says `Add the bottom receipt
  photo with overlap` for the missing-bottom/totals case.
- Generic long-receipt continuation wording remains generic where the app does
  not specifically know the bottom section is missing.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the
  review-control recovery copy so generic and bottom-specific long-receipt
  actions stay distinct in the photo review controls.

### Receipt Camera Reopen Pass 1018: Review-Control Bottom Recovery Copy

Status: complete.

What changed:
- Single-photo receipt review recovery text now branches on
  `coverageDecision.isMissingBottomEdgeAndTotals`.
- The missing-bottom/totals branch says to add the bottom receipt section with
  overlap.
- The generic possible-continuation branch still says to add the next receipt
  section.
- Added layout source guards so the recovery copy cannot silently collapse the
  bottom-specific action back into generic wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "post-capture quality copy leads with action and evidence" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening local OCR
  total/subtotal detection variants so common receipt wording feeds the
  bottom-section decision more reliably.

### Receipt Camera Reopen Pass 1019: Local Totals Wording Variants

Status: complete.

What changed:
- Expanded subtotal detection beyond `subtotal` to include common receipt
  summary labels such as `merchandise total`, `item total`, `items total`,
  `pre-tax total`, `pre tax amount`, `taxable total`, and
  `taxable subtotal`.
- Expanded total detection to include labels such as `amount due`,
  `balance due`, `total sale`, `transaction total`, `transaction amount`,
  `transaction amt`, `receipt total`, and `net total`.
- Kept false-positive guards so beginning/ending balance, gift-card balance,
  saved/savings, and subtotal-style summary lines do not become receipt totals.
- Added a focused OCR test proving merchandise-total and transaction-total
  lines count as summary evidence while balance/savings lookalikes do not.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr recognizes common subtotal and total wording variants" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding fuel/gas receipt
  summary wording variants while keeping pump, card, and loyalty lines out of
  expense totals.

### Receipt Camera Reopen Pass 1020: Fuel Receipt Summary Variants

Status: complete.

What changed:
- Added local total detection for fuel-style summary labels such as
  `fuel total`, `fuel sale`, `fuel amount`, `pump total`, and `sale amount`.
- Kept pump/gallon product lines available as fuel item candidates instead of
  swallowing them as totals.
- Added a focused fuel receipt test proving `UNLEADED ... GAL` remains a fuel
  item candidate, `FUEL SALE` becomes the receipt total, and loyalty/balance
  lookalikes do not become totals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "fuel receipt summary labels do not swallow pump item lines" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening local
  parser handling for split/mixed receipts by making summary evidence and line
  evidence easier to audit before Business/Personal/Mixed classification.

### Receipt Camera Reopen Pass 1022: Mixed Classification Evidence Contract

Status: complete.

What changed:
- Added a privacy-safe mixed receipt classification readiness contract to the
  OCR parser handoff. It reports whether Business/Personal/Mixed review is
  ready, needs receipt totals, needs line items, needs safer item prices, needs
  section order review, needs line order review, or needs subtotal/tax/total
  math review.
- Added content-free diagnostics for mixed classification readiness:
  item-line counts, ready/review line counts, summary-line count, summary math
  status, line sequence status, source-section continuity status, and source
  section count.
- Included the mixed classification label and diagnostics in the privacy-safe
  OCR parser handoff contract and aggregate count buckets.
- Carried the mixed classification evidence into `ReceiptOcrDiagnostics` and
  the parser signal summary.
- Updated the assisted receipt review chip to use the OCR mixed-classification
  evidence when deeper expense parser diagnostics are not available yet.
- Added tests proving a clean parsed Lowe's-style receipt is ready for mixed
  classification and a generic review-only priced line is not trusted as
  classification-ready.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals flag generic priced lines for review" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving line-item
  amount confidence for messy retail/fuel receipt rows so classification-ready
  evidence depends on safer prices instead of merely finding a number.

### Receipt Camera Reopen Pass 1021: Bottom/Totals Ghost-Guide Contract

Status: complete.

What changed:
- Made the combined long-receipt rule explicit in
  `ReceiptPhotoCoverageDecision`: when bottom-edge evidence is missing and
  subtotal/total text evidence is also missing, the continuation contract is
  `bottom_edge_totals_missing_use_ghost_overlap`.
- Updated the shared capture/review handoff labels so this case says to use
  the ghost overlap guide, not just generic overlap or generic receipt-quality
  review.
- Updated assisted receipt review copy to tell the user to add the next
  receipt section with the ghost overlap guide before saving.
- Added focused guards proving this exact edge case stays wired from OCR
  evidence into camera-result handoff and assisted receipt review.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr totals evidence can trigger missing bottom coverage decision" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening local
  parser handling for split/mixed receipts by making summary evidence and line
  evidence easier to audit before Business/Personal/Mixed classification.

### Receipt Camera Reopen Pass 1023: Terminal Item Amount Confidence

Status: complete.

What changed:
- Added a safe terminal receipt amount signal for OCR item lines. A purchased
  item line now needs a line-total-style amount at the end of the row before it
  can count as parser-ready.
- Added `safe_terminal_line_amount`, `embedded_amount_review`, and
  `multiple_amounts_review` traits for local parser handoff and diagnostics.
- Prevented inventory-prep and parser-ready item status from trusting embedded
  prices, unit-price fragments, or other messy rows where the price is not in
  the receipt line-total position.
- Penalized item-line confidence when a money-looking value appears in the
  middle of the row, and added a clear review reason for that case.
- Added a focused regression proving `WIDGET 12.99 SKU 12345` remains a review
  item, does not become mixed-classification-ready, and keeps the receipt in
  `needs_safe_item_prices` until a human checks it.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals require terminal item amount before ready" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser handoff classifies item families for downstream apps" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "fuel receipt summary labels do not swallow pump item lines" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving receipt line
  amount handling for quantity/unit rows so the parser can distinguish unit
  price, quantity, and final line total without trusting the wrong amount.

### Receipt Camera Reopen Pass 1024: Quantity/Unit Terminal Amount Handling

Status: complete.

What changed:
- Added terminal-line amount accessors to OCR parser line signals so downstream
  receipt flows can distinguish the safe line total from earlier unit-price or
  quantity values on the same row.
- Treated quantity/unit rows with a safe terminal amount as parser-ready instead
  of automatically demoting them for having multiple numbers.
- Added `terminal_line_amount_selected` and
  `unit_or_quantity_amounts_present` traits when a row such as gallons plus unit
  price plus line total can safely use the final amount.
- Kept embedded or non-terminal prices in review-only mode so rows with messy
  numbers still cannot become mixed-classification-ready by accident.
- Added a fuel-style regression proving `UNLEADED 10.000 GAL 3.49 35.00`
  selects `35.00` as the item amount, keeps `3.49` as supporting evidence only,
  and preserves mixed-classification readiness.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals use terminal amount for quantity rows" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals require terminal item amount before ready" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser handoff classifies item families for downstream apps" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is expanding local receipt
  parser confidence around common fuel, hardware, and store-line layouts without
  requiring a known merchant pack.

### Receipt Camera Reopen Pass 1025: Ghost Guide AND-Condition Guard

Status: complete.

What changed:
- Added a regression guard proving the long-receipt ghost guide is not triggered
  by a weak/missing bottom-edge signal alone.
- Preserved the intended rule: the app should recommend the bottom-section ghost
  overlap flow only when bottom-edge coverage is weak and subtotal/total/amount
  evidence is missing together.
- Verified that if subtotal and total evidence are present, a weak edge signal
  remains a normal edge-check/review case instead of forcing another photo.

Validation:
- `dart format test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "detected totals do not force ghost guide when bottom edge is weak" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "detected totals avoid long receipt prompt when bottom is present" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening
  merchant-independent receipt structure so unknown gas stations, hardware
  stores, and small vendors still produce useful local parser evidence.

### Receipt Camera Reopen Pass 1026: Merchant-Independent Structure Evidence

Status: complete.

What changed:
- Added a merchant-independent receipt structure status to the local OCR parser
  handoff so unknown vendors can still be classified by receipt shape and line
  evidence.
- Added privacy-safe statuses for generic fuel, material, vehicle-supply, and
  general receipt readiness without depending on a known merchant pack.
- Carried the status into parser tasks, downstream readiness counts, the
  privacy-safe parser handoff contract, OCR diagnostics, and the parser summary
  label.
- Added unknown-vendor fuel and material fixtures proving a receipt can be
  locally useful while still keeping vendor names and amounts out of the
  privacy-safe contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown material merchant exposes merchant-independent structure" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser handoff classifies item families for downstream apps" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "fuel receipt summary labels do not swallow pump item lines" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving the generic
  receipt structure layer for unknown vendors with weak/missing headers so the
  app can still recover store/date/total/item evidence when OCR sees a receipt
  but the merchant header is damaged.

### Receipt Camera Reopen Pass 1027: Recoverable Missing Header Evidence

Status: complete.

What changed:
- Added a controlled missing-vendor recovery path for receipts where OCR cannot
  identify a store header but can still see a date, safe item prices, totals,
  and sane receipt line order.
- Added `headerRecoveryStatus`, `headerRecoveryLabel`, privacy-safe recovery
  diagnostics, and recovery evidence line ids to the local OCR parser handoff.
- Updated parser readiness so recoverable missing headers become
  `needs_vendor_review` instead of collapsing the whole receipt to
  `missing_vendor`.
- Updated downstream readiness so the receipt can continue as
  `receipt_header_needs_review` while still forcing the user to check the store
  name.
- Preserved stricter behavior for bad-order receipts: a missing/weak vendor with
  totals before item lines still remains a review case, not a recovered receipt.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "damaged merchant header recovers receipt structure with review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals flag totals before item lines for review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown fuel merchant exposes merchant-independent structure" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "unknown material merchant exposes merchant-independent structure" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening generic
  merchant/date inference for damaged headers without allowing metadata,
  payment, or address rows to become trusted vendor names.

### Receipt Camera Reopen Pass 1028: Address And Contact Vendor Suppression

Status: complete.

What changed:
- Added local address/contact detection so street-address, ZIP/state, and phone
  rows are treated as receipt metadata before vendor inference runs.
- Prevented damaged-header recovery from promoting address or contact rows into
  fake vendor names.
- Updated the Lowe's receipt regression so address rows are explicitly counted
  as metadata while the real store header remains the vendor candidate.
- Added a damaged-header fixture proving address and phone rows are suppressed,
  the receipt still recovers as `missing_vendor_recoverable`, and privacy-safe
  contracts do not leak address or phone text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "address and phone rows are not promoted to vendor on damaged headers" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "damaged merchant header recovers receipt structure with review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result exposes parser-ready ordered receipt line signals" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr parser line signals flag totals before item lines for review" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening local
  vendor recovery suggestions: keep the vendor field reviewable, surface why it
  was not trusted, and avoid storing raw address/contact text in diagnostics.
