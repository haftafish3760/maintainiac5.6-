# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 741 - 03:39:00 EDT to active cleanup

Scope:
- Hardened barcode/QR privacy so malformed value-type labels containing
  sensitive terms cannot be bucketed as harmless `other` payloads.
- Added a focused regression proving malformed customer/private/email type
  labels are treated as sensitive and cannot produce inventory lookup values.
- Recorded `BUG-RECEIPT-0229` under `privacy_redaction`.
- Archived Pass 716 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service and focused
  scanner regression.
- Passed focused Flutter barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 740 - 03:36:30 EDT to active cleanup

Scope:
- Hardened barcode/QR privacy so URL payloads cannot become inventory lookup
  values.
- Added a focused regression proving URL QR values are treated as sensitive
  payloads and stay out of privacy-safe summaries.
- Recorded `BUG-RECEIPT-0228` under `privacy_redaction`.
- Archived Pass 715 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service and focused
  scanner regression.
- Passed focused Flutter barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 739 - 03:35:02 EDT to active cleanup

Scope:
- Audited barcode handoff metadata and kept raw code values out of receipt
  review metadata.
- Promoted the multi-image barcode scan limit warning to its own privacy-safe
  bucket so diagnostics can distinguish bounded work from decoder failures.
- Updated the focused barcode scanner regression for the batch limit bucket.
- Archived Pass 714 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service and focused
  scanner regression.
- Passed focused Flutter barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 738 - 03:33:00 EDT to active cleanup

Scope:
- Added a shared `ReceiptCaptureFlow.scanBarcodesFromReviewResult` handoff
  helper for expense, inventory, and maintenance consumers.
- Routed barcode scanning through OCR-source photos first, with saved proof
  fallback only when the review result already fell back.
- Added focused regressions for OCR-source preference and saved-proof fallback.
- Archived Pass 713 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for capture flow barcode handoff.
- Passed focused Flutter barcode handoff and barcode scanner regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 737 - 03:30:19 EDT to active cleanup

Scope:
- Audited the existing ML Kit barcode/QR service and confirmed the dependency
  and single-image scanner already exist.
- Added a bounded multi-image barcode scan result for long receipts and shared
  camera handoff consumers.
- Added privacy-safe batch summaries and deduped inventory lookup values across
  receipt segments without exposing raw barcode or QR payloads.
- Added focused batch scanner regressions for cross-segment dedupe and segment
  count bounding.
- Archived Pass 712 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service and focused
  barcode scanner regression.
- Passed focused Flutter barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 736 - 03:28:54 EDT to active cleanup

Scope:
- Audited native capture staging fixtures for retired lock diagnostics.
- Replaced stale locked focus/exposure/white-balance fixture state with
  continuous/auto/not-requested diagnostics.
- Updated manifest and recovery-index expectations so staged diagnostics keep
  retired lock attempts at zero.
- Recorded `BUG-RECEIPT-0227` under `qa_harness`.
- Archived Pass 711 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native capture staging fixtures,
  manifest expectations, index expectations, and staging regression.
- Passed focused Flutter native capture staging regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 735 - 03:27:16 EDT to active cleanup

Scope:
- Audited remaining native lock diagnostics after platform argument hardening.
- Hard-coded Android and iOS `whiteBalanceLockEnabled` diagnostics false so
  retired lock state cannot leak through serialized capture diagnostics.
- Updated Android/iOS storage-contract regressions to reject variable-derived
  white-balance lock diagnostics.
- Recorded `BUG-RECEIPT-0226` under `native_bridge`.
- Archived Pass 710 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS native storage bridge
  regressions.
- Passed focused Flutter Android/iOS storage bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 734 - 03:25:54 EDT to active cleanup

Scope:
- Audited native argument readers after the Dart service boundary was hardened.
- Hard-coded Android and iOS `whiteBalanceLockEnabled` false so stale native
  arguments cannot re-enable retired white-balance locking.
- Updated Android/iOS bridge source regressions to reject the stale argument
  trust path.
- Recorded `BUG-RECEIPT-0225` under `native_bridge`.
- Archived Pass 709 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS native bridge exposure
  regressions.
- Passed focused Flutter Android/iOS bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 733 - 03:24:50 EDT to active cleanup

Scope:
- Closed the remaining Dart service payload gap for retired tap focus.
- Hard-coded `tapFocusEnabled` false before native channel handoff instead of
  relying on upstream session policy.
- Extended the service source-contract regression to reject config-derived
  `tapFocusEnabled` payloads.
- Recorded `BUG-RECEIPT-0224` under `native_bridge`.
- Archived Pass 708 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
