# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1089: Compact Parsed-Line Source Proof Chips

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1089: Compact Parsed-Line Source Proof Chips

Status: complete.

What changed:
- The parsed receipt line evidence row now shows OCR source anchors as their own
  compact chip instead of only embedding the source inside the receipt evidence
  sentence.
- The customer/client proof chip now uses a dedicated proof label so section
  references such as `Section 2 line 1` are visually separate from the OCR source
  label and easier to reuse for later customer-safe redaction.
- The assisted-review source guard now checks that the parsed receipt UI keeps
  both the OCR source chip and the proof chip present.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is section-order guidance:
  use OCR section anchors and summary-word detection to help decide when the
  receipt likely needs another bottom photo, while keeping the decision advisory
  and never blocking the user from continuing.

### Receipt Camera Reopen Pass 1090: Advisory Section-Order Bottom Guidance

Status: complete.

What changed:
- Added privacy-safe OCR section continuity labels and instructions to
  `ExpenseReceiptParseDiagnostics`, including continuous sections, single
  section, missing gaps, out-of-order sections, duplicates, and no-text cases.
- The app-assisted receipt detail intro now adds section-order guidance to the
  existing bottom-section advisory when bottom edge plus subtotal/total evidence
  is missing together.
- The bottom-section alert now shows a compact section-order chip, giving the
  user a reason for the suggestion without showing raw receipt text, prices, or
  vendor names.
- Strengthened parser and source-guard tests so section continuity survives the
  OCR-to-parser handoff and remains visible in the receipt review source.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves OCR item review buckets through parser diagnostics" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using section-order
  status in the handoff/next-step copy so a single-section long receipt with no
  totals gets a clear "add the lower section" prompt, while a complete
  continuous-section receipt stays on the normal review path.

### Receipt Camera Reopen Pass 1091: Single-Section No-Total Lower-Section Handoff

Status: complete.

What changed:
- Added `shouldSuggestLowerReceiptSection` and lower-section review copy to
  `ExpenseReceiptParseDiagnostics`.
- A parsed OCR result with receipt text and item lines but no subtotal/total
  evidence now gets an advisory "totals may be lower down" path instead of
  being treated like a normal complete receipt.
- The app-assisted receipt detail intro now shows the same lower-section
  advisory, with a compact `Add Lower Section` action label, without blocking
  manual continuation.
- The accepted-photo handoff now uses the lower-section decision for parsed
  receipts so the next-step copy matches what the receipt review screen will
  ask the user to do.
- Added a parser regression for a single-section Walmart-style receipt with an
  item line and no total.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "suggests lower receipt section when OCR finds item text without totals" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "preserves OCR item review buckets through parser diagnostics" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is duplicate/overlap
  readiness in the parsed review: keep long-receipt overlap warnings tied to
  section anchors so repeated top/bottom lines are reviewable without creating
  duplicate expense charges.

### Receipt Camera Reopen Pass 1092: Structured Duplicate-Overlap Parser Review

Status: complete.

What changed:
- The local expense receipt parser now turns adjacent repeated parsed lines into
  structured parser task counts:
  - `long_receipt_duplicate_text`
  - `long_receipt_probable_overlap`
- The existing user-facing duplicate warning remains in place, but the parser
  diagnostics now also expose machine-readable overlap review state.
- Added `hasParserDuplicateOverlapReview` and
  `parserDuplicateOverlapReviewLabel` to `ExpenseReceiptParseDiagnostics`.
- The assisted receipt review summary now shows the overlap label when there is
  no louder math mismatch, so repeated ghost-overlap lines can be checked
  before saving instead of being silently trusted.
- Added parser and source-guard tests for duplicate/overlap review.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent duplicate lines from possible long receipt overlap" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is section-aware duplicate
  overlap: when repeated lines have OCR section anchors, show which source
  section/line needs review so users can compare the overlap area without
  exposing receipt text in diagnostics.

