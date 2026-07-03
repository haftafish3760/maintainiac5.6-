# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 584 - 11:12:00 EDT to 11:18:15 EDT

Scope:
- Hardened OCR-source enhancement scoring so malformed receipt quality metrics
  cannot produce non-finite cleanup candidate rankings.
- Added OCR-source handoff source coverage requiring cleanup score metrics to
  route through the finite enhancement helper.
- Recorded `BUG-RECEIPT-0100` under `camera_capture_quality`.
- Archived Pass 557 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed the first focused contract failure by reading the enhancement helper
  part file instead of only the main image processor shell.
- Passed targeted Dart format/analyzer for enhancement scoring and OCR-source
  handoff coverage.
- Passed focused Flutter OCR-source handoff regression.

## Pass 583 - 11:01:00 EDT to 11:08:30 EDT

Scope:
- Hardened receipt review cleanup, recovery, and camera-result membership
  checks so they use normalized receipt photo path identity instead of raw
  string `contains` checks.
- Added behavior coverage for normalized path membership and updated lifecycle
  source guards to require the shared helper.
- Recorded `BUG-RECEIPT-0099` under `multi_photo_ordering`.
- Archived Pass 556 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for the path identity helper, review
  exit actions, picked-photo membership, and focused tests.
- Passed focused Flutter path-identity and review lifecycle regressions.

## Pass 582 - 10:48:00 EDT to 10:57:30 EDT

Scope:
- Added a shared receipt photo path identity helper and routed picked-photo
  intake plus retake/order guards through the same normalized identity rule.
- Added behavior coverage proving blank, padded, duplicate, and `../` alias
  receipt photo paths are rejected or de-duplicated before review ordering.
- Updated the review lifecycle source guard so picked-photo intake must keep
  using the shared helper.
- Recorded `BUG-RECEIPT-0098` under `multi_photo_ordering`.
- Archived Pass 554 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for the shared path identity helper,
  review screen wiring, picked-photo intake, retake ordering, and focused
  tests.
- Passed focused Flutter path-identity and retake-order regressions.
- Corrected a stale lifecycle test filter, then passed focused Flutter
  lifecycle coverage for review save/close actions.

## Pass 581 - 10:37:00 EDT to 10:44:30 EDT

Scope:
- Hardened long-receipt retake/insert order planning so receipt section path
  aliases cannot be treated as separate source images.
- Added regression coverage proving current-section and replacement-section
  `../` path aliases are rejected before section order is mutated.
- Recorded `BUG-RECEIPT-0097` under `multi_photo_ordering`.
- Archived Pass 553 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed the first analyzer style warning by using the null-aware collection
  element for normalized path set construction.
- Passed targeted Dart format/analyzer for retake-order planning and focused
  retake-order regression coverage.
- Passed focused Flutter regression
  `test/receipt_photo_review_retake_order_test.dart --plain-name "retake plan
  rejects normalized receipt section path aliases"`.

## Pass 580 - 10:30:00 EDT to 10:35:20 EDT

Scope:
- Hardened the shared native capture diagnostics sanitizer so exact
  stringified non-finite tokens from platform channels are dropped before
  receipt camera review or recovery restore can trust them.
- Extended native service and recovery-index regressions to prove `NaN`,
  `Infinity`, and `-Infinity` string diagnostics are removed from maps and
  lists.
- Recorded `BUG-RECEIPT-0096` under `native_bridge`.
- Archived Pass 552 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for the shared native diagnostic
  sanitizer, native result rejection coverage, and recovery-index coverage.
- Passed focused Flutter regressions for native service unsafe diagnostics and
  recovery restore malformed diagnostics.

## Pass 579 - 10:22:00 EDT to 10:27:20 EDT

Scope:
- Hardened native capture staging diagnostics so non-finite values inside
  iterable/list diagnostics are filtered before recovery manifests are written.
- Added regression coverage proving staged diagnostics and the manifest omit
  `NaN` and infinity values while preserving usable list entries.
- Recorded `BUG-RECEIPT-0095` under `native_bridge`.
- Archived Pass 551 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for native staging diagnostic
  sanitization and focused native staging regression coverage.
- Passed focused Flutter regression
  `test/receipt_native_capture_staging_test.dart --plain-name "native staging
  removes non-finite diagnostic list values"`.

## Pass 578 - 09:58:08 EDT to 09:58:55 EDT

Scope:
- Hardened receipt straightening so non-finite rotation angles are rejected
  before creating a derived OCR/review image.
- Added regression coverage proving `NaN` and infinity rotation requests fail
  with a stable angle error.
- Recorded `BUG-RECEIPT-0094` under `camera_capture_quality`.
- Archived Pass 550 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for the image processor and focused
  rotation-angle regression coverage.
- Passed focused Flutter regression
  `test/receipt_image_rotation_test.dart --plain-name "receipt image processor
  rejects unusable rotation angles"`.

