# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 718 - 02:40:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native receipt capture temp filenames so they include
  a UUID in addition to the timestamp.
- Added native bridge source regressions proving timestamp-only receipt capture
  filenames cannot return.
- Recorded `BUG-RECEIPT-0206` under `multi_photo_ordering`.
- Archived Pass 691 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS bridge regressions.
- Passed focused Android/iOS native bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 717 - 02:39:00 EDT to active cleanup

Scope:
- Hardened `ReceiptNativeCameraService` so native results cannot return more
  receipt photo paths than the session `maxSectionCount` allows.
- Added a focused regression where long-receipt mode is disabled but the native
  bridge returns two receipt paths.
- Recorded `BUG-RECEIPT-0205` under `multi_photo_ordering`.

Verification:
- Passed Dart format/analyzer for native section-count validation.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 716 - 02:37:00 EDT to active cleanup

Scope:
- Added a focused native path-validation regression proving NUL-containing
  receipt photo paths are rejected before OCR/staging handoff.
- Recorded `BUG-RECEIPT-0204` under `source_preservation`.

Verification:
- Passed Dart format/analyzer for native path validation regression.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 715 - 02:32:00 EDT to active cleanup

Scope:
- Split native receipt path validation regressions into
  `test/receipt_native_camera_result_path_validation_test.dart` so the primary
  native result rejection test is no longer one line under the project cap.
- Kept duplicate, non-local, and non-image path regressions intact in the new
  focused test file.
- Recorded `BUG-RECEIPT-0203` under `qa_harness`.
- Archived Pass 690 from the active cleanup log to keep the doc under cap.

Verification:
- Passed Dart format/analyzer for native result and path validation tests.
- Passed focused native result and path validation regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 714 - 02:31:00 EDT to active cleanup

Scope:
- Extended native receipt path validation so local paths must also be image-like
  receipt captures before OCR/staging handoff.
- Added a regression rejecting a local `.txt` path returned from the native
  camera platform channel.
- Recorded `BUG-RECEIPT-0202` under `source_preservation`.
- Archived Pass 689 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native receipt image path
  validation.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 713 - 02:29:00 EDT to active cleanup

Scope:
- Hardened `ReceiptNativeCameraService` so native camera results must return
  local absolute receipt photo paths before OCR/staging handoff.
- Added a regression rejecting URL and relative-path receipt results from the
  platform channel.
- Recorded `BUG-RECEIPT-0201` under `source_preservation`.
- Archived Pass 688 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native receipt path validation.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 712 - 02:27:00 EDT to active cleanup

Scope:
- Tightened native capture ID sanitization so malformed, path-like, spaced, or
  oversized IDs become opaque `native_capture_N` values instead of preserving
  sanitized user-looking words.
- Updated the native result regression to prove path-like names and oversized
  receipt IDs do not survive as staging metadata.
- Recorded `BUG-RECEIPT-0200` under `privacy_redaction`.
- Archived Pass 687 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native capture ID sanitization.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 711 - 02:25:00 EDT to active cleanup

Scope:
- Hardened the shared native camera result boundary so Android/iOS
  `temporaryCaptureIds` are sanitized, bounded, and capped to the returned
  photo count before the result leaves `ReceiptNativeCameraService`.
- Added a regression with path-like, oversized, and extra native capture IDs so
  malformed metadata cannot spread into staging manifests or diagnostics.
- Recorded `BUG-RECEIPT-0199` under `native_bridge`.
- Archived Pass 686 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service boundary
  and result regression.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 710 - 02:23:00 EDT to active cleanup

Scope:
- Tightened shared Flutter receipt help copy so it names continuous
  autofocus/readability guidance instead of generic continuous focus.
- Replaced first-use intro `flash, focus` wording with `flash, readability
  guidance` so the shared camera entry point does not imply a manual focus
  feature.
- Added help-flow source regressions for the updated copy and the retired
  generic focus phrase.
- Recorded `BUG-RECEIPT-0198` under `camera_capture_quality`.
- Archived Pass 652 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the receipt camera help flow.
- Passed focused receipt camera help flow regression.
- First cleanup log gate failed at 501 lines; archived Pass 653 and reran the
  gate before milestone push.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 709 - 02:21:00 EDT to active cleanup