### Receipt Camera Reopen Pass 1093: Section-Aware Duplicate Overlap Review

Status: complete.

What changed:
- Added `parserDuplicateOverlapSourceLabels`,
  `hasParserDuplicateOverlapSourceLabels`, and
  `parserDuplicateOverlapSourceSummaryLabel` to
  `ExpenseReceiptParseDiagnostics`.
- The local parser now records privacy-safe duplicate-overlap anchors from the
  parsed receipt line proof labels instead of only saying a duplicate line
  exists.
- OCR parsing now refreshes those duplicate-overlap anchors after OCR line
  evidence has been attached, so multi-section receipts can point to source
  locations like `Source line 3 -> Section 2 line 1`.
- The duplicate-overlap review label now prefers anchored guidance, such as
  `Check repeated overlap near Line 3 -> Line 4`, while preserving the old
  generic label when no anchor is available.
- Added a focused OCR regression proving duplicate overlap can be tied to OCR
  section proof labels without exposing receipt item text in diagnostics.
- Strengthened the assisted-review source guard so the overlap anchor getters
  and anchored review label stay wired during later receipt-flow refactors.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors duplicate overlap review to OCR source sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent duplicate lines from possible long receipt overlap" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is carrying overlap-anchor
  evidence into the assisted receipt action row so the user has a clear,
  tappable way to compare duplicate overlap lines before the parsed expense is
  accepted.

### Receipt Camera Reopen Pass 1094: Anchored Overlap Review Actions

Status: complete.

What changed:
- Added `_parserDuplicateOverlapActionLabelsFor` to the assisted receipt review
  guidance so parse-level overlap anchors become actionable review chips.
- Anchored duplicate overlap now produces a compact action such as
  `Compare Line 3 -> Line 4` before the generic overlap actions.
- Kept the existing generic actions (`Confirm no duplicate charges` and
  `Review overlap area`) so the flow still works when section/source anchors
  are unavailable.
- Prioritized `Compare ...` actions alongside duplicate-line checks so the
  specific overlap comparison does not sink below unrelated review actions.
- Strengthened the assisted-review source guard for the new action provider,
  literal anchored action label, and action-priority prefix.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors duplicate overlap review to OCR source sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent duplicate lines from possible long receipt overlap" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is grouping repeated
  overlap anchors into a compact review model that can later drive a focused
  compare/edit surface without turning the review screen into a control jungle.

### Receipt Camera Reopen Pass 1095: Compact Overlap Review Instruction Model

Status: complete.

What changed:
- Added `parserDuplicateOverlapAnchorCount` to
  `ExpenseReceiptParseDiagnostics` so repeated-overlap review has a compact
  count separate from the raw parser task count.
- Added `parserDuplicateOverlapReviewInstruction` so the parser diagnostics own
  the user-safe instruction for comparing overlap anchors before saving.
- The assisted receipt review detail text now uses that diagnostic instruction
  instead of hardcoding duplicate-overlap guidance entirely in the UI layer.
- Parser regressions now verify the anchor count and exact instruction for
  both plain parsed receipts (`Line 3 -> Line 4`) and OCR section handoffs
  (`Source line 3 -> Section 2 line 1`).
- Strengthened source guards so the grouped overlap count and instruction stay
  wired into assisted review as the receipt UI keeps evolving.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors duplicate overlap review to OCR source sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent duplicate lines from possible long receipt overlap" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is expanding the parser's
  long-receipt overlap model from adjacent duplicates to near-duplicate
  repeated lines where OCR may slightly change spacing, casing, or punctuation
  across the overlap zone.

### Receipt Camera Reopen Pass 1096: Near-Duplicate OCR Overlap Detection

Status: complete.

What changed:
- Reworked adjacent duplicate detection into a compact
  `_DuplicateParsedLinePair` helper so exact duplicates and near-duplicates can
  share the same privacy-safe source-anchor flow.
