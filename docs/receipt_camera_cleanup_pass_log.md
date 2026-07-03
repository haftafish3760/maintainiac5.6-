# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 517 - 01:17:01 EDT to 01:17:58 EDT

Scope:
- Hardened receipt section retake ordering so duplicate or unnormalized current
  section paths cannot make `indexOf` retake the wrong receipt slot.
- Added retake-order regression coverage proving ambiguous current section
  paths are rejected before replacement.
- Recorded `BUG-RECEIPT-0035` under `multi_photo_ordering`.
- Archived Pass 480 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial targeted analyzer failure by moving the current-path
  uniqueness helper where both retake builders can use it.
- Passed targeted Dart format and analyzer for retake ordering and focused
  retake-order regression coverage.
- Passed focused Flutter test
  `test/receipt_photo_review_retake_order_test.dart --plain-name "retake plan
  rejects duplicate current section paths"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 528 - 02:01:00 EDT to 02:05:00 EDT

Scope:
- Hardened OCR parser category and customer-proof line ID lists so duplicate
  stable line IDs do not appear twice in selectable/task/redaction lists.
- Preserved raw `stableLineIds` ordering so duplicate OCR rows remain auditable
  while actionable line-ID lists stay unique.
- Extended duplicate-ID regression coverage for parser task lists,
  inventory/material IDs, and customer-proof review IDs.
- Recorded `BUG-RECEIPT-0046` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format and analyzer for parser handoff line-ID lists,
  customer-proof lists, and parser handoff structure regression coverage.
- Passed focused Flutter test
  `test/receipt_ocr_service_parser_handoff_structure_test.dart --plain-name
  "parser handoff line id maps preserve first duplicate line id"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 529 - 02:12:33 EDT to 02:16:00 EDT

Scope:
- Hardened malformed retake section metadata so invalid retake-order evidence
  wins over preserved-slot evidence in receipt section order summaries.
- Added regression coverage proving an invalid middle-section retake reports
  `retake_order_invalid` and emits a matching privacy-safe evidence label.
- Recorded `BUG-RECEIPT-0047` under `multi_photo_ordering`.

Verification:
- Passed targeted Dart format and analyzer for retake section-order outcome
  logic and focused stitch scanner regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_stitch_scanner_test.dart --plain-name
  "malformed retake section metadata is counted without leaking paths"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 530 - 02:26:23 EDT to 02:31:00 EDT

Scope:
- Hardened receipt retake diagnostics so order metadata is generated only for
  replacement photo paths accepted by the retake order plan.
- Added regression coverage proving stale or extra replacement paths receive no
  retake order diagnostics.
- Recorded `BUG-RECEIPT-0048` under `multi_photo_ordering`.

Verification:
- Passed targeted Dart format and analyzer for retake order planning and
  focused retake-order regression coverage.
- Passed focused Flutter test
  `test/receipt_photo_review_retake_order_test.dart --plain-name "retake
  diagnostics reject stale replacement path lists"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 527 - 01:56:00 EDT to 02:00:00 EDT

Scope:
- Hardened OCR parser line-id metadata maps so duplicate stable line IDs also
  preserve the first role, parser bucket, expense family, parser hint, and
  customer-proof visibility.
- Extended duplicate-ID regression coverage across adjacent parser handoff and
  customer-proof maps.
- Recorded `BUG-RECEIPT-0045` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format and analyzer for parser handoff line maps,
  customer-proof maps, and parser handoff structure regression coverage.
- Passed focused Flutter test
  `test/receipt_ocr_service_parser_handoff_structure_test.dart --plain-name
  "parser handoff line id maps preserve first duplicate line id"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 526 - 01:50:00 EDT to 01:55:00 EDT

Scope:
- Hardened OCR parser handoff line-id lookup maps so duplicate stable line IDs
  preserve the first receipt line instead of silently overwriting it with a
  later line.
- Added regression coverage proving line number, proof label, draft, amount,
  and text maps stay pinned to the first duplicate line ID.
