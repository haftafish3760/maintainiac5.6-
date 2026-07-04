# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 790 - 08:05:54 EDT to active cleanup

Scope:
- Updated Command Center OCR-start telemetry fixture storage outcome from
  `use_original_for_ocr` to `ocr_clear_source_before_saved_proof_copy`.
- Kept telemetry reporting aligned with the camera/storage policy that OCR reads
  the clear source before the retained saved proof.
- Recorded `BUG-RECEIPT-0277` under `source_preservation`.
- Archived Pass 763 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused telemetry regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 789 - 08:01:22 EDT to active cleanup

Scope:
- Renamed native camera memory-policy diagnostics from original-for-OCR wording
  to temporary-source-for-OCR wording.
- Updated Android/iOS default policy strings, Dart session policy strings, and
  focused fixtures/expectations that consume those diagnostics.
- Kept the legacy `ocrUsesOriginalFirst` bridge key untouched for compatibility.
- Recorded `BUG-RECEIPT-0276` under `source_preservation`.
- Archived Pass 762 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native camera storage,
  session, contract, and staging regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 788 - 07:58:11 EDT to active cleanup

Scope:
- Added a correctly named temporary full-quality OCR source policy getter on
  native camera settings.
- Routed shared session `ocrSourceProtected` through the new getter instead of
  the legacy bridge key name.
- Preserved the platform bridge key for Android/iOS compatibility.
- Recorded `BUG-RECEIPT-0275` under `source_preservation`.
- Archived Pass 761 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native camera contract
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 787 - 07:53:46 EDT to active cleanup

Scope:
- Changed native capture staging's omitted data-saver fallback from original
  retention to balanced saved proof.
- Added a no-argument staging regression proving saved attachments and recovery
  manifests default to `balanced`, not `original`.
- Recorded `BUG-RECEIPT-0274` under `source_preservation`.
- Archived Pass 760 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native staging regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 786 - 07:50:34 EDT to active cleanup

Scope:
- Reworded saved-proof preview copy that labeled the comparison size as an
  original photo.
- Changed the details row to `Capture source size` and the footer to
  `Capture source` so the panel does not imply full original retention.
- Added help-flow source regressions against the stale original-photo label.
- Recorded `BUG-RECEIPT-0273` under `source_preservation`.
- Archived Pass 759 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused help-flow source
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 785 - 07:43:52 EDT to active cleanup

Scope:
- Corrected active camera blueprint, handoff, service, and parallel-boundary
  docs to use temporary full-quality OCR source language.
- Clarified that compressed saved proof is the default retained artifact and
  original-quality proof retention is explicit user choice.
- Added active-doc regressions against stale original-first/source-truth copy.
- Recorded `BUG-RECEIPT-0272` under `source_preservation`.
- Archived Pass 758 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and active-doc regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 784 - 07:40:18 EDT to active cleanup

Scope:
- Fixed a stale Android native UI contract assertion that still required the
  retired original-first OCR copy.
- Updated the contract to require temporary full-quality OCR source copy and
  reject the retired wording.
- Recorded `BUG-RECEIPT-0271` under `qa_harness`.
- Archived Pass 757 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android native UI contract
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 783 - 07:36:42 EDT to active cleanup

Scope:
- Removed stale Android camera status-strip copy that said OCR reads the
  original first.
- Reworded the strip to temporary full-quality OCR source language so users do
  not infer permanent full-size original retention.
- Added a native Android source regression rejecting the stale original-first
  status copy.
- Recorded `BUG-RECEIPT-0270` under `source_preservation`.
- Archived Pass 755 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android native bridge
  source regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 782 - 07:32:31 EDT to active cleanup

Scope:
- Hardened receipt quality guidance so critical-but-decodable photos still
  advertise manual review availability while auto-capture remains blocked.
- Kept unreadable/corrupt images out of the continue-with-review signal.
- Added quality regressions for glare retake guidance, manual Next availability,
  and unreadable-image exclusion.
- Recorded `BUG-RECEIPT-0269` under `camera_capture_quality`.
- Archived Pass 754 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused quality guidance test.
- Passed doc-size, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.

## Pass 781 - 07:27:48 EDT to active cleanup

Scope:
- Clarified OCR-source storage language so the app says temporary full-quality
  photo/source instead of implying permanent original retention.
- Updated Android, iOS, shared handoff labels, and the handoff report boundary
  to match the policy that saved proof is the normal retained artifact.
- Added/updated native bridge source regressions for the revised storage copy.
- Recorded `BUG-RECEIPT-0268` under `source_preservation`.
- Archived Pass 753 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native bridge source tests.
- Passed doc-size, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.

## Pass 780 - 07:20:47 EDT to active cleanup

Scope:
- Hardened OCR scanner-preparation signal/risk handoff for normalized paths.
- Replaced raw `preparationDiagnosticsByOcrPath` lookups with normalized
  receipt-photo map lookups in attachment and capture-flow helpers.
- Added source regressions proving scanner preparation metadata does not depend
  on raw OCR source path equality.
