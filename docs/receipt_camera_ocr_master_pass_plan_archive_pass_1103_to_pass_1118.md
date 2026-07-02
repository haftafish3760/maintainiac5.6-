# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1103: Overlap Confidence Review Priority

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1103: Overlap Confidence Review Priority

Status: complete.

What changed:
- The assisted receipt review action list now includes a compact overlap
  confidence action label when duplicate-overlap diagnostics provide one.
- Review chips now distinguish:
  - `Overlap: high-confidence overlap`
  - `Overlap: probable overlap`
  - `Overlap: probable OCR overlap`
  - `Overlap: review OCR overlap`
- Action priority now keeps `Compare ...` first, then ranks high-confidence
  overlap above probable overlap, and probable overlap above review-only OCR
  overlap.
- This keeps overlap urgency visible without adding another large review panel
  or exposing raw receipt item text.
- Strengthened the assisted-review source guard so the confidence chip and
  priority routing remain wired during future cleanup.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is grouping multiple
  duplicate-overlap anchors into a compact evidence summary so long receipts
  with several repeated sections do not flood the review actions.

### Receipt Camera Reopen Pass 1104: Compact Multi-Anchor Overlap Summary

Status: complete.

What changed:
- Added `parserDuplicateOverlapEvidenceSummaryLabel` as a derived diagnostics
  summary for repeated long-receipt overlap evidence.
- The summary combines safe counts and labels without receipt text, for example:
  `2 overlap anchors | high-confidence overlap | adjacent overlap`.
- Added a parser regression for a receipt with two separate repeated overlap
  anchors, proving the parser reports two anchors without flooding the review
  contract with raw item details.
- Strengthened the assisted-review source guard so the compact evidence summary
  remains part of the local OCR/parser contract.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "summarizes multiple duplicate overlap anchors compactly" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making parser review
  copy use the compact evidence summary where it helps, while keeping the
  receipt-photo review screen uncluttered.

### Receipt Camera Reopen Pass 1105: Compact Overlap Evidence Review Copy

Status: complete.

What changed:
- The assisted OCR review detail now includes the compact overlap evidence
  summary when duplicate-overlap diagnostics are present.
- The new copy is a single sentence in the existing review detail:
  `Overlap evidence: ...`.
- The evidence text remains privacy-safe because it uses counts, confidence
  labels, and window labels rather than raw receipt item text.
- Strengthened the assisted-review source guard so the evidence summary remains
  wired into the review detail instead of drifting into another large panel.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening parser
  overlap evidence for mixed exact/near anchors so review can summarize the
  strongest overlap risk without hiding weaker OCR-repeat evidence.

### Receipt Camera Reopen Pass 1106: Mixed Exact/Near Overlap Coverage

Status: complete.

What changed:
- Added a parser regression for receipts that contain both exact duplicate
  overlap lines and fuzzy OCR duplicate overlap lines.
- Verified the parser keeps both confidence labels:
  `high-confidence overlap` and `probable OCR overlap`.
- Verified the compact evidence summary stays honest and short:
  `2 overlap anchors | high-confidence overlap, probable OCR overlap | adjacent overlap`.
- No production parser changes were needed in this pass because the confidence
  label helper already preserved mixed overlap evidence correctly.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "summarizes mixed exact and fuzzy overlap anchors honestly" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding an OCR-source
  mixed-overlap regression so multi-photo receipt sections preserve both exact
  and fuzzy overlap confidence labels after OCR source enrichment.

### Receipt Camera Reopen Pass 1107: OCR-Source Mixed Overlap Anchors

Status: complete.

What changed:
- Added an OCR-source regression for a multi-section receipt that contains both
  exact duplicate overlap and fuzzy OCR duplicate overlap.
- Verified OCR source enrichment preserves both proof anchors:
  `Source line 3 -> Section 2 line 1` and
  `Section 2 line 2 -> Section 3 line 1`.
- Verified the parser keeps both confidence labels after OCR handoff:
  `high-confidence overlap` and `probable OCR overlap`.
- Verified the compact evidence summary remains short and safe after OCR source
  enrichment:
  `2 overlap anchors | high-confidence overlap, probable OCR overlap | adjacent overlap`.
- No production parser changes were needed in this pass because the OCR
  enrichment path already preserved the mixed overlap evidence.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors mixed exact and fuzzy OCR overlap review to source sections" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening overlap
  evidence for non-adjacent exact repeats separated by one OCR noise line so
  exact one-line-gap overlap gets a stronger summary than fuzzy one-line-gap
  overlap.

### Receipt Camera Reopen Pass 1108: Exact One-Line-Gap Overlap Strength

Status: complete.