- Recorded `BUG-RECEIPT-0044` under `receipt_line_numbering`.
- Archived Pass 501 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial regression expectation to match the existing section-1
  `source line` label contract, then reran the focused chain.
- Passed targeted Dart format and analyzer for parser handoff line maps and
  parser handoff structure regression coverage.
- Passed focused Flutter test
  `test/receipt_ocr_service_parser_handoff_structure_test.dart --plain-name
  "parser handoff line id maps preserve first duplicate line id"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 525 - 01:46:00 EDT to 01:49:00 EDT

Scope:
- Hardened previous-section ghost-guide reason handling so uppercase or mixed
  native bridge reason codes still trigger bottom/totals overlap guidance.
- Added session regression coverage proving uppercase
  `MISSING_BOTTOM_EDGE_AND_TOTALS` normalizes to the bottom-section ghost policy.
- Recorded `BUG-RECEIPT-0043` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format and analyzer for native session ghost-guide
  policy and focused session regression coverage.
- Passed focused Flutter test
  `test/receipt_native_camera_session_limits_test.dart --plain-name "session
  carries previous section guide only for long receipt flow"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 524 - 01:41:00 EDT to 01:45:00 EDT

Scope:
- Hardened receipt coverage bottom-edge evidence so native
  `bottom_soft_or_missing` status alone is treated as missing bottom edge.
- Added a coverage regression proving status-only bottom-soft evidence still
  prompts for a bottom section when totals are missing.
- Recorded `BUG-RECEIPT-0042` under `camera_capture_quality`.
- Archived Pass 499 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for coverage evidence helpers and
  coverage totals regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_coverage_totals_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 523 - 01:36:00 EDT to 01:40:00 EDT

Scope:
- Hardened receipt coverage totals evidence so fractional subtotal/total
  candidate counts cannot be rounded into fake completion evidence.
- Added a coverage regression proving malformed fractional counts still prompt
  for a bottom receipt section when bottom edge and totals are missing.
- Recorded `BUG-RECEIPT-0041` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format and analyzer for coverage evidence helpers and
  coverage totals regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_coverage_totals_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 522 - 01:31:00 EDT to 01:35:00 EDT

Scope:
- Hardened kept-for-later receipt review results so staged source paths are
  normalized and de-duplicated before building stitch input metadata.
- Added regression coverage proving kept-for-later public paths, stitch input
  paths, diagnostics, and handoff counts agree after malformed duplicate input.
- Recorded `BUG-RECEIPT-0040` under `source_preservation`.
- Archived Pass 498 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for receipt capture models and
  camera-result regression coverage.
- Passed focused Flutter test `test/receipt_camera_result_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 521 - 01:26:00 EDT to 01:30:00 EDT

Scope:
- Tightened camera-result path validation so blank or untrimmed paths cannot
  produce per-photo quality diagnostics.
- Tightened reviewed-photo quality handoff path validation with the same
  normalized nonblank requirement.
- Added camera-result and lifecycle source regressions for malformed diagnostic
  paths.
- Recorded `BUG-RECEIPT-0039` under `source_preservation`.
- Archived Pass 496 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for camera result diagnostics,
  reviewed-photo handoff models, camera-result regression coverage, and
  lifecycle source regression coverage.
- Passed focused Flutter tests `test/receipt_camera_result_best_shot_ocr_test.dart`
  and `test/receipt_photo_review_save_lifecycle_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 520 - 01:25:00 EDT to 01:25:37 EDT

Scope:
- Hardened camera-result per-photo diagnostics so duplicate camera result paths
  or duplicate requested paths cannot attach first-section quality evidence to
  the wrong long-receipt section.
- Hardened reviewed-photo quality handoff so duplicate path lists do not attach
  ambiguous per-path quality checks.
- Added camera-result and source lifecycle regressions for duplicate photo path
  evidence.
- Recorded `BUG-RECEIPT-0038` under `camera_capture_quality`.
- Archived Pass 495 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for camera result diagnostics,
  reviewed-photo handoff models, camera-result regression coverage, and
  lifecycle source regression coverage.