- Recorded `BUG-RECEIPT-0267` under `source_preservation`.
- Archived Pass 752 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Flutter OCR source
  attachment/handoff contract regressions.
- Passed doc-size, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.

## Pass 779 - 07:04:11 EDT to active cleanup

Scope:
- Hardened OCR source quality/warning handoff for normalized-equivalent paths.
- Replaced raw OCR source diagnostics and quality lookups with normalized
  receipt-photo map lookups in shared attachment and capture-flow helpers.
- Added source regressions proving quality and capture diagnostics use
  normalized lookup instead of raw OCR source path equality.
- Recorded `BUG-RECEIPT-0266` under `source_preservation`.
- Archived Pass 751 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Flutter OCR source
  attachment/handoff contract regressions.
- Passed doc-size, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.

## Pass 778 - 06:29:36 EDT to active cleanup

Scope:
- Hardened shared reviewed-photo acceptance so existing receipt photo read
  states survive adding picked photos, native capture, and recovery review.
- Added normalized previous-read-state restoration to `_acceptReviewedPhotoResult`
  while keeping newly added receipt photos marked as not read.
- Added source regressions proving accepted review paths preserve previous read
  state metadata.
- Recorded `BUG-RECEIPT-0265` under `source_preservation`.
- Archived Pass 750 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for accepted review read-state changes.
- Passed focused Flutter OCR-source attachment read regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.

## Pass 777 - 06:24:09 EDT to active cleanup

Scope:
- Hardened attachment review acceptance so existing photo IDs and read states
  survive review-screen path normalization.
- Replaced raw previous-map key lookups with normalized receipt photo path
  matching for accepted review results.
- Added source regressions proving normalized previous-photo map lookups protect
  accepted attachment identity/read-state continuity.
- Recorded `BUG-RECEIPT-0264` under `source_preservation`.
- Archived Pass 749 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for accepted review map lookup changes.
- Passed focused Flutter OCR-source attachment read regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.

## Pass 776 - 06:10:03 EDT to active cleanup

Scope:
- Hardened attachment-panel picked-photo review so existing receipt capture
  diagnostics are preserved when newly picked photos are added to review.
- Merged existing `_photoCaptureDiagnosticsByPath` with new pick diagnostics,
  matching the existing quality-check merge behavior.
- Added a source regression proving both existing and new diagnostics are passed
  into `ReceiptPhotoReviewScreen`.
- Recorded `BUG-RECEIPT-0263` under `camera_review_state`.
- Archived Pass 748 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for attachment diagnostics handoff.
- Passed focused Flutter attachment recovery contract regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 775 - 06:02:17 EDT to active cleanup

Scope:
- Ran a broader focused regression bundle across the camera/review path
  normalization work from Passes 764-774.
- Covered shared capture flow, interrupted native recovery, long-receipt
  guidance, native bridge layout, camera capture layout, and photo-review
  lifecycle source contracts.
- Archived Pass 747 from the active cleanup log to keep the doc under cap.

Verification:
- Passed focused Flutter regression bundle:
  `test/receipt_capture_flow_shareability_test.dart`,
  `test/receipt_capture_flow_recovery_contract_test.dart`,
  `test/receipt_camera_long_receipt_guidance_test.dart`,
  `test/receipt_camera_capture_layout_test.dart`,
  `test/receipt_camera_native_bridge_layout_test.dart`, and
  `test/receipt_photo_review_save_lifecycle_test.dart`.

## Pass 774 - 05:58:15 EDT to active cleanup

Scope:
- Updated the long-receipt guidance source regression after the review screen
  moved from raw initial photo counts to normalized initial photo counts.
- Required the test to prove `_initialReviewMode` is driven by
  `_initialPhotoPaths.length` and that initial paths are normalized once.
- Recorded `BUG-RECEIPT-0262` under `qa_harness`.
- Archived Pass 746 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for long-receipt guidance regression.
- Passed focused Flutter long-receipt guidance regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 773 - 05:54:18 EDT to active cleanup

Scope:
- Hardened recovered native-capture review opening so the first recovered photo
  index uses the normalized existing receipt photo count.
- Prevented invalid or duplicate existing review paths from shifting recovered
  receipt photos to the wrong selected section.
- Added a recovery-contract source regression for normalized recovered-photo
  index calculation.
- Recorded `BUG-RECEIPT-0261` under `camera_review_state`.
- Archived Pass 745 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for recovery review index changes.
- Passed focused Flutter recovery contract regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 772 - 05:51:44 EDT to active cleanup

Scope:
- Hardened attachment-panel review opening so Add Existing Photo / picked-photo
  review uses the normalized existing receipt photo count for the first new
  section index.
- Prevented invalid or duplicate existing attachment photo paths from shifting
  the review screen away from newly picked receipt photos.
- Added source regressions for normalized first-new-photo index calculation.
- Recorded `BUG-RECEIPT-0260` under `camera_review_state`.
- Archived Pass 744 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for attachment review index changes.
- Passed focused Flutter camera capture layout/native bridge layout
  regressions.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 771 - 05:44:56 EDT to active cleanup

Scope:
- Hardened shared camera review-opening selection so the old-photo offset uses
  the same normalized initial receipt photo count as the review screen.