What changed:
- Tightened `_DuplicateParsedLinePair.confidenceLabel` so exact repeated
  receipt lines separated by one OCR/noise line are labeled
  `high-confidence one-line overlap`.
- Fuzzy one-line-gap repeats still stay at `review OCR overlap`, keeping exact
  evidence stronger than fuzzy OCR evidence.
- Added a parser regression proving exact one-line-gap overlap reports:
  `1 overlap anchor | high-confidence one-line overlap | one-line gap overlap`.
- Strengthened the assisted-review source guard so the new confidence label
  stays in the local parser contract.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "labels exact one-line-gap overlap as high-confidence evidence" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "flags repeated overlap lines separated by one OCR noise line" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding the same exact
  one-line-gap strength regression through the OCR source-enrichment path so
  photo-based receipt sections keep the stronger label.

### Receipt Camera Reopen Pass 1109: OCR Exact One-Line-Gap Strength

Status: complete.

What changed:
- Added an OCR-source regression for exact repeated receipt lines separated by
  one OCR/noise line.
- Verified OCR source enrichment preserves the proof anchor:
  `Source line 3 -> Section 2 line 2`.
- Verified exact one-line-gap overlap keeps the stronger local parser label:
  `high-confidence one-line overlap`.
- Verified the compact evidence summary stays privacy-safe and precise:
  `1 overlap anchor | high-confidence one-line overlap | one-line gap overlap`.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors exact one-line-gap OCR overlap as high-confidence evidence" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening duplicate
  overlap evidence when repeated lines cross three or more receipt sections,
  keeping review summaries bounded and source anchors readable.

### Receipt Camera Reopen Pass 1110: Bounded Multi-Section Overlap Source Summary

Status: complete.

What changed:
- Added an OCR-source regression for a long receipt where repeated overlap
  lines cross four OCR source sections.
- Verified the parser keeps all three source anchors internally while the source
  summary remains bounded to two anchors plus `+1 more`.
- Verified the review instruction uses the bounded source summary instead of
  dumping every source anchor.
- Verified the compact evidence summary stays short and privacy-safe:
  `3 overlap anchors | high-confidence overlap | adjacent overlap`.
- No production parser changes were needed because the existing source summary
  and evidence summary helpers already handled the bounded UI contract.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "bounds OCR overlap source summaries across many sections" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is reducing repeated
  duplicate-overlap helper recomputation so source, window, and confidence
  labels come from one computed pair list without changing behavior.

### Receipt Camera Reopen Pass 1111: Shared Duplicate-Overlap Pair Evidence

Status: complete.

What changed:
- Refactored duplicate-overlap diagnostics so source labels, window labels,
  confidence labels, and task counts share one computed duplicate-pair list
  inside each parser diagnostics path.
- The OCR result path now computes duplicate pairs once after OCR line evidence
  has been applied, then reuses that list for source/window/confidence labels.
- The direct text parser diagnostics path now computes duplicate pairs once and
  reuses that list for task counts plus source/window/confidence labels.
- Removed the extra exact/near helper recomputation for task counts.
- Behavior is intentionally unchanged; this pass reduces local parser work and
  keeps overlap diagnostics aligned from the same evidence.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "bounds OCR overlap source summaries across many sections" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "summarizes mixed exact and fuzzy overlap anchors honestly" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors exact one-line-gap OCR overlap as high-confidence evidence" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a tiny
  source-guard assertion so future refactors do not reintroduce separate
  duplicate-pair recomputation for each overlap label family.

### Receipt Camera Reopen Pass 1112: Shared Pair Evidence Source Guard

Status: complete.

What changed:
- Strengthened the assisted receipt review source guard so future refactors
  must keep duplicate-overlap source labels, window labels, and confidence
  labels fed from `duplicateLinePairs`.
- The guard now checks for the shared `final duplicateLinePairs` pattern, the
  task-count handoff `duplicateLinePairs: duplicateLinePairs`, and the three
  label helpers using the shared list.
- This protects the local parser from drifting back into repeated overlap-pair
  recomputation as the receipt brain grows.