- Passed focused Flutter tests `test/receipt_camera_result_best_shot_ocr_test.dart`
  and `test/receipt_photo_review_save_lifecycle_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 519 - 01:43:00 EDT to 01:48:00 EDT

Scope:
- Updated the receipt photo review lifecycle regression so it now requires the
  safer add/remove order-plan path from Pass 518.
- Added source-level coverage proving the old `indexOf(targetPhotoPath)`
  removal pattern does not come back.
- Recorded `BUG-RECEIPT-0037` under `qa_harness`.
- Archived Pass 494 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the lifecycle source regression.
- Passed focused Flutter test
  `test/receipt_photo_review_save_lifecycle_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 518 - 01:31:00 EDT to 01:39:00 EDT

Scope:
- Hardened long-receipt add-photo ordering so continuation photos insert after
  the same selected section slot that launched the camera, not the first
  matching path after async return.
- Hardened remove-photo ordering so confirmed removals delete the original
  selected section slot and reject ambiguous duplicate or stale section paths.
- Added insert/remove order plan regressions for duplicate current paths and
  stale async anchors.
- Recorded `BUG-RECEIPT-0036` under `multi_photo_ordering`.
- Archived Pass 493 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for photo review ordering actions,
  retake/order plans, and focused ordering regression coverage.
- Passed full focused Flutter test `test/receipt_photo_review_retake_order_test.dart`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 516 - 01:15:25 EDT to 01:16:19 EDT

Scope:
- Hardened in-entry receipt proof line labels so unsafe draft source IDs and
  generated manual IDs no longer appear in receipt review rows before save.
- Added source regression coverage proving the raw fallback-label path is gone.
- Recorded `BUG-RECEIPT-0034` under `privacy_redaction`.
- Archived Pass 479 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial regression string escaping syntax error, then reran the
  focused chain.
- Passed targeted Dart format and analyzer for draft receipt line labels and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 515 - 01:13:06 EDT to 01:14:21 EDT

Scope:
- Hardened in-entry receipt draft line redaction anchors so unsaved/manual line
  IDs that include typed descriptions use deterministic private-safe tokens.
- Hardened draft OCR line labels so unsafe source IDs fall back to a generic
  receipt-line label.
- Added source regression coverage proving the old raw draft-line ID fallback is
  gone from the assisted review entry model.
- Recorded `BUG-RECEIPT-0033` under `privacy_redaction`.
- Archived Pass 478 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test failure caused by asserting helper placement in
  the wrong source bundle, then tightened draft OCR line labels and reran.
- Passed targeted Dart format and analyzer for draft line models, computed
  fields, support helpers, and assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 514 - 01:09:30 EDT to 01:11:50 EDT

Scope:
- Hardened receipt line redaction anchors so manual/generated line IDs that
  contain typed item descriptions are replaced with deterministic private-safe
  tokens before entering privacy-safe contracts.
- Added regression coverage proving manual private item text and generated IDs
  do not appear in line review contracts.
- Recorded `BUG-RECEIPT-0032` under `privacy_redaction`.
- Archived Pass 477 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test failure where the line-number label still used a
  generated private-text ID, then reran the focused chain.
- Fixed a targeted analyzer style issue before commit.
- Passed targeted Dart format and analyzer for expense receipt line records and
  line-record regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_line_record_test.dart --plain-name "privacy-safe receipt
  line contracts never expose generated item ids"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 513 - 01:06:51 EDT to 01:08:06 EDT

Scope:
- Hardened native capture staging bottom-edge evidence so non-finite edge scores
  do not default to "present until OCR evidence" when native framing says the
  receipt may be cut off.
- Hardened staged recovery manifest diagnostics so non-finite numeric values are
  not written into JSON payloads.
- Added staging regression coverage for unusable native edge evidence.
- Recorded `BUG-RECEIPT-0031` under `camera_capture_quality`.
- Archived Pass 476 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial focused-test failure where non-finite diagnostics crashed
  recovery manifest JSON encoding, then reran the focused chain.