## Pass 577 - 09:44:18 EDT to 09:51:14 EDT

Scope:
- Hardened manual receipt crop processing so zero-size or non-finite display
  and crop rectangles are rejected before pixel scaling.
- Added regression coverage proving unusable crop bounds fail with a stable
  crop-bound error instead of creating an unsafe derived receipt image.
- Recorded `BUG-RECEIPT-0093` under `camera_capture_quality`.
- Archived Passes 549 and 544 out of the live cleanup log to keep the active
  log under the project line-count cap.

Verification:
- Fixed the first targeted analyzer failure by importing Flutter material for
  `Rect` in the crop-bound regression test.
- Passed targeted Dart format/analyzer for the image processor and focused
  crop-bound regression coverage.
- Passed focused Flutter regression
  `test/receipt_image_rotation_test.dart --plain-name "receipt image processor
  rejects unusable crop bounds"`.

## Pass 576 - 09:34:57 EDT to 09:35:54 EDT

Scope:
- Hardened `ReceiptCameraCaptureEvidence` live brightness and exposure helpers
  so non-finite values are treated as missing camera evidence.
- Added regression coverage proving malformed live brightness does not create
  dark/glare flags and malformed exposure offsets stay at native baseline.
- Recorded `BUG-RECEIPT-0092` under `camera_capture_quality`.
- Archived Pass 546 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for camera-result models and focused
  native evidence regression coverage.
- Passed focused Flutter regression
  `test/receipt_camera_result_best_shot_ocr_test.dart --plain-name "camera
  results carry privacy-safe native capture evidence"`.

## Pass 575 - 09:30:34 EDT to 09:32:10 EDT

Scope:
- Hardened Dart camera-result diagnostics so non-finite live preview brightness
  is treated as unknown before review and OCR handoff metadata are built.
- Added regression coverage proving malformed live brightness does not leak
  `Infinity`/`NaN` into capture diagnostics or preview parity signals.
- Recorded `BUG-RECEIPT-0091` under `camera_capture_quality`.
- Archived Pass 545 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed the first focused regression failure by preserving unknown preview
  parity when live brightness evidence is malformed.
- Passed targeted Dart format/analyzer for camera-result diagnostics and
  focused camera-result quality regression coverage.
- Passed focused Flutter regression
  `test/receipt_camera_result_quality_test.dart --plain-name "camera result
  diagnostics ignore non-finite live brightness"`.

## Pass 574 - 09:22:37 EDT to 09:24:08 EDT

Scope:
- Hardened Android captured-photo diagnostic rounding so non-finite quality
  values become unknown evidence instead of unsafe diagnostic numbers.
- Hardened iOS captured-photo diagnostic rounding with the same finite-value
  guard.
- Added Android and iOS source contract regressions for finite captured quality
  diagnostics.
- Recorded `BUG-RECEIPT-0090` under `camera_capture_quality`.
- Archived Pass 548 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for Android and iOS native quality
  source regressions.
- Passed focused Flutter regressions
  `test/receipt_native_android_bridge_settings_quality_test.dart` and
  `test/receipt_native_ios_bridge_long_receipt_quality_test.dart`.

## Pass 573 - 09:14:52 EDT to 09:21:30 EDT

Scope:
- Hardened Android native camera session double extras so non-finite zoom,
  exposure, and auto-capture thresholds fall back before camera clamping.
- Hardened iOS native camera session double arguments so non-finite zoom,
  exposure, and auto-capture thresholds cannot reach AVFoundation controls.
- Added Android and iOS source contract regressions for finite native bridge
  double handling.
- Recorded `BUG-RECEIPT-0089` under `native_bridge`.
- Archived Pass 547 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed one line-wrap-sensitive Android source regression expectation, then
  reran the focused native bridge checks.
- Passed targeted Dart format/analyzer for Android and iOS native bridge source
  regressions.
- Passed focused Flutter regressions
  `test/receipt_native_android_bridge_settings_quality_test.dart` and
  `test/receipt_native_ios_bridge_ui_session_test.dart`.

## Pass 572 - 09:08:52 EDT to 09:12:53 EDT

Scope:
- Hardened manual stitch-overlap review controls so non-finite overlap values
  are ignored before they can enter preview state or preview cache keys.
- Added source regression coverage proving malformed manual overlap values are
  rejected before the selected stitch-pair slot is mutated.
- Recorded `BUG-RECEIPT-0088` under `ghost_overlap_stitching`.
- Archived Passes 525 and 541 out of the live cleanup log to keep the active
  log under the project line-count cap.

Verification:
- Fixed the first focused regression assertion so it checks the manual-overlap
  setter block instead of an earlier source reference.
- Passed targeted Dart format/analyzer for stitch preview async state and
  focused review lifecycle regression coverage.