- Prevented invalid or duplicate existing photo paths from shifting selection
  away from the newly staged receipt section.
- Added a source regression tying review-opening index math to
  `uniqueNormalizedReceiptPhotoPaths`.
- Recorded `BUG-RECEIPT-0259` under `camera_review_state`.
- Archived Pass 743 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for review-opening offset changes.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 770 - 05:41:14 EDT to active cleanup

Scope:
- Hardened initial photo-review capture diagnostics so raw map keys are
  normalized and matched against the normalized initial receipt photo list
  before entering mutable review state.
- Dropped blank, unnormalized, duplicate, or non-review diagnostics keys and
  froze accepted diagnostic maps at the screen boundary.
- Added a source regression preventing raw `initialCaptureDiagnosticsByPath`
  spreads from returning.
- Recorded `BUG-RECEIPT-0258` under `camera_review_state`.
- Archived Pass 742 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for initial diagnostics key changes.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 769 - 05:39:20 EDT to active cleanup

Scope:
- Hardened initial photo-review quality checks so raw map keys are normalized
  and matched against the normalized initial receipt photo list before use.
- Dropped blank, unnormalized, duplicate, or non-review quality-check keys
  instead of preserving them in review state.
- Added a source regression preventing raw `initialQualityChecksByPath` spreads
  from returning.
- Recorded `BUG-RECEIPT-0257` under `camera_review_state`.
- Archived Pass 741 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for initial quality-check key changes.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 768 - 05:35:04 EDT to active cleanup

Scope:
- Hardened the photo review screen so initial receipt photo paths are normalized
  and de-duplicated once before becoming the in-memory review path list.
- Switched initial quality checks, review-mode selection, and recoverable-photo
  detection to the normalized initial path list instead of raw widget input.
- Added source regressions for the normalized initial-photo source of truth.
- Recorded `BUG-RECEIPT-0256` under `camera_review_state`.
- Archived Pass 740 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for photo-review initial path changes.
- Fixed the initial source-regression assertion scope so it checks the
  normalized-path length in the review-screen source, not the save-actions
  source bundle.
- Passed focused Flutter capture-flow shareability and save-lifecycle
  regressions.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 767 - 05:32:59 EDT to active cleanup

Scope:
- Hardened shared camera review opening so continuation flows clamp the
  requested selected index within the newly staged photo set before offsetting
  by pre-existing photos.
- Prevented negative or oversized `initialSelectedIndex` values from selecting
  an older receipt photo instead of the newly captured section.
- Added a source regression for the review-opening index helper.
- Recorded `BUG-RECEIPT-0255` under `camera_review_state`.
- Archived Pass 739 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for review-opening index changes.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 766 - 05:21:09 EDT to active cleanup

Scope:
- Hardened capture-flow previous-section diagnostics so direct malformed ghost
  fractions cannot produce non-finite metadata or throwing slice-percent math.
- Bounded source, overlay, height, and opacity fractions to 0..1 with malformed
  values falling back to zero before diagnostics are emitted.
- Added a source regression preventing raw ghost-height option rounding from
  returning to the diagnostics helper.
- Recorded `BUG-RECEIPT-0254` under `multi_photo_ordering`.
- Archived Pass 738 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for capture-flow diagnostics changes.
- Fixed the initial source-regression assertion mismatch caused by Dart format
  splitting the slice-percent expression across lines.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates. The first
  source-audit attempt raced another `dart run` audit on native asset setup;
  the same audit passed when rerun by itself.

## Pass 765 - 05:07:23 EDT to active cleanup

Scope:
- Hardened capture-flow continuation guide options so unsafe previous-photo
  paths cannot be preserved before native session construction.
- Reused the native camera local image path sanitizer for continuation guide
  creation, manual guide application, and flow diagnostics.
- Prevented diagnostics from claiming a previous-section guide photo is
  available when the path is relative, URL-like, non-image, or NUL-tainted.
- Added capture-flow regressions for unsafe previous-photo guide families.
- Recorded `BUG-RECEIPT-0253` under `multi_photo_ordering`.
- Archived Pass 737 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for capture-flow continuation changes.
- Fixed the initial analyzer/test failure caused by a private helper crossing
  Dart library boundaries by making the sanitizer a public contract helper.
- Passed focused Flutter capture-flow shareability regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.

## Pass 764 - 04:52:58 EDT to active cleanup

Scope:
- Hardened the Dart native camera session boundary so previous-section ghost
  guide paths must be local absolute image-like paths before native handoff.
- Rejected relative paths, URLs, `file://` URIs, non-image files, and NUL-tainted
  guide paths before the app marks a long-receipt guide as active.
- Kept previous-section reason, guidance, and ghost fractions disabled whenever
  the guide photo path itself is invalid.
- Added Dart session regressions for unsafe guide path families.
- Recorded `BUG-RECEIPT-0252` under `multi_photo_ordering`.
- Archived Pass 736 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for session boundary changes.
- Passed focused Flutter native camera session limit regression.
- Passed doc-size, bug-ledger, source-audit, and test-audit gates.