Validation:
- `dart format test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the duplicate
  overlap review warning reuse the same shared duplicate-pair summary path, so
  warning text and diagnostics cannot disagree on repeated-line counts.

### Receipt Camera Reopen Pass 1113: Shared Duplicate Warning Counts

Status: complete.

What changed:
- The direct text parser now computes duplicate-overlap pairs once immediately
  after parsed receipt line records are built.
- `_duplicateParsedLineReviewWarning` now receives the shared pair list instead
  of recomputing duplicate pairs from receipt lines.
- `_parseDiagnosticsFor` receives the same pair list, so warning text, task
  counts, source labels, window labels, and confidence labels all come from one
  evidence set.
- Strengthened the assisted-review source guard so warning generation stays on
  the shared `duplicateLinePairs` path.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "bounds OCR overlap source summaries across many sections" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding focused coverage
  that warning text count and diagnostics anchor count stay aligned for
  multiple duplicate-overlap anchors.

### Receipt Camera Reopen Pass 1114: Warning Count Anchor Alignment

Status: complete.

What changed:
- Strengthened the multi-anchor text parser regression so it now proves the
  user-facing warning count and diagnostics anchor count stay aligned.
- The regression now asserts the warning copy says
  `2 possible repeated receipt lines found...` while
  `parserDuplicateOverlapAnchorCount` is also `2`.
- This locks the shared duplicate-pair evidence path from Pass 1113 to a visible
  behavior contract instead of only a source-structure guard.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "summarizes multiple duplicate overlap anchors compactly" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding equivalent
  warning/anchor alignment coverage for near-duplicate OCR overlap so fuzzy
  repeated lines stay counted consistently.

### Receipt Camera Reopen Pass 1115: Near-Duplicate Warning Anchor Alignment

Status: complete.

What changed:
- Strengthened the adjacent near-duplicate OCR overlap regression so it now
  proves fuzzy repeated-line warnings and diagnostics anchors stay aligned.
- The regression asserts the user-facing warning says one possible repeated
  receipt line while `parserDuplicateOverlapAnchorCount` is also `1`.
- This gives the same alignment coverage for fuzzy OCR overlap that Pass 1114
  added for exact duplicate overlap.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent near duplicate lines from OCR overlap noise" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding warning/anchor
  alignment coverage for exact one-line-gap overlap so the stronger
  high-confidence one-line label stays consistent with warning counts.

### Receipt Camera Reopen Pass 1116: Exact One-Line Warning Anchor Alignment

Status: complete.

What changed:
- Strengthened the exact one-line-gap overlap regression so warning text,
  diagnostics anchor count, window labels, confidence labels, and evidence
  summary all stay aligned.
- The regression now proves the user-facing warning says one possible repeated
  receipt line while `parserDuplicateOverlapAnchorCount` is also `1`.
- This locks the stronger `high-confidence one-line overlap` path to the same
  shared duplicate-pair evidence used by warning counts.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "labels exact one-line-gap overlap as high-confidence evidence" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding OCR-source
  warning/anchor alignment coverage for exact one-line-gap overlap so
  photo-based receipt sections prove the same consistency.

### Receipt Camera Reopen Pass 1117: OCR Exact One-Line Warning Anchor Alignment

Status: complete.

What changed:
- Strengthened the OCR-source exact one-line-gap overlap regression so
  photo-based receipt sections prove the same warning/anchor alignment as the
  direct text parser path.
- The regression now asserts the user-facing warning says one possible repeated
  receipt line while `parserDuplicateOverlapAnchorCount` is also `1`.
- This keeps the stronger `high-confidence one-line overlap` OCR path tied to
  the shared duplicate-pair evidence used by warnings and diagnostics.

Validation:
- `dart format test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors exact one-line-gap OCR overlap as high-confidence evidence" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is improving warning copy
  so exact duplicate, exact one-line-gap, and fuzzy OCR overlap can use more
  specific guidance without increasing UI clutter.

### Receipt Camera Reopen Pass 1118: Specific Duplicate Overlap Warning Guidance

Status: complete.

What changed:
- `_duplicateParsedLineReviewWarning` now reuses shared duplicate-pair evidence
  to choose specific guidance instead of always using one generic
  long-receipt-overlap sentence.
- Exact adjacent overlap now tells the user to check adjacent receipt overlap.
- Exact one-line-gap overlap now tells the user to compare the repeated line
  around OCR noise.
- Fuzzy adjacent overlap now tells the user to compare fuzzy OCR overlap.
- Fuzzy one-line-gap overlap now tells the user to compare fuzzy OCR overlap
  around the noise line.
- Mixed exact/fuzzy overlap now tells the user to compare exact and fuzzy OCR
  overlap before saving.
- Strengthened parser regressions and the assisted-review source guard so this
  compact warning guidance stays tied to the shared duplicate-pair evidence
  path.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent duplicate lines from possible long receipt overlap" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "warns about adjacent near duplicate lines from OCR overlap noise" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "flags repeated overlap lines separated by one OCR noise line" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "labels exact one-line-gap overlap as high-confidence evidence" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "summarizes multiple duplicate overlap anchors compactly" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "summarizes mixed exact and fuzzy overlap anchors honestly" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors exact one-line-gap OCR overlap as high-confidence evidence" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "anchors mixed exact and fuzzy OCR overlap review to source sections" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_parser_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the
  long-receipt completion hints so the parser can distinguish likely partial
  receipt captures from complete receipts without blocking the user.
