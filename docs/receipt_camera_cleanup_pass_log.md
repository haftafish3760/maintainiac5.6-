# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 564 - 07:54:05 EDT to 08:02:17 EDT

Scope:
- Hardened restored app-document kind names so padded maintenance/job receipt
  document metadata does not downgrade into the generic document bucket.
- Added regression coverage for maintenance receipt document routing and stored
  PDF attachment restore after padded kind metadata.
- Recorded `BUG-RECEIPT-0080` under `source_preservation`.

Verification:
- Passed targeted Dart format/analyzer for app document models and document
  store regression coverage.
- Passed focused Flutter regression
  `test/app_document_store_test.dart --plain-name "document records trim stored
  kind names before restore"`.

## Pass 563 - 07:45:00 EDT to 07:53:53 EDT

Scope:
- Hardened restored receipt-proof media asset metadata so padded purpose and
  backup-policy values still route receipt proofs into receipt cloud manifests.
- Added safe byte-size parsing so malformed media metadata cannot crash restore
  or silently block receipt proof backup eligibility.
- Added regression coverage for restored receipt-proof backup manifest entries.
- Recorded `BUG-RECEIPT-0079` under `source_preservation`.
- Archived Pass 514 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for media asset restore and cloud backup
  manifest regression coverage.
- Passed focused Flutter regression
  `test/cloud_backup_manifest_test.dart --plain-name "receipt proof media
  restore trims backup metadata for cloud manifests"`.

## Pass 562 - 07:37:10 EDT to 07:44:38 EDT

Scope:
- Hardened duplicate receipt status and confidence restore helpers so padded
  stored enum values do not weaken override or exact-file-match state.
- Added regression coverage for restored override-saved duplicate review state
  and exact proof-match candidate confidence.
- Recorded `BUG-RECEIPT-0078` under `source_preservation`.
- Archived Pass 513 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for duplicate receipt models and focused
  duplicate detection regression coverage.
- Passed focused Flutter regression
  `test/expense_duplicate_detection_test.dart --plain-name "duplicate receipt
  restore trims saved status and confidence names"`.

## Pass 561 - 07:30:00 EDT to 07:36:56 EDT

Scope:
- Hardened restored receipt line business-use names so whitespace-padded stored
  values do not downgrade personal or split receipt lines to business.
- Added regression coverage for split allocation math, client-proof redaction,
  and receipt proof anchors after padded storage restore.
- Recorded `BUG-RECEIPT-0077` under `business_personal_split`.

Verification:
- Passed targeted Dart format/analyzer for the receipt line model and focused
  line-record regression coverage.
- Passed focused Flutter regression
  `test/expense_receipt_line_record_test.dart --plain-name "receipt line
  records trim stored business use names"`.

## Pass 560 - 07:12:04 EDT to 07:13:08 EDT

Scope:
- Hardened stitch result metadata so zero/manual-overlap placeholders do not
  claim the user made a manual match when automatic overlap matching was used.
- Added fixture-backed manual-overlap regression coverage for a zero fraction.
- Recorded `BUG-RECEIPT-0076` under `ghost_overlap_stitching`.
- Archived Pass 526 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for stitch API and manual-overlap
  regression coverage.
- Passed focused Flutter manual-overlap regression.

## Pass 559 - 07:05:33 EDT to 07:11:06 EDT

Scope:
- Hardened long-receipt stitching so duplicate input paths fall back to ordered
  section review instead of producing a bogus combined OCR image.
- Added fixture-backed stitching regression coverage for duplicate paths that
  only differ by storage whitespace.
- Recorded `BUG-RECEIPT-0075` under `ghost_overlap_stitching`.
- Archived Pass 527 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for stitch result models, stitch API,
  and stitching regression coverage.
- Passed focused Flutter stitching regression for duplicate receipt section
  paths.

## Pass 558 - 07:01:13 EDT to 07:04:21 EDT

Scope:
- Hardened retake capture diagnostics so stale picked diagnostics cannot be
  re-added for paths outside the accepted retake order plan.
- Added lifecycle source regression coverage requiring retake diagnostics to
  emit only accepted retake-plan keys.
- Recorded `BUG-RECEIPT-0074` under `multi_photo_ordering`.
- Archived Pass 542 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for retake capture actions and lifecycle
  source coverage.
- Passed focused Flutter lifecycle contract test.

## Pass 557 - 06:46:00 EDT to 06:59:56 EDT

Scope:
- Hardened recovery-stage manifest updates so old/private-looking manifest
  diagnostics are filtered through the staging safe-key whitelist during merge.
- Added cleanup regression coverage proving stage updates drop existing private
  receipt/customer diagnostic keys while preserving safe recovery metadata.
- Recorded `BUG-RECEIPT-0073` under `privacy_redaction`.
- Archived Pass 543 out of the live cleanup log.

Verification:
- Fixed a type issue in the safe merge, corrected an over-broad Hive-index
  expectation, then reran the focused chain.
- Passed targeted Dart analyzer and focused Flutter recovery-stage update test.

## Pass 556 - 06:44:37 EDT to 06:45:41 EDT

Scope:
- Hardened native receipt capture results so duplicate original photo paths are
  rejected before they can collapse long-receipt section identity downstream.
