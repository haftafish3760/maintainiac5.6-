# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 732 - 03:23:50 EDT to active cleanup

Scope:
- Extended retired-control hardening from tap focus to focus, exposure, and
  white-balance lock enablement at the Dart service boundary.
- Hard-coded retired lock enablement fields false before native channel handoff.
- Added a service source-contract regression rejecting lock enablement derivation
  from session config.
- Recorded `BUG-RECEIPT-0223` under `native_bridge`.
- Archived Pass 707 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 731 - 03:22:11 EDT to active cleanup

Scope:
- Audited remaining tap-focus references after removing retired controls from
  capability policy scoring.
- Hard-coded the Dart service contract payload so `tapFocusControlExpected`
  stays false instead of deriving from `config.tapFocusEnabled`.
- Added a service source-contract regression proving the retired tap-focus
  expected flag cannot be reconnected through the service helper.
- Recorded `BUG-RECEIPT-0222` under `native_bridge`.
- Archived Pass 706 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 730 - 03:17:54 EDT to active cleanup

Scope:
- Removed retired lock controls from native capability policy scoring so
  capable devices can still report full camera assist.
- Kept lock enablement false, but stopped treating retired locks as a degraded
  capability or noisy policy code.
- Removed retired tap-focus controls from capability policy scoring after the
  focused test caught capable devices losing their full-assist policy code.
- Added session/channel regressions proving retired-lock policy noise stays out
  while full camera assist remains possible.
- Recorded `BUG-RECEIPT-0220` and `BUG-RECEIPT-0221` under `native_bridge`.
- Archived Pass 705 from the active cleanup log to keep the doc under cap.

Verification:
- Focused test caught `BUG-RECEIPT-0221`; fix added before continuing.
- Passed targeted Dart format/analyzer for native camera capability policy,
  session settings, channel expectations, and focused contract tests.
- Passed focused Flutter native session, settings-contract, and channel
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 729 - 03:15:57 EDT to active cleanup

Scope:
- Removed remaining active native service spec wording that listed
  focus/exposure/white-balance lock controls after the receipt camera moved to
  continuous autofocus/readability guidance.
- Removed dormant lock-tag builder lines from current Dart session config so a
  future flag flip cannot re-add `focus_lock`, `brightness_lock`, or
  `white_balance_lock` tags.
- Extended active-doc and session-contract regressions for retired lock-control
  wording and tags.
- Recorded `BUG-RECEIPT-0219` under `native_bridge`.
- Archived Pass 704 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused active-doc/session
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 728 - 03:11:18 EDT to active cleanup

Scope:
- Retired Dart-side focus/exposure/white-balance lock enablement so current
  receipt camera sessions no longer advertise lock controls or lock tags.
- Removed lock-control descriptors from the current receipt camera settings
  list, keeping continuous focus/readability guidance as the product path.
- Replaced lock-unavailable capability policy noise with a retired-lock policy
  code and updated channel/staging/native UI fixtures.
- Recorded `BUG-RECEIPT-0218` under `native_bridge`.
- Archived Pass 703 from the active cleanup log to keep the doc under cap.

Verification:
- First focused batch exposed stale previous-section capability-policy and
  native UI tag-count expectations; fixed before continuing.
- Passed targeted Dart format/analyzer and focused native contract/channel/
  staging/UI regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 727 - 03:07:12 EDT to active cleanup

Scope:
- Pinned Android, iOS, and Dart bridge diagnostics so retired focus/exposure/
  white-balance lock controls are never reported as expected receipt-camera
  controls.
- Kept legacy lock setting fields available separately for compatibility while
  preventing them from driving expected-control health.
- Updated staging/channel fixtures and Android/iOS bridge regressions for the
  retired lock-control expected values.
- Recorded `BUG-RECEIPT-0217` under `native_bridge`.
- Archived Pass 701 from the active cleanup log to keep the doc under cap.

Verification:
- First focused run included a non-existent staging manifest test path and
  exposed a stale retired-lock health expectation; fixed the expectation and
  reran with the correct staging test.
- Focused staging rerun exposed stale manifest helper assertions for retired
  lock expected controls; fixed before continuing.
- Tests-only source audit initially hit a Dart native-assets codesign race while
  another audit was running; reran it alone and it passed.
- Passed targeted Dart format/analyzer and focused native bridge/staging
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 726 - 03:04:16 EDT to active cleanup

Scope:
- Refined Android and iOS native control readiness summaries into core camera
  readiness signals so optional hardware controls do not make limited devices
  look unhealthy.
- Kept optional pinch zoom, brightness slider/reset, and torch diagnostics
  available as separate actual-status fields for admin/device capability
  review.
- Added Android/iOS bridge regressions that reject optional hardware controls
  as readiness-summary blockers.
- Recorded `BUG-RECEIPT-0216` under `native_bridge`.
- Archived Pass 700 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS native UI
  contract regressions.
- First bug-ledger gate failed because `BUG-RECEIPT-0216` used an unknown
  category; reclassified it under allowed `native_bridge` before continuing.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