Scope:
- Removed stale Android native settings copy that still told users to use focus
  assist after the receipt camera moved to continuous-autofocus/readability
  guidance.
- Added focused Android bridge source regression coverage so retired focus
  assist copy cannot return through settings/help text.
- Recorded `BUG-RECEIPT-0197` under `camera_capture_quality`.
- Archived Pass 651 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the Android settings bridge test.
- Passed focused Android settings bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 708 - 02:45:00 EDT to active cleanup

Scope:
- Removed stale iOS native settings copy that still told users to use focus
  assist after the receipt camera moved to continuous-autofocus/readability
  guidance.
- Added focused iOS bridge source regression coverage so the retired focus
  assist copy cannot return through settings/help text.
- Fixed stale iOS bridge QA assertions that still expected direct raw
  readability-signal equality checks instead of the named readability-review
  policy set.
- Recorded `BUG-RECEIPT-0195` under `camera_capture_quality`.
- Recorded `BUG-RECEIPT-0196` under `qa_harness`.
- Archived Pass 650 from the active cleanup log to keep the doc under cap.

Verification:
- First focused iOS settings bridge regression failed because the test still
  expected raw `latestReadabilitySignal == ...` checks; fixed the regression to
  require the helper/set policy and reject direct equality checks.
- Passed targeted Dart format/analyzer for the iOS settings bridge test.
- Passed focused iOS settings bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 707 - 02:38:00 EDT to active cleanup

Scope:
- Audited native long-receipt ghost-guide argument parsing after the tap-focus
  boundary hardening.
- Fixed iOS previous-section guide path handling so it stores the trimmed path
  instead of keeping whitespace around the local receipt image path.
- Added focused iOS bridge regression coverage for the trimmed ghost-guide path.
- Recorded `BUG-RECEIPT-0194` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for iOS long-receipt bridge test.
- Passed focused iOS long-receipt bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 649 from the active cleanup log to keep the doc under cap.

## Pass 706 - 02:31:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native session argument readers so stale or malformed
  bridge arguments cannot re-enable tap-focus for receipt capture.
- Forced the native tap-focus policy to
  `continuous_focus_primary_no_tap_focus` at both platform boundaries.
- Updated Android and iOS bridge regressions to reject raw tap-focus argument
  trust.
- Recorded `BUG-RECEIPT-0193` under `native_bridge`.
- Archived Pass 647 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native bridge tests.
- Passed focused Android/iOS bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 648 from the active cleanup log to keep the doc under cap.

## Pass 705 - 02:25:00 EDT to active cleanup

Scope:
- Aligned in-entry draft receipt line numbering with the saved ledger line
  guardrails so malformed OCR line or section numbers cannot show impossible
  proof labels before save.
- Added bounded draft line/section helpers and routed draft proof labels, OCR
  source labels, and redaction anchors through them.
- Expanded the assisted-review source fixture so regression coverage includes
  the shared draft line support and label helpers.
- Recorded `BUG-RECEIPT-0192` under `receipt_line_numbering`.
- Archived Pass 646 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for draft receipt line helpers and
  assisted-review source regression.
- Passed focused Flutter assisted receipt review flow regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 704 - 02:18:00 EDT to active cleanup

Scope:
- Audited the shared Google ML Kit barcode/QR scanner foundation after the
  camera-lane reminder to keep scanner support shared across expenses,
  inventory, and maintenance without touching inventory internals.
- Added corrupted/wrong-file style regression coverage so generic decoder
  failures become safe `barcode_scan_failed` warnings.
- Proved raw exception text from barcode failures does not leak into
  privacy-safe scanner summaries.
- Recorded `BUG-RECEIPT-0191` under `barcode_qr_scanning`.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service tests.
- Passed focused Flutter barcode scanner service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 645 from the active cleanup log to keep the doc under cap.

## Pass 703 - 02:12:00 EDT to active cleanup