- Added native-service regression coverage for duplicate paths that only differ
  by storage whitespace.
- Recorded `BUG-RECEIPT-0072` under `multi_photo_ordering`.
- Archived Pass 540 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for native camera service and native
  result rejection coverage.
- Passed focused Flutter file `test/receipt_native_camera_result_rejection_test.dart`.

## Pass 555 - 06:34:19 EDT to 06:35:43 EDT

Scope:
- Generalized native capture diagnostic sanitization into a shared helper used
  by the native camera service, Hive recovery index restore, recovery manifest
  restore, and recovery diagnostic updates.
- Added recovery regression coverage proving old malformed persisted
  diagnostics cannot restore `NaN`, infinity, nested unsafe values, or
  non-string keys.
- Recorded `BUG-RECEIPT-0071` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for native diagnostics sanitizer,
  service, recovery store, staging, and targeted regressions.
- Passed focused Flutter tests for native service diagnostics and recovery
  restore diagnostics.

## Pass 554 - 06:25:12 EDT to 06:30:54 EDT

Scope:
- Hardened native receipt camera service diagnostics so malformed bridge
  values cannot leak non-finite numbers or non-string keys into review state.
- Added native-service regression coverage for `NaN`, infinity, nested
  diagnostics, lists, and non-string diagnostic keys.
- Recorded `BUG-RECEIPT-0070` under `native_bridge`.
- Archived Pass 539 out of the live cleanup log.

Verification:
- Fixed an over-broad regression assertion that matched unrelated policy text,
  then reran the failed focused test and the full native result rejection file.
- Passed targeted Dart format/analyzer for native camera service and native
  result rejection coverage.

## Pass 553 - 06:10:54 EDT to 06:19:40 EDT

Scope:
- Hardened receipt attachment map restore so persisted IDs and source paths are
  trimmed before they can key source-state maps, duplicate checks, or recovery
  records.
- Added metadata regression coverage proving padded stored identity/source
  values restore to normalized receipt attachment records.
- Recorded `BUG-RECEIPT-0069` under `source_preservation`.
- Archived Pass 536 out of the live cleanup log.

Verification:
- Passed targeted Dart format and analyzer for receipt attachment records and
  attachment metadata regression coverage.
- Passed focused Flutter test `test/receipt_attachment_record_metadata_test.dart`.

## Pass 552 - 05:51:59 EDT to 06:07:13 EDT

Scope:
- Hardened receipt attachment map restore so non-finite file, page, and photo
  quality numbers cannot crash integer conversion or become fake camera
  evidence.
- Added metadata regression coverage proving `NaN` and infinity values are
  ignored and never serialize back out.
- Recorded `BUG-RECEIPT-0068` under `camera_capture_quality`.
- Archived Pass 535 out of the live cleanup log.

Verification:
- Passed targeted Dart format and analyzer for receipt attachment records and
  attachment metadata regression coverage.
- Passed focused Flutter test `test/receipt_attachment_record_metadata_test.dart`.

## Pass 551 - 05:50:40 EDT to 05:53:10 EDT

Scope:
- Hardened persisted receipt attachment restore so whitespace-padded or
  duplicate photo attachment paths cannot enter `_photoPaths`, photo IDs,
  quality state, or read-state maps.
- Added recovery contract coverage requiring the attachment panel to normalize
  initial photo attachments before rebuilding camera source state.
- Recorded `BUG-RECEIPT-0067` under `source_preservation`.
- Archived Pass 534 out of the live cleanup log.

Verification:
- Passed targeted Dart format and analyzer for attachment initial state and
  recovery contract coverage.
- Passed focused Flutter test
  `test/receipt_attachment_panel_recovery_contract_test.dart --plain-name
  "receipt attachment panel has plain recovery states"`.

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

## Pass 549 - 05:30:31 EDT to 05:37:07 EDT

Scope:
- Hardened OCR source quality and diagnostics helpers so derived OCR paths do
  not inherit original-photo evidence just because the list indexes match.
- Added attachment and shared-flow source contract coverage requiring direct
  OCR-source path lookup with aligned original-photo fallback only.
- Recorded `BUG-RECEIPT-0065` under `source_preservation`.
- Archived Pass 532 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer for attachment native signal helpers,
  capture-flow helpers, OCR source risk helpers, and source contracts.
- Passed focused Flutter tests
  `test/receipt_camera_ocr_source_attachment_read_test.dart` and
  `test/receipt_capture_flow_handoff_contract_test.dart`.

## Pass 550 - 05:37:08 EDT to 05:38:53 EDT

Scope:
- Hardened document-scanner backup quality handoff so duplicate or whitespace
  camera-result paths cannot overwrite or mislabel receipt quality evidence.
- Added attachment read source contract coverage for the new camera-result path
  uniqueness and normalization guard.
- Recorded `BUG-RECEIPT-0066` under `source_preservation`.
- Archived Pass 533 out of the live cleanup log.

Verification:
- Passed targeted format/analyzer for attachment native signal helpers and
  attachment read contract coverage.
- Passed focused Flutter test
  `test/receipt_camera_ocr_source_attachment_read_test.dart --plain-name
  "reviewed OCR source attachments preserve read state and cleanup safety"`.

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