- Added bounded edit-distance matching for adjacent same-price receipt lines
  where OCR changes a small amount of text, such as `PVC GLUE` versus
  `PVC CLUE`.
- Added the structured parser task `long_receipt_near_duplicate_text` and kept
  `long_receipt_probable_overlap` as the combined exact + near-duplicate
  overlap count.
- `hasParserDuplicateOverlapReview` now treats near-duplicate overlap as a
  review risk, and the existing anchored labels/instructions continue to point
  users to the receipt proof lines.
- The assisted review action builder now treats
  `long_receipt_near_duplicate_text` like duplicate overlap so users still get
  duplicate-charge review actions.
- Added a parser regression for OCR overlap noise where one repeated line has a
  one-character OCR difference.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent near duplicate lines from OCR overlap noise" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent duplicate lines from possible long receipt overlap" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a false-positive
  guard for near-duplicate overlap so adjacent same-price but genuinely
  different short items do not get merged into long-receipt overlap review.

### Receipt Camera Reopen Pass 1097: Short-Item Near-Overlap False-Positive Guard

Status: complete.

What changed:
- Added a parser regression proving short same-price neighboring items like
  `BOLT 1.99` and `BELT 1.99` do not trigger long-receipt overlap review.
- The test locks down the existing compact-length guard in
  `_parsedLineDescriptionSimilarity`, which keeps fuzzy overlap matching from
  becoming too aggressive on short item names.
- Verified the parser produces no `long_receipt_duplicate_text`,
  `long_receipt_near_duplicate_text`, or `long_receipt_probable_overlap` tasks
  for that short-item case.
- Kept the positive OCR-noise regression from Pass 1096 green so the guard does
  not weaken actual overlap detection.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not flag short same-price neighboring items as OCR overlap" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent near duplicate lines from OCR overlap noise" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding section-aware
  near-duplicate OCR overlap coverage so fuzzy repeated lines also retain
  multi-photo proof anchors.

### Receipt Camera Reopen Pass 1098: Section-Aware Near-Duplicate OCR Anchors

Status: complete.

What changed:
- Added an OCR regression proving near-duplicate overlap across two receipt
  sections keeps the same privacy-safe source proof anchor flow as exact
  duplicate overlap.
- The test uses a section handoff where OCR reads `PVC GLUE 7.99` at the end
  of section 1 and `PVC CLUE 7.99` at the start of section 2, then confirms
  `long_receipt_near_duplicate_text` is counted while
  `long_receipt_duplicate_text` stays zero.
- Verified the anchored review instruction remains
  `Compare Source line 3 -> Section 2 line 1...`, so the user can review the
  multi-photo overlap area without diagnostics exposing receipt item text.
- Strengthened the assisted-review source guard to keep the near-duplicate pair
  model, near match type, and bounded edit-distance helper visible during
  future parser refactors.

