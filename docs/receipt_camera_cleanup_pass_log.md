# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 753 - 04:02:09 EDT to active cleanup

Scope:
- Hardened Android and iOS optional auto-capture readiness so malformed live
  framing bounds cannot count as edge-ready capture evidence.
- Reused the native usable-bounds guard added in Pass 752 for auto-capture
  decisions, keeping manual shutter behavior unaffected.
- Added Android/iOS auto-capture source regressions for the usable-bounds guard.
- Recorded `BUG-RECEIPT-0241` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native auto-capture regressions.
- Passed focused Android/iOS native auto-capture bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 752 - 03:59:57 EDT to active cleanup

Scope:
- Hardened Android and iOS live receipt framing so malformed or non-finite
  bounds cannot appear as `framing_ok`.
- Added explicit invalid-bounds diagnostics for frame guidance and perspective
  readiness while preserving `receipt_not_found` for genuinely missing frames.
- Added Android/iOS source regressions for malformed live framing bounds.
- Recorded `BUG-RECEIPT-0240` under `camera_capture_quality`.
- Archived Pass 726 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native framing regressions.
- Passed focused Android/iOS native analysis exposure regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 751 - 03:57:59 EDT to active cleanup

Scope:
- Hardened Android and iOS native live brightness buckets so non-finite preview
  brightness cannot be classified as `lighting_ok`.
- Hardened saved-photo exposure mismatch diagnostics so non-finite live
  brightness resolves to `unknown` instead of healthy alignment.
- Added Android/iOS native exposure regressions for the non-finite live
  brightness guard.
- Recorded `BUG-RECEIPT-0239` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native exposure regressions.
- Passed focused Android/iOS native exposure bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 750 - 03:55:19 EDT to active cleanup

Scope:
- Hardened native live-to-saved luma parity diagnostics so non-finite preview or
  saved-photo brightness values cannot be bucketed as healthy preview-match
  evidence.
- Added Android/iOS source regressions proving non-finite live/saved luma and
  non-finite parity deltas resolve to `unknown`.
- Recorded `BUG-RECEIPT-0238` under `camera_capture_quality`.
- Archived Pass 725 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native live-to-saved parity
  regressions.
- Passed focused Android/iOS native bridge quality regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 749 - 03:52:44 EDT to active cleanup

Scope:
- Hardened native saved-photo bottom/top luma diagnostics so missing or
  non-finite values are bucketed as `unknown` instead of appearing as
  top/bottom brightness-close evidence.
- Added Android/iOS source regressions proving invalid bottom/top luma and
  non-finite delta values cannot look healthy.
- Recorded `BUG-RECEIPT-0237` under `camera_capture_quality`.
- Archived Pass 724 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native quality source regressions.
- Passed focused Android/iOS native bridge quality regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 748 - 03:50:30 EDT to active cleanup

Scope:
- Hardened expense receipt review-mode settings so corrupted non-string Hive
  values cannot crash receipt settings or camera handoff.
- Added focused settings-store regression coverage proving non-string review
  style storage falls back safely to prices-only.
- Recorded `BUG-RECEIPT-0236` under `receipt_line_review_mode`.
- Archived Pass 723 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for expense settings review mode.
- Passed focused expense settings-store regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 747 - 03:48:44 EDT to active cleanup

Scope:
- Hardened Android and iOS native receipt review-depth argument readers so
  snake-case, hyphenated, padded, or cased bridge values preserve prices-only
  versus detailed-line intent.
- Added native source regressions for both bridge argument readers.
- Recorded `BUG-RECEIPT-0235` under `native_bridge`.
- Archived Pass 722 from the active cleanup log to keep the doc under cap and
  removed a stale duplicate verification tail line.

Verification:
- Passed targeted Dart format/analyzer for native bridge review-depth tests.
- Passed focused Android/iOS native bridge UI contract regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 746 - 03:47:31 EDT to active cleanup

Scope:
- Hardened native receipt review-depth diagnostics so snake-case or hyphenated
  bridge values preserve prices-only versus detailed-line intent.
- Added focused regression coverage for `prices-only` and `detailed_lines`
  native review-depth payloads.
- Recorded `BUG-RECEIPT-0234` under `receipt_line_review_mode`.
- Archived Pass 721 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native review-depth diagnostics.
- Passed focused receipt camera result frozen metadata regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 745 - 03:46:09 EDT to active cleanup

Scope:
- Hardened expense receipt review-mode restoration so padded or case-varied
  stored values preserve the user's detailed-line review preference instead of
  silently falling back to prices-only.
- Added focused settings-store regression coverage for normalized receipt review
  style hydration.
- Recorded `BUG-RECEIPT-0233` under `receipt_line_review_mode`.
- Archived Pass 720 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for expense settings review mode.
- Passed focused expense settings-store regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 744 - 03:42:58 EDT to active cleanup

Scope:
- Hardened parser/readiness gates so duplicate OCR line IDs downgrade receipt
  parser, downstream, merchant-independent, mixed-classification, and lean-local
  OCR readiness instead of appearing only as metadata.
- Added a focused regression with an otherwise ready receipt whose duplicate
  line IDs force review before line-numbered proof or split classification.
- Split duplicate line identity coverage into a focused test file after the
  source audit caught the structure test over the line cap.
- Recorded `BUG-RECEIPT-0232` under `receipt_line_numbering`.
- Archived Pass 719 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for parser handoff readiness.
- Passed focused Flutter parser handoff structure and line-identity regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates after splitting the oversized test.

## Pass 743 - 03:41:10 EDT to active cleanup

Scope:
- Hardened receipt line-number handoff so duplicate stable OCR line IDs are
  surfaced as a review-needed identity status instead of silently hiding behind
  first-entry map preservation.
- Added focused regression coverage proving duplicate IDs are counted and
  exposed in the privacy-safe parser handoff contract.
- Recorded `BUG-RECEIPT-0231` under `receipt_line_numbering`.
- Archived Pass 718 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for parser handoff line identity.
- Passed focused Flutter parser handoff structure regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates after correcting the ledger category.

## Pass 742 - 03:39:36 EDT to active cleanup

Scope:
- Hardened barcode/QR privacy so sensitive-looking raw payloads cannot become
  inventory lookup values when ML Kit labels them as generic `text`.
- Added focused regressions for text-bucket QR URLs and Wi-Fi configs so payload
  content classification blocks customer/session/network data.
- Recorded `BUG-RECEIPT-0230` under `privacy_redaction`.
- Archived Pass 717 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service and focused
  scanner regression.
- Passed focused Flutter barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
