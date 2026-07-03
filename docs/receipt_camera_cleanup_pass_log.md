# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 544 - 05:07:44 EDT to 05:11:43 EDT

Scope:
- Hardened native camera engine restore so padded bridge, manifest, or Hive
  index values do not downgrade captured receipts to the unavailable engine.
- Added capability and interrupted-capture recovery regressions for padded
  native engine names.
- Recorded `BUG-RECEIPT-0061` under `native_bridge`.
- Archived Pass 538 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer for native camera contract and recovery
  restore files.
- Passed focused capability and recovery-index Flutter regressions.

## Pass 545 - 05:12:04 EDT to 05:13:14 EDT

Scope:
- Hardened receipt performance mode restore so padded Hive values do not fall
  back to automatic camera workload selection.
- Added settings-store regression coverage proving Battery Saver survives
  padded persisted values and still maps to the light capability tier.
- Recorded `BUG-RECEIPT-0062` under `camera_capture_quality`.
- Archived Pass 537 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer for assistance policy enums and settings
  store regression coverage.
- Passed focused Flutter test
  `test/receipt_capture_settings_store_test.dart --plain-name "restores padded
  receipt performance mode preference"`.

## Pass 546 - 05:17:20 EDT to 05:23:05 EDT

Scope:
- Hardened edited-photo review metadata so source-selection counts no longer
  duplicate the edit action bucket.
- Added regression coverage proving edited receipt copies report
  `edited_copy_selected` while edit actions still report `manual_crop`.
- Recorded `BUG-RECEIPT-0063` under `source_preservation`.
- Archived Pass 529 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer for native review signal aggregation and
  recovery metadata regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_recovery_metadata_test.dart`.

## Pass 547 - 05:23:06 EDT to 05:28:19 EDT

Scope:
- Generalized `BUG-RECEIPT-0063` so direct OCR handoff signals and risk flags
  also use selected-source tokens instead of edit-action tokens.
- Updated source-guard regressions to require `$sourceSelection` tokens and to
  read the current helper files that own diagnostics and recovery guards.
- Archived Pass 530 out of the live cleanup log.

Verification:
- Fixed two stale source-guard expectations uncovered by the focused test run,
  then reran the affected chain.
- Passed targeted format/analyzer and focused recovery handoff, quality
  handoff, and shared-flow recovery contract tests.

## Pass 548 - 05:28:20 EDT to 05:30:30 EDT

Scope:
- Hardened picked camera-result quality handoff so stale or foreign picked
  paths cannot leave partial quality evidence after diagnostics reject the
  batch.
- Added lifecycle source regression coverage requiring the camera-result member
  guard beside the picked-path uniqueness guard.
- Recorded `BUG-RECEIPT-0064` under `source_preservation`.
- Archived Pass 531 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer for picked review save models and lifecycle
  source regression coverage.
- Passed focused Flutter test
  `test/receipt_photo_review_save_lifecycle_test.dart --plain-name "photo
  review save and close actions respect lifecycle state"`.

## Pass 543 - 05:01:39 EDT to 05:02:14 EDT

Scope:
- Hardened receipt attachment enum restore helpers so padded stored names do
  not fall back to default proof/storage states.
- Added attachment storage-map regression coverage for padded kind, data-saver,
  PDF status, storage state, and read-state values.
- Recorded `BUG-RECEIPT-0060` under `source_preservation`.

Verification:
- Passed targeted format/analyzer, focused attachment metadata regression,
  bug-ledger, cleanup-log, doc-size, source-audit, and diff gates.

## Pass 542 - 04:58:57 EDT to 04:59:58 EDT

Scope:
- Hardened picked receipt-photo factories so camera, native, and phone-backup
  paths are normalized and de-duplicated before entering review state.
- Filtered picked native diagnostics to the normalized picked path list.
- Added lifecycle source regression coverage for the normalized picked-path
  handoff.
- Recorded `BUG-RECEIPT-0059` under `source_preservation`.
- Archived Pass 518 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer and focused lifecycle regression.
- Passed bug-ledger, cleanup-log, doc-size, source-audit, and diff gates.

## Pass 541 - 04:56:14 EDT to 04:57:00 EDT

Scope:
- Hardened receipt photo review results so quality checks, capture diagnostics,
  and OCR preparation diagnostics are filtered to normalized result paths.
- Added regression coverage proving stale and whitespace-keyed evidence maps
  cannot survive after saved-proof and OCR source paths are normalized.
- Recorded `BUG-RECEIPT-0058` under `source_preservation`.
- Archived Pass 519 out of the live cleanup log.

Verification:
- Removed the dead immutable-diagnostics helper after analyzer caught it, then
  reran.
- Passed targeted format/analyzer, focused camera-result regression,
  bug-ledger, log, doc-size, source-audit, and diff gates.