Validation:
- `dart format test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors near duplicate OCR overlap review to source sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors duplicate overlap review to OCR source sections" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is moving from adjacent
  overlap only to small-window overlap detection so repeated lines separated by
  one OCR noise line can still be caught safely.

### Receipt Camera Reopen Pass 1099: Small-Window Overlap Detection

Status: complete.

What changed:
- Extended duplicate/near-duplicate overlap detection from strictly adjacent
  parsed lines to a bounded two-line look-ahead window.
- The parser now catches repeated overlap lines separated by one OCR noise line,
  while still recording the same privacy-safe proof anchor labels.
- The helper stops at the first overlap match for each starting line so the
  same receipt line is not double-counted.
- Added a positive parser regression for `PVC GLUE 7.99`, one smudged OCR line,
  then `PVC CLUE 7.99`, which now anchors as `Line 3 -> Line 5`.
- Added a false-positive regression proving different same-price items across
  one normal item are not treated as long-receipt overlap.
- Strengthened the assisted-review source guard so the look-ahead window stays
  intentionally tiny (`index + 2`) during later refactors.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "flags repeated overlap lines separated by one OCR noise line" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "does not flag different same-price items across one normal item" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the small-window
  overlap evidence visible in parser diagnostics as windowed versus adjacent,
  so future UI can explain why a repeated line was flagged.

### Receipt Camera Reopen Pass 1100: Overlap Window Diagnostics

Status: complete.

What changed:
- Added `parserDuplicateOverlapWindowLabels`,
  `hasParserDuplicateOverlapWindowLabels`, and
  `parserDuplicateOverlapWindowSummaryLabel` to
  `ExpenseReceiptParseDiagnostics`.
- The parser now records whether an overlap anchor came from `adjacent overlap`
  or a bounded `one-line gap overlap`.
- The overlap review instruction now includes the window reason when available,
  e.g. `Compare Line 3 -> Line 5 (one-line gap overlap)...`.
- The overlap pair model now carries `lineDistance`, preserving why the parser
  flagged the repeated lines without exposing receipt item text.
- Strengthened parser tests for both adjacent near-duplicate overlap and
  one-line-gap overlap, including proof anchors and instruction copy.
- Strengthened the source guard so the intentionally tiny look-ahead window and
  window-label helper stay visible during future refactors.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "flags repeated overlap lines separated by one OCR noise line" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent near duplicate lines from OCR overlap noise" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a section-aware
  one-line-gap OCR regression so multi-photo receipts preserve proof anchors
  even when OCR inserts a priced noise line between repeated overlap lines.

### Receipt Camera Reopen Pass 1101: Section-Aware One-Line-Gap OCR Overlap

Status: complete.

What changed:
- Added an OCR regression for a multi-section receipt where the repeated
  overlap lines are separated by one priced OCR-noise line.
- The test proves `PVC GLUE 7.99`, `SMUDGED BARCODE TEXT 0.01`, then
  `PVC CLUE 7.99` is flagged as `long_receipt_near_duplicate_text` and
  `long_receipt_probable_overlap`.
- Verified the proof anchor survives OCR section enrichment as
  `Source line 3 -> Section 2 line 2`.
- Verified the review instruction includes the window reason:
  `Compare Source line 3 -> Section 2 line 2 (one-line gap overlap)...`.
- Updated older adjacent OCR overlap expectations so they now include the new
  `(adjacent overlap)` window reason from Pass 1100.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors one-line-gap OCR overlap review to source sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors near duplicate OCR overlap review to source sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors duplicate overlap review to OCR source sections" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a compact
  overlap confidence label so exact, near, adjacent, and one-line-gap overlap
  can be prioritized cleanly in review without exposing receipt text.

### Receipt Camera Reopen Pass 1102: Compact Overlap Confidence Labels

Status: complete.

What changed:
- Added `parserDuplicateOverlapConfidenceLabels`,
  `hasParserDuplicateOverlapConfidenceLabels`, and
  `parserDuplicateOverlapConfidenceSummaryLabel` to
  `ExpenseReceiptParseDiagnostics`.
- The parser now labels duplicate-overlap evidence without exposing receipt
  text:
  - `high-confidence overlap` for exact adjacent repeats.
  - `probable overlap` for exact repeats separated by one OCR/noise line.
  - `probable OCR overlap` for near adjacent OCR repeats.
  - `review OCR overlap` for near repeats separated by one OCR/noise line.
- The OCR handoff path and direct text parser path both populate the same
  confidence labels, so camera photos and imported OCR text stay consistent.
- Strengthened parser regressions for exact OCR overlap, adjacent near OCR
  overlap, and one-line-gap OCR overlap.
- Strengthened the assisted-review source guard so the compact confidence
  labels remain part of the local parser/review contract.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors duplicate overlap review to OCR source sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent near duplicate lines from OCR overlap noise" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors one-line-gap OCR overlap review to source sections" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is feeding compact overlap
  confidence into the assisted receipt review action priority, so exact overlap
  gets surfaced above fuzzy one-line-gap OCR overlap without adding noisy UI.