- Passed targeted Dart format and analyzer for native staging cleanup,
  diagnostics, safe diagnostics, and staging regression coverage.
- Passed focused Flutter test
  `test/receipt_native_capture_staging_test.dart --plain-name "native staging
  treats non-finite edge evidence as cut off"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 512 - 01:04:59 EDT to 01:06:18 EDT

Scope:
- Hardened receipt coverage evidence parsing so non-finite diagnostic numbers
  cannot fake bottom-edge or totals completion evidence.
- Added a coverage regression proving malformed native numbers still produce a
  conservative missing-bottom-and-totals continuation decision.
- Recorded `BUG-RECEIPT-0030` under `camera_capture_quality`.
- Archived Pass 475 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed an initial analyzer failure from a wrong diagnostic key in the new
  regression, then fixed the app logic after the corrected regression exposed a
  false likely-complete decision.
- Passed targeted Dart format and analyzer for receipt coverage evidence helpers
  and coverage totals regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_coverage_totals_test.dart --plain-name
  "non-finite coverage diagnostics are treated as missing evidence"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 511 - 01:03:26 EDT to 01:04:01 EDT

Scope:
- Hardened native camera capability parsing so malformed platform numbers cannot
  become fake camera counts, zoom ranges, exposure ranges, or still sizes.
- Added direct unit regression coverage for non-finite capability values.
- Recorded `BUG-RECEIPT-0029` under `native_bridge`.
- Archived Pass 474 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the native camera contract and
  native camera session contract regression coverage.
- Passed focused Flutter test
  `test/receipt_native_camera_session_contract_test.dart --plain-name "native
  capabilities reject non-finite platform numbers"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 510 - 01:02:14 EDT to 01:02:52 EDT

Scope:
- Hardened receipt capture diagnostic telemetry so recovery photo counts from
  native diagnostics reject non-finite numeric values instead of crashing.
- Added regression coverage proving the recovery telemetry converter requires a
  finite numeric value.
- Recorded `BUG-RECEIPT-0028` under `camera_capture_quality`.
- Archived Pass 473 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for capture diagnostic telemetry and
  OCR source handoff regression coverage.
- Passed focused Flutter test `test/receipt_camera_ocr_source_handoff_test.dart`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 509 - 01:00:37 EDT to 01:01:44 EDT

Scope:
- Hardened receipt camera diagnostic bucket helpers so non-finite numeric
  payloads from the native bridge cannot crash telemetry or create fake quality
  evidence.
- Added regression coverage proving diagnostic integer parsing goes through a
  finite-value helper.
- Recorded `BUG-RECEIPT-0027` under `camera_capture_quality`.

Verification:
- Fixed an initial focused-test failure caused by the regression fixture not
  reading the diagnostic helper implementation, then reran the focused chain.
- Passed targeted Dart format and analyzer for diagnostic bucket helpers and
  OCR source handoff regression coverage.
- Passed focused Flutter test `test/receipt_camera_ocr_source_handoff_test.dart`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 508 - 00:58:43 EDT to 00:59:26 EDT

Scope:
- Hardened the main split-percent sheet so custom business percent text can
  include a percent sign, matching the quick price-only split path.
- Added regression coverage proving the old direct custom controller parse path
  is gone.
- Recorded `BUG-RECEIPT-0026` under `business_personal_split`.
- Archived Pass 472 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for the split percent sheet and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.

## Pass 507 - 00:56:22 EDT to 00:57:13 EDT

Scope:
- Hardened quick price-only split line entry so custom business percent text can
  include a percent sign just like the full line editor.
- Added regression coverage proving the quick split parser strips `%` and the
  old direct `double.tryParse(...trim())` path is gone.
- Recorded `BUG-RECEIPT-0025` under `business_personal_split`.
- Archived Pass 471 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format and analyzer for quick line-mode helpers and
  assisted-review regression coverage.
- Passed focused Flutter test
  `test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted
  receipt review exposes classification and attachment flow"`.
- Passed `dart tool/receipt_bug_regression_ledger_gate.dart`.