## Pass 540 - 04:52:32 EDT to 04:53:38 EDT

Scope:
- Added a source-level UI contract guard proving receipt review layout tweaks
  keep camera actions wired to add-photo, retake, continue, crop, order, stitch,
  quality, and capture diagnostics handoff.
- Archived Pass 520 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed source-bundle path misses in the new guard, then reran.
- Passed targeted format/analyzer, focused handoff contract regression,
  cleanup-log gate, doc-size gate, source audit, and diff check.

## Pass 539 - 03:32:13 EDT to 03:33:32 EDT

Scope:
- Hardened native recovery review so duplicate or whitespace-padded manifest
  photo paths cannot reopen duplicate receipt sections.
- Replaced raw recovery diagnostics map construction with an immutable helper
  based on the normalized recovered path list.
- Added recovery contract coverage requiring the normalized helper and rejecting
  the old raw path-keyed diagnostics shape.
- Recorded `BUG-RECEIPT-0057` under `multi_photo_ordering`.
- Archived Pass 528 out of the live cleanup log.

Verification:
- Fixed stale recovery-contract assertions that still expected the old raw
  manifest loop, then reran the focused chain.
- Passed focused Flutter test
  `test/receipt_attachment_panel_recovery_contract_test.dart`.
- Passed targeted format/analyzer, bug-ledger, log, doc-size, audit, and diff
  gates.

## Pass 532 - 02:41:43 EDT to 02:46:00 EDT

Scope:
- Hardened receipt completion coverage so native bottom-missing statuses keep
  the user in add-next-section flow before receipt details.
- Added regression coverage proving `bottom_soft_or_missing` triggers another
  section even without an explicit `photoCoverageNeedsMorePhotos` boolean.
- Recorded `BUG-RECEIPT-0050` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format and analyzer for completion coverage logic and
  focused completion coverage regression coverage.
- Passed focused Flutter test
  `test/receipt_camera_result_completion_coverage_test.dart --plain-name
  "native bottom soft status requests another section before details"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 533 - 02:43:56 EDT to 02:48:00 EDT

Scope:
- Hardened attachment-panel photo risk flags so native bottom-missing coverage
  statuses still mark a receipt photo as a possible partial receipt.
- Added source contract coverage for the private panel helper and
  `bottom_soft_or_missing` status token.
- Recorded `BUG-RECEIPT-0051` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format and analyzer for attachment panel publish signals
  and attachment read contract coverage.
- Passed focused Flutter test
  `test/receipt_camera_ocr_source_attachment_read_test.dart --plain-name
  "reviewed OCR source attachments preserve read state and cleanup safety"`.
- Archived Pass 508 after the cleanup log gate caught the active log over cap.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 534 - 02:50:38 EDT to 02:54:00 EDT

Scope:
- Hardened attachment-panel photo risk flags so native bottom-missing statuses
  recommend adding more receipt photos, not just mark partial risk.
- Extended attachment read contract coverage for the normalized status branch.
- Recorded `BUG-RECEIPT-0052` under `camera_capture_quality`.
- Archived Pass 509 to keep the active log under the line-count cap.

Verification:
- Passed targeted Dart format and analyzer for attachment panel publish signals
  and attachment read contract coverage.
- Passed focused Flutter test
  `test/receipt_camera_ocr_source_attachment_read_test.dart --plain-name
  "reviewed OCR source attachments preserve read state and cleanup safety"`.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 535 - 02:56:05 EDT to 03:01:00 EDT

Scope:
- Hardened expense receipt line map restore so non-finite numeric payloads do
  not poison split percentages, totals, odometer values, or parser confidence.
- Added regression coverage proving `NaN` and infinity inputs fall back to
  finite receipt-line defaults and never serialize back out.
- Recorded `BUG-RECEIPT-0053` under `business_personal_split`.
- Archived Pass 510 to keep the active log under the line-count cap.

Verification:
- Passed targeted Dart format/analyzer for expense numeric helpers and line
  record regression coverage.
- Passed focused Flutter test for non-finite receipt line payloads.
- Passed bug-ledger gate, cleanup-log gate, doc-size gate, source audit, and
  diff check.

## Pass 536 - 02:59:48 EDT to 03:04:00 EDT

Scope:
- Hardened receipt line proof redaction anchors so malformed nonpositive
  section numbers cannot leak into stable proof IDs.
- Applied the same sanitization to saved and entry-screen line models.
- Added regression coverage for a negative section number with a valid section
  line number.
- Recorded `BUG-RECEIPT-0054` under `receipt_line_numbering`.
- Archived Pass 511 to keep the active log under the line-count cap.

Verification:
- Passed targeted Dart format/analyzer for receipt line anchor logic and entry
  line model parity.
- Passed focused Flutter test for malformed receipt section proof anchors.
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