Scope:
- Audited active receipt camera docs and focus policy after retiring tap-focus
  as a product answer.
- Strengthened the active-doc focus regression so the exact `tap-focus` phrase
  cannot come back into active camera docs.
- Removed the stale active native service spec sentence that still described
  tap-focus as legacy diagnostics.
- Recorded `BUG-RECEIPT-0190` under `qa_harness`.

Verification:
- Initial focused regression failed on the stale native service spec sentence;
  fixed it before moving on.
- Passed targeted Dart format/analyzer for the active camera docs policy test.
- Passed focused Flutter active camera docs focus-policy regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 644 from the active cleanup log to keep the doc under cap.

## Pass 702 - 02:06:00 EDT to active cleanup

Scope:
- Hardened continuation guide application so manual guide construction cannot
  leak untrimmed reason/guidance/path values or malformed ghost overlay
  fractions into shared capture options.
- Clamped out-of-range ghost fractions and dropped non-finite fractions before
  native camera session arguments can inherit continuation context.
- Added focused regression coverage for malicious/manual continuation guide
  values.
- Recorded `BUG-RECEIPT-0189` under `ghost_overlap_stitching`.
- Archived Passes 642 and 643 from the active cleanup log to keep the doc
  under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow models.
- Passed focused Flutter receipt capture flow shareability regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 701 - 01:45:00 EDT to active cleanup

Scope:
- Strengthened long-receipt continuation coverage so Add Photo/continuation
  guides prove they preserve module-default detailed review intent.
- Added direct assertions for materials inventory and maintenance continuation
  staying detailed-line review while expense continuation remains price-only by
  default unless forced.
- Kept missing-bottom/totals ghost context expectations pinned in the same
  shared-flow regression.
- Recorded `BUG-RECEIPT-0188` under `qa_harness`.
- Archived Pass 641 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt capture flow shareability.
- Passed focused Flutter receipt capture flow shareability regression.

## Pass 700 - 01:40:00 EDT to active cleanup

Scope:
- Promoted module-specific receipt review depth into a direct
  `ReceiptCaptureFlowOptions.effectiveReviewDepth` contract.
- Updated the shared capture settings builder to use that model contract instead
  of a private helper, making the inventory/maintenance detailed-line default
  directly testable.
- Strengthened the shareability regression so it asserts behavior for expenses,
  shared, materials inventory, maintenance/repair, and forced overrides.
- Recorded `BUG-RECEIPT-0187` under `qa_harness`.
- Archived Pass 640 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow models.
- Passed focused Flutter receipt capture flow shareability regression.

## Pass 699 - 01:34:00 EDT to active cleanup

Scope:
- Hardened receipt line review-mode detection so raw OCR evidence, catalog item
  evidence, or parser classification keeps a line in detailed review even when
  the cleaned display description is still generic.
- Preserved privacy-safe output by proving raw OCR receipt text does not leak
  through the line review contract.
- Added focused regression coverage for OCR-only detailed line evidence.
- Recorded `BUG-RECEIPT-0186` under `receipt_line_review_mode`.
- Archived Pass 639 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for expense receipt line records.
- Passed focused Flutter expense receipt line record regression.

## Pass 698 - 01:29:00 EDT to active cleanup

Scope:
- Fixed shared receipt capture defaults so materials-inventory and
  maintenance/repair launches use detailed-line review when no caller forces a
  review depth.
- Kept expenses and generic shared launches price-only by default, preserving
  the fast review path unless the caller or expense settings asks for details.
- Added a focused shared-flow regression guarding the module-specific review
  depth default and the existing attachment UI override path.
- Recorded `BUG-RECEIPT-0185` under `receipt_line_review_mode`.
- Archived Pass 638 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow.
- Passed focused Flutter receipt capture flow shareability regression.

## Pass 697 - 01:23:00 EDT to active cleanup

Scope:
- Removed stale active handoff wording that still said users can tap to focus
  during the production receipt camera flow.
- Replaced it with continuous autofocus/readability guidance plus pinch zoom,
  brightness/exposure, and torch controls where supported.
