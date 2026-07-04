# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 763 - 04:52:58 EDT to active cleanup

Scope:
- Hardened Android and iOS previous-section guide loaders so the long-receipt
  ghost overlay only accepts trimmed local absolute image paths.
- Removed Android's non-image `setImageURI` fallback so existing non-image
  files cannot appear as continuation guides.
- Added Android/iOS source regressions for local image guide enforcement.
- Recorded `BUG-RECEIPT-0251` under `multi_photo_ordering`.
- Archived Pass 735 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for previous-section guide regressions.
- Passed focused Android settings-quality and iOS long-receipt quality tests.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 762 - 04:41:45 EDT to active cleanup

Scope:
- Hardened Android and iOS previous-section ghost crop boundaries so malformed
  source start/height fractions cannot create unsafe overlap guide crops.
- Added local crop-boundary fallbacks in addition to session argument
  sanitization, preserving long-receipt continuation guidance if future call
  paths mutate the values.
- Added Android/iOS native ghost overlay source regressions for safe crop
  fractions.
- Recorded `BUG-RECEIPT-0250` under `multi_photo_ordering`.
- Archived Pass 734 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for ghost overlay regressions.
- Passed focused Android settings-quality and iOS long-receipt quality tests.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 761 - 04:33:00 EDT to active cleanup

Scope:
- Hardened Android and iOS receipt bottom-edge status so non-finite saved-photo
  edge scores or live edge coverage cannot claim `bottom_visible`.
- Kept malformed bottom-edge evidence on the existing `not_evaluated` path
  before OCR/review completion decisions consume it.
- Added Android/iOS native bottom-edge source regressions for finite edge
  evidence checks.
- Recorded `BUG-RECEIPT-0249` under `camera_capture_quality`.
- Archived Pass 733 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for bottom-edge regressions.
- Passed focused Android close-controls and iOS long-receipt quality tests.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 760 - 04:26:36 EDT to active cleanup

Scope:
- Hardened Android and iOS saved-photo vertical quality scoring so non-finite
  band luma or edge samples cannot appear as even vertical quality or bottom
  blur evidence.
- Kept malformed vertical-quality samples on the existing `unknown` path.
- Added Android/iOS native vertical-quality source regressions for finite sample
  checks.
- Recorded `BUG-RECEIPT-0248` under `camera_capture_quality`.
- Archived Pass 732 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for vertical-quality regressions.
- Passed focused Android close-controls and iOS long-receipt quality tests.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 759 - 04:16:42 EDT to active cleanup

Scope:
- Hardened Android and iOS saved-photo brightness and sharpness bucket helpers
  so non-finite captured samples cannot look like glare or high-contrast edge
  evidence.
- Kept malformed saved-photo samples on the existing `unknown` quality path.
- Added Android/iOS native quality source regressions for non-finite brightness
  and sharpness buckets.
- Recorded `BUG-RECEIPT-0247` under `camera_capture_quality`.
- Archived Pass 731 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native quality regressions.
- Passed focused Android/iOS native quality bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 758 - 04:08:20 EDT to active cleanup

Scope:
- Hardened Android and iOS pre-capture exposure prep so non-finite live
  brightness cannot trigger last-second exposure changes before saving a
  receipt photo.
- Kept malformed brightness on the existing `brightness_unknown` pre-capture
  skip path.
- Added Android/iOS native exposure source regressions for finite pre-capture
  brightness checks.
- Recorded `BUG-RECEIPT-0246` under `camera_capture_quality`.
- Archived Pass 730 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for pre-capture exposure regressions.
- Passed focused Android/iOS native analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 757 - 04:06:53 EDT to active cleanup

Scope:
- Hardened iOS manual exposure bias handling so non-finite slider or direct bias
  values cannot reach `setExposureTargetBias`.
- Added a safe zero-based clamp fallback and a final setter guard for malformed
  exposure bias input.
- Added iOS source regressions for finite exposure-bias handling.
- Recorded `BUG-RECEIPT-0245` under `camera_capture_quality`.
- Archived Pass 729 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for iOS exposure-bias regressions.
- Passed focused iOS native analysis exposure regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 756 - 04:05:37 EDT to active cleanup

Scope:
- Hardened Android and iOS pinch zoom so non-finite gesture scale or zoom
  factors cannot reach native camera zoom controls.
- Added `zoom_invalid_scale` diagnostics for rejected malformed zoom input while
  preserving normal pinch zoom behavior.
- Added Android/iOS source regressions for non-finite zoom guards.
- Recorded `BUG-RECEIPT-0244` under `camera_capture_quality`.
- Archived Pass 728 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native zoom regressions.
- Passed focused Android close-controls and iOS analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 755 - 04:04:36 EDT to active cleanup

Scope:
- Hardened Android and iOS native auto-exposure so non-finite live brightness
  cannot trigger brighten/dim exposure adjustments.
- Kept unknown brightness on the existing `brightness_unknown` decision path and
  reset any pending exposure candidate before returning.
- Added Android/iOS exposure source regressions for finite brightness guards.
- Recorded `BUG-RECEIPT-0243` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native exposure regressions.
- Passed focused Android/iOS native analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 754 - 04:03:12 EDT to active cleanup

Scope:
- Hardened Android and iOS live readability so non-finite brightness, motion, or
  shadow samples cannot fall through to `lighting_ok`.
- Added explicit `readability_unknown` diagnostics for malformed native live
  quality samples while leaving manual capture available.
- Added Android/iOS source regressions for non-finite live readability inputs.
- Recorded `BUG-RECEIPT-0242` under `camera_capture_quality`.
- Archived Pass 727 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native readability regressions.
- Passed focused Android/iOS native analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