- Passed focused Flutter regression
  `test/receipt_photo_review_save_lifecycle_test.dart --plain-name "photo
  review save and close actions respect lifecycle state"`.

## Pass 571 - 08:43:48 EDT to 08:57:53 EDT

Scope:
- Hardened native settings health so non-finite settings-open counts cannot
  create false settings-opened or settings-not-opened UI evidence.
- Added regression coverage proving malformed native settings counts are
  ignored while valid settings contract and placement signals survive.
- Recorded `BUG-RECEIPT-0087` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for native settings health and focused
  native settings regression coverage.
- Passed focused Flutter regression
  `test/receipt_camera_result_native_close_settings_test.dart --plain-name
  "native settings health ignores non-finite open counts"`.

## Pass 570 - 08:30:00 EDT to 08:38:58 EDT

Scope:
- Hardened OCR-source native recovery document signals so non-finite recovered
  photo counts do not create false recovered-photo evidence.
- Applied the finite-count guard to both capture-flow and attachment-panel OCR
  source signal builders.
- Added source regression coverage proving both signal paths require finite
  recovered counts.
- Recorded `BUG-RECEIPT-0086` under `native_bridge`.
- Archived Passes 523 and 524 out of the live cleanup log to keep the active
  log under the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for both OCR-source signal builders and
  focused handoff contract regression coverage.
- Passed focused Flutter regression
  `test/receipt_capture_flow_handoff_contract_test.dart --plain-name "app
  assisted OCR reads prepared OCR sources instead of saved backup proof"`.

## Pass 569 - 08:19:00 EDT to 08:29:09 EDT

Scope:
- Hardened receipt photo quality scoring so non-finite focus, brightness,
  contrast, crop, or text-band metrics become conservative retake evidence.
- Added regression coverage proving malformed quality metrics stay finite in
  review labels and do not masquerade as readable camera output.
- Recorded `BUG-RECEIPT-0085` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for photo quality models and focused
  camera-result quality regression coverage.
- Passed focused Flutter regression
  `test/receipt_camera_result_quality_test.dart --plain-name "receipt quality
  treats non-finite metrics as unsafe evidence"`.

## Pass 568 - 08:13:00 EDT to 08:18:41 EDT

Scope:
- Hardened native close/capture diagnostic numeric helpers so non-finite counts
  cannot become positive camera health evidence.
- Added regression coverage proving malformed close counts do not create false
  close-request, deferred-capture, retry, or no-photo-cancel flags.
- Recorded `BUG-RECEIPT-0084` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for diagnostic helpers and focused
  native-close regression coverage.
- Passed focused Flutter regression
  `test/receipt_camera_result_native_close_settings_test.dart --plain-name
  "native close health ignores non-finite numeric counts"`.

## Pass 567 - 08:06:05 EDT to 08:12:36 EDT

Scope:
- Hardened native recovery Hive index restore so padded session IDs, manifest
  paths, engine names, and data-saver names do not leak into recovery identity.
- De-duplicated normalized staged photo paths at the index restore boundary so
  interrupted native captures keep stable ordered section counts.
- Added focused regression coverage for recovered index identity and path
  normalization.
- Recorded `BUG-RECEIPT-0083` under `multi_photo_ordering`.
- Archived Pass 521 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for native recovery index restore and
  focused recovery-index regression coverage.
- Passed focused Flutter regression
  `test/receipt_native_capture_recovery_index_test.dart --plain-name "recovery
  index restore normalizes stored identity and paths"`.

## Pass 566 - 08:04:10 EDT to 08:05:55 EDT

Scope:
- Hardened native capture recovery manifests so padded/duplicate staged photo
  paths restore as unique ordered receipt sections.
- Hardened attachment-only recovery fallback paths so padded attachment paths do
  not inflate missing-photo counts or resume labels.
- Added regression coverage for staged and attachment fallback path normalization.
- Recorded `BUG-RECEIPT-0082` under `multi_photo_ordering`.
- Archived Pass 516 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for native recovery records and focused
  recovery-record regression coverage.
- Passed focused Flutter regression
  `test/receipt_native_capture_recovery_record_test.dart --plain-name "recovery
  manifest normalizes staged and attachment photo paths"`.

## Pass 565 - 08:02:25 EDT to 08:04:01 EDT

Scope:
- Hardened PDF receipt import duplicate checks so padded existing hashes or
  paths still match the newly staged PDF proof.
- Added source regression coverage for normalized current-form PDF duplicate
  hash and path comparisons.
- Recorded `BUG-RECEIPT-0081` under `source_preservation`.
- Archived Pass 515 out of the live cleanup log.

Verification:
- Passed targeted Dart format/analyzer for PDF import actions and focused PDF
  import regression coverage.
- Passed focused Flutter regression
  `test/receipt_pdf_import_copy_test.dart --plain-name "PDF import copy keeps
  proof-only and app-fill choices clear"`.

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