- Extended the active camera docs focus-policy regression to cover the long
  2026-07-03 receipt camera handoff and reject tap-to-focus flow wording.
- Recorded `BUG-RECEIPT-0184` under `camera_capture_quality`.
- Archived Pass 637 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer for the active camera docs focus-policy test.
- Passed focused Flutter active camera docs focus-policy regression.

## Pass 696 - 01:18:00 EDT to active cleanup

Scope:
- Removed stale active native-camera service spec wording that still listed tap
  focus as a camera hardware control.
- Reworded native service current-state guidance around continuous
  focus/readability instead of generic focus adjustment.
- Extended the active camera docs focus-policy regression to cover the native
  service spec and reject tap focus as an active control list item.
- Recorded `BUG-RECEIPT-0183` under `camera_capture_quality`.
- Archived Pass 636 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer for the active camera docs focus-policy test.
- Passed focused Flutter active camera docs focus-policy regression.

## Pass 695 - 01:10:00 EDT to active cleanup

Scope:
- Carried layout redaction telemetry into the expense telemetry client-proof
  summary so Command Center can see visible, hidden, ignored, protected-type,
  merchant-context, and totals-context layout counts.
- Added Command Center and Firestore summary sanitizer coverage for the new
  layout redaction rollup keys and top layout status.
- Extended focused telemetry workflow and parity fixtures so admin summaries
  cannot silently drop layout redaction evidence.
- Recorded `BUG-RECEIPT-0182` under `privacy_redaction`.
- Archived Pass 635 from the active cleanup log to keep the doc under cap.

Verification:
- First focused test run exposed that layout context booleans were missing from
  the expense telemetry metadata allowlist; fixed before continuing.
- Second focused test run exposed missing Firestore parity keys and an
  under-exercised rich parity fixture; fixed both before continuing.
- Passed targeted Dart analyzer for expense telemetry redaction rollups.
- Passed focused Flutter expense telemetry workflow, sanitizer, and Firestore
  Command Center parity regressions.

## Pass 694 - 01:05:00 EDT to active cleanup

Scope:
- Aggregated privacy-safe layout redaction telemetry into the receipt privacy
  health snapshot and Command Center map.
- Added policy and telemetry metadata allowlist coverage for layout redaction
  status, visible/hidden/ignored counts, protected-type counts, and context
  booleans.
- Extended the health fixture regression so stored layout redaction events prove
  the rollup cannot silently drop QA/admin redaction visibility.
- Recorded `BUG-RECEIPT-0181` under `privacy_redaction`.
- Archived Pass 634 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt privacy health redaction
  telemetry.
- Passed focused Flutter receipt privacy event store regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 693 - 00:55:10 EDT to active cleanup

Scope:
- Added a privacy-safe receipt event path for layout redaction plans so
  QA/admin telemetry can see visible, hidden, ignored, and protected line
  counts without receipt text or anchor IDs.
- Added scalar serialization for layout redaction status, counts, and context
  booleans.
- Added regression coverage proving ignored line-target telemetry stays
  privacy-safe.
- Recorded `BUG-RECEIPT-0180` under `privacy_redaction`.
- Archived Passes 633 and 632 from the active cleanup log to keep the doc under
  cap.

Verification:
- First focused regression run failed because the tiny fixture did not prove
  merchant-context detection; fixed the fixture to use recognizable receipt
  structure.
- Passed targeted Dart format/analyzer for receipt privacy event redaction
  telemetry.
- Passed focused Flutter receipt privacy event regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 692 - 00:53:45 EDT to active cleanup

Scope:
- Added a privacy-safe receipt layout redaction summary so QA/admin diagnostics
  can see visible, hidden, ignored, and protected line counts without receipt
  text.
- Included safe redaction anchor codes and protected content buckets while
  keeping raw OCR/item text out of the summary.
- Added regression coverage proving ignored line-target requests are summarized
  safely and raw receipt text is not exposed.
- Recorded `BUG-RECEIPT-0179` under `privacy_redaction`.
- Archived Pass 631 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt layout redaction summary.
- Passed focused Flutter direct parser/layout redaction regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.
