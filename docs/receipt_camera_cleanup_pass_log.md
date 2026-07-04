# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 591 - 20:32:44 EDT to 20:36:37 EDT

Scope:
- Reframed the receipt camera focus contract so continuous autofocus is the
  primary capture behavior and tap-to-focus is only optional focus assist.
- Added shared focus/readability policy diagnostics for continuous focus,
  brightness assist, sharpness guidance, and live readability guidance.
- Updated user-facing camera quality guidance to tell users to hold steady and
  let the camera refocus before using focus assist.
- Added `focus_assist` as a native control contract alias while preserving
  legacy `tapFocus...` bridge diagnostics for compatibility.
- Recorded `BUG-RECEIPT-0114` under `camera_capture_quality`.

Verification:
- Fixed one focused regression mismatch for devices without focus-assist
  support and one health-tag alias mismatch before proceeding.
- Passed targeted Dart analyzer for the edited receipt camera contract,
  guidance, diagnostics, and regression tests.
- Passed focused Flutter regressions for native camera contract/session,
  privacy diagnostics, assistance policy diagnostics, quality guidance, and
  native UI health.

## Pass 590 - 20:11:15 EDT to active cleanup

Scope:
- Added a work-supply barcode scan bridge that converts shared ML Kit
  barcode/QR results into inventory package alias suggestions.
- Preserved the existing inventory alias normalization path instead of creating
  a second barcode identity model.
- Added privacy-safe suggestion summaries that expose format/type/length but
  not the scanned code value.
- Added focused regressions for UPC, QR, duplicate scan values, sensitive QR
  payload exclusion, and unknown-format guessing.
- Recorded `BUG-RECEIPT-0113` under `barcode_qr_scanning`.
- Archived Pass 570 out of the live cleanup log before recording Pass 590.

Verification:
- Passed targeted Dart format/analyzer for the work-supply barcode bridge.
- Passed focused barcode bridge and shared scanner service regressions.

## Pass 589 - 16:06:06 EDT to active cleanup

Scope:
- Classified generated work-supply catalog Dart files separately in the source
  audit instead of mixing generated data with hand-written receipt parser code.
- Added an explicit `--include-generated-catalog-data` source-audit mode so
  generated catalog files can still be audited intentionally.
- Added regression coverage proving generated catalog data is skipped by
  default and included when requested.
- Added regression coverage proving vendored native `.symlinks` plugin sources
  do not count against app-owned source caps.
- Hardened Add Another Photo ordering so inserted long-receipt sections carry
  anchor section, final section, offset, and order-policy diagnostics.
- Extended receipt result handoff counts so inserted section metadata reaches
  privacy-safe section-order outcomes and admin/QA summaries.
- Hardened manual move-earlier/move-later ordering so user-reordered receipt
  sections carry privacy-safe original/final section and direction evidence.
- Locked manual reorder plans to adjacent one-section moves so future UI
  controls cannot silently skip receipt sections.
- Added an explicit capture-flow review-depth override so detailed-line intent
  reaches the native camera session.
- Mapped expense simple/full review style to native price-only/detailed-line
  capture, while inventory and maintenance capture request detailed lines.
- Hardened camera quality diagnostics so normalized receipt photo path aliases
  cannot publish duplicate per-photo evidence.
- Added the local Google ML Kit barcode/QR scanner dependency and a shared
  scanner service for receipt, inventory, and maintenance callers.
- Added barcode/QR result models that normalize duplicate lookup values while
  keeping raw code text out of privacy-safe summaries.
- Blocked sensitive QR payload types such as Wi-Fi, contact, phone, geo, and
  driver-license values from inventory lookup suggestions.
- Added focused retake/order and source-contract regressions for inserted
  section metadata and stale inserted-path rejection.
- Added a focused regression for non-adjacent manual reorder requests.
- Added focused shared camera flow regressions for review-depth propagation.
- Added focused camera-result quality regression coverage for path aliases.
- Added focused barcode scanner service regressions for dedupe, invalid paths,
  sensitive payload handling, and platform failure warnings.
- Split section-order helper logic out of native-signal summaries after the
  source audit caught the file over the line cap.
- Recorded `BUG-RECEIPT-0106` and `BUG-RECEIPT-0107` under
  `multi_photo_ordering`.
- Recorded `BUG-RECEIPT-0108` and `BUG-RECEIPT-0109` under
  `multi_photo_ordering`.
- Recorded `BUG-RECEIPT-0110` under `receipt_line_review_mode`.
- Recorded `BUG-RECEIPT-0111` under `camera_capture_quality`.
- Recorded `BUG-RECEIPT-0112` under `barcode_qr_scanning`.
- Archived Pass 564 out of the live cleanup log to keep the active log under the
  project line-count cap.
- Archived Pass 565 out of the live cleanup log after this pass grew the active
  log past the cap.
- Archived Pass 566 out of the live cleanup log before recording result-level
  insert-order handoff coverage.
- Archived Pass 567 out of the live cleanup log before recording adjacent
  manual-reorder guard coverage.
- Archived Pass 568 out of the live cleanup log before recording camera-quality
  path identity coverage.
- Archived Pass 569 out of the live cleanup log before recording barcode/QR
  scanner coverage.

Verification:
- Passed focused Flutter source-audit contract regression coverage.
- Passed focused work-supply data source audit for hand-written files.
- Confirmed `--include-generated-catalog-data` still reports the oversized
  generated catalog data files.
- Passed targeted analyzer and focused Flutter tests for receipt retake/order
  and long-receipt guidance contracts.
- Passed focused receipt result stitch/scanner regressions for valid and
  malformed insert-after metadata.
- Passed focused manual reorder regressions and source contract coverage.
- Passed focused adjacent manual reorder regression coverage.
- Passed focused shared capture-flow review-depth regression coverage.
- Passed focused camera-result quality path identity regression coverage.
- Passed focused barcode scanner service regression coverage.
- Passed the receipt QA runner after the source-audit and long-receipt ordering
  cleanup batch.
- Passed scoped receipt source audit and cleanup/doc size gates.
- Passed `git diff --check`.

## Pass 588 - 11:55:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native camera session argument readers so receipt
  review depth is normalized before UI labels and diagnostics can use it.
- Added native bridge source regressions requiring safe review-depth readers on
  both platforms.
- Recorded `BUG-RECEIPT-0104` under `receipt_line_review_mode`.
- Ran a broad professional QA gate and stopped on real failures instead of
  bypassing them.
- Hardened derived OCR-source attachment diagnostics so OCR-ready artifacts can
  still inherit aligned original proof-photo continuation and ghost-guide
  evidence.
- Recorded `BUG-RECEIPT-0105` under `ocr_handoff_contract`.
- Fixed app-wide regressions exposed by the broad suite: invoice PDF archive
  hashes, invoice calendar filter focus, dashboard duplicate labels, iOS-native
  navigation route guards, and archived OCR contract documentation checks.
- Fixed low-voltage receipt parser precedence for LV bracket/mud-ring and
  thermostat C-wire adapter receipt lines.
- Split tools/safety parser scoring into its own part file after the source
  audit caught an oversized parser scoring file.
- Reused generated trade-pack payloads for export manifest and chunk writing so
  the catalog pack QA does not build the same payload twice.
- Split oversized receipt parser alias, fallback, and trade-scoring god-files
  into focused part files for terms, trade families, HVAC sections, tile
  waterproofing, and tile tools while preserving behavior.
- Tightened the source audit to ignore third-party iOS plugin symlinks so the
  500-line rule reports app-owned files.
- Archived Pass 561 and Pass 562 out of the live cleanup log to keep the active
  log under
  the project line-count cap.

Verification:
- Fixed a stale iOS source assertion so it matches the current safer
  `doubleArgument` zoom parsing contract.
- Passed targeted Dart format/analyzer for Android and iOS native bridge source
  coverage.
- Passed focused Flutter Android and iOS native bridge regressions.
- Passed targeted receipt-camera OCR-source/continuation regressions and source
  audit contract for split receipt OCR warning coverage.
- Passed targeted app-wide regression batch:
  `test/widget_test.dart`, `test/invoices_home_screen_test.dart`,
  `test/invoice_pdf_preview_action_tracking_test.dart`,
  `test/ios_navigation_gesture_routes_test.dart`, and
  `test/expense_command_center_ocr_contract_doc_test.dart`.
- Passed work-supply parser/export regressions:
  `test/work_supply_low_voltage_tools_receipt_parser_test.dart` and
  `test/work_supply_catalog_pack_payload_test.dart`.
- Passed focused parser cleanup regressions for work-supply catalog aliases,
  electrical/HVAC/low-voltage, large trade matrix, and tile parser coverage.
- Passed `dart analyze lib/screens/work_supplies/data/work_supply_receipt_parser.dart`.
- Passed `git diff --check`.
- Focused work-supply data source audit now shows no hand-written receipt parser
  scoring files over the 500-line cap; remaining failures are generated catalog
  data files that need a separate generated-data strategy.

## Pass 587 - 11:45:00 EDT to 11:49:40 EDT

Scope:
- Hardened shared diagnostic token normalization so malformed receipt
  review-depth strings cannot create oversized metadata keys.
- Extended native review-depth regression coverage to prove invalid depth keys
  stay bounded while remaining visible in privacy-safe handoff metadata.
- Recorded `BUG-RECEIPT-0103` under `receipt_line_review_mode`.
- Archived Pass 560 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for diagnostic token normalization and
  native review-depth metadata coverage.
- Passed focused Flutter malformed review-depth regression.

## Pass 586 - 11:36:00 EDT to 11:39:45 EDT

Scope:
- Hardened privacy-safe OCR/parser line summaries so source section and line
  numbers match the clamped user-facing receipt proof labels.
- Extended parser handoff structure regression coverage for privacy-safe source
  section and line numbers.
- Recorded `BUG-RECEIPT-0102` under `receipt_line_numbering`.
- Archived Pass 559 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for OCR parser models and parser handoff
  structure coverage.
- Passed focused Flutter parser handoff regression for clamped source line
  numbers and privacy-safe summary values.

## Pass 585 - 11:25:00 EDT to 11:29:40 EDT

Scope:
- Hardened OCR/parser source-location labels so malformed section or line
  numbers cannot show impossible receipt proof labels such as line zero.
- Added parser handoff structure regression coverage proving source labels,
  maps, and proof references clamp source section and line numbers to at least
  one.
- Recorded `BUG-RECEIPT-0101` under `receipt_line_numbering`.
- Archived Pass 558 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for OCR parser models and parser handoff
  structure coverage.
- Passed focused Flutter parser handoff regression for clamped source line
  numbers.

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
