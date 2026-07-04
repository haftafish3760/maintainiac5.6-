# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 880 - active cleanup

Scope:
- Hardened focus/readability contract checks so continuous-autofocus readiness
  must carry a matching `continuous_focus` native UI contract tag.
- Added fallback-review contract checks so devices without continuous focus must
  expose the `focus_readability_review` tag when review is required.
- Corrected the native UI ready regression fixture so retired lock controls stay
  disabled while continuous focus is explicitly present.
- Added focused regression coverage for continuous-focus and fallback-review
  contract tag drift.
- Recorded `BUG-RECEIPT-0329` under `native_bridge`.
- Archived Pass 807 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused native UI/focus contract
  regressions, and test source audit.

## Pass 879 - active cleanup

Scope:
- Hardened native UI health outcome priority so any retired-control regression
  becomes the primary camera health outcome before normal ready summaries.
- Covered the lock-only path where focus-lock, exposure-lock, or white-balance
  lock regressions could otherwise stay behind a ready native-control summary.
- Added regression coverage proving lock-only retirement failures become
  attachment risk flags and the main native UI outcome.
- Recorded `BUG-RECEIPT-0328` under `native_bridge`.
- Archived Pass 806 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused retired-control regression, and
  test source audit.

## Pass 878 - active cleanup

Scope:
- Closed the follow-on retired-control gap where native diagnostics could mark
  tap focus or lock controls active without stale contract tags.
- Added active-retired-control regression buckets for tap focus, focus lock,
  exposure lock, and white-balance lock.
- Kept active retired controls out of normal ready/missing control counts while
  still surfacing attachment risk flags.
- Added focused regression coverage for the no-contract-tag path.
- Recorded `BUG-RECEIPT-0327` under `native_bridge`.
- Archived Pass 805 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused native UI health regressions,
  and test source audit.

## Pass 877 - active cleanup

Scope:
- Hardened retired native camera controls so stale tap-focus or lock contract
  tags are treated as product-policy regressions, not missing controls the UI
  should restore.
- Covered the whole retired-control class: tap focus, focus lock, exposure
  lock, and white-balance lock.
- Kept regression signals flowing into native camera UI health outcomes and
  receipt attachment risk flags.
- Added focused native UI contract regression coverage.
- Recorded `BUG-RECEIPT-0326` under `native_bridge`.
- Archived Pass 804 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused native UI health regressions,
  and test source audit.

## Pass 876 - active cleanup

Scope:
- Classified OCR-source section-order handoff signals as their own typed
  evidence family instead of leaving them mixed into generic source signals.
- Exposed section-order signal counts through privacy-safe OCR handoff
  diagnostics so admin/failure reports can see why ordering review is needed.
- Made section-order review-required evidence drive
  `section_order_review_required` and `review_receipt_section_order` handoff
  actions before OCR/parser trust.
- Added a focused OCR-service regression that keeps section-order flags out of
  generic photo-quality risk counts.
- Recorded `BUG-RECEIPT-0325` under `ocr_handoff_contract`.
- Archived Pass 803 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused OCR/capture-flow/section-
  order regressions.

## Pass 875 - 16:32:00 EDT to active cleanup

Scope:
- Carried section-order review evidence into OCR-source attachment contracts
  from both the shared capture flow and attachment-panel paths.
- Added section-order outcome/action document signals and OCR risk flags so
  downstream OCR/admin diagnostics can see exactly why order review is needed.
- Added source-contract and result-level regressions for the new handoff
  signals and risk flags.
- Recorded `BUG-RECEIPT-0324` under `ocr_handoff_contract`.
- Archived Pass 802 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused capture-flow/section-order
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 874 - 16:36:00 EDT to active cleanup

Scope:
- Hardened malformed retake and insert diagnostics that omit required section
  numbers while still carrying operation metadata.
- Added missing-original/final retake buckets and missing-anchor/final insert
  buckets so OCR cannot trust incomplete section-order metadata.
- Added regression coverage for missing retake and insert section numbers.
- Recorded `BUG-RECEIPT-0323` under `multi_photo_ordering`.
- Archived Pass 801 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused section-order/stitch-scanner
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 873 - 16:31:00 EDT to active cleanup

Scope:
- Closed the follow-on section-order handoff gap where invalid order metadata
  could still report a details-ready route.
- Made invalid section ordering return `needs_review_before_ocr`, pause receipt
  details/OCR handoff, and require section-order review before continuing.
- Added regression coverage for route blocking and attachment document signals
  so downstream OCR handoff sees the review-needed state.
- Recorded `BUG-RECEIPT-0322` under `multi_photo_ordering`.
- Archived Pass 800 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused section-order/stitch-scanner
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 872 - 16:26:00 EDT to active cleanup

Scope:
- Hardened receipt section-order diagnostics for long-receipt retakes,
  inserted sections, manual reorder, and normal ghost-guided continuation.
- Added invalid families for retake offsets, context flag mismatches,
  previous/next context gaps, top-retake ghost mismatches, and insert offsets.
- Surfaced privacy-safe section-order review action codes, labels, metadata,
  and handoff counts so OCR cannot silently trust malformed ordering metadata.
- Added regression coverage for invalid retake context, top ghost mismatch,
  insert offset mismatch, and normal long-receipt ghost continuation.
- Recorded `BUG-RECEIPT-0321` under `multi_photo_ordering`.
- Archived Pass 799 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused section-order/stitch-scanner
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 871 - 16:12:00 EDT to active cleanup

Scope:
- Stopped top-section retakes from feeding the next receipt section into the
  native previous-section ghost overlay field.
- Added a previous-section-only retake guide handoff so native top ghost
  overlays are used only when the retake has true previous-section context.
- Kept top-section next-context guidance as review guidance until a real
  next-section overlay exists.
- Added focused retake-order and long-receipt guidance regressions.
- Recorded `BUG-RECEIPT-0320` under `ghost_overlap_stitching`.
- Archived Pass 798 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused retake-order/long-receipt
  guidance regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 870 - 16:09:00 EDT to active cleanup

Scope:
- Forwarded long-receipt retake alignment reason and guidance into the native
  camera session when a user retakes a top, middle, or bottom receipt segment.
- Kept generic coverage guidance as the fallback only when no retake alignment
  context exists.
- Added retake guidance text regressions for top, middle, and bottom segment
  replacement.
- Added long-receipt handoff regressions proving the retake context is wired
  through to native previous-section reason/guidance fields.
- Recorded `BUG-RECEIPT-0319` under `ghost_overlap_stitching`.
- Archived Pass 797 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused retake-order/long-receipt
  guidance regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 868 - 16:04:00 EDT to active cleanup

Scope:
- Classified native camera `lastFocusStatus` diagnostics into health counts for
  configured, unavailable, not-requested, configuration-failed, and stale
  not-used focus states.
- Promoted focus configuration failure and stale `not_used` diagnostics into
  native UI health outcomes so review/admin surfaces cannot silently treat them
  as ready.
- Routed focus configuration failure and stale `not_used` outcomes into
  attachment risk flags for OCR/review handoff.
- Recorded `BUG-RECEIPT-0318` under `native_bridge`.
- Archived Pass 823 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native UI health/ready
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 865 - 12:29:00 EDT to active cleanup

Scope:
- Added an explicit iOS `continuous_focus_not_requested` diagnostic for
  non-continuous focus sessions instead of leaving `lastFocusStatus` as
  `not_used`.
- Pinned the iOS native bridge source regression for configured, unavailable,
  and not-requested focus-status families.
- Recorded `BUG-RECEIPT-0317` under `native_bridge`.
- Archived Pass 822 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused iOS native bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 860 - 12:23:00 EDT to active cleanup

Scope:
- Added focused barcode/QR QA for repeated invalid input paths so warning
  results stay capped while valid receipt images still scan.
- Pinned `skippedInvalidImageCount` and privacy-safe invalid-path warning
  buckets without exposing raw bad path strings.
- Archived Pass 794 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 855 - 12:15:00 EDT to active cleanup

Scope:
- Changed barcode/QR batch scanning so invalid input paths do not consume the
  valid-image decoder limit.
- Added separate privacy-safe input, scanned, invalid, and skipped-invalid
  summary counts for long-receipt scan batches.
- Recorded `BUG-RECEIPT-0316` under `barcode_qr_scanning`.
- Archived Pass 792 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 847 - 12:00:00 EDT to active cleanup

Scope:
- Split ML Kit barcode format mapping out of the barcode scanner service into a
  focused part file.
- Kept the scanner service under the 500-line cap after the coverage-count
  hardening without changing behavior.
- Archived Pass 791 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 841 - 11:51:00 EDT to active cleanup

Scope:
- Added privacy-safe batch barcode/QR summary counts for scanned images,
  warning images, and invalid images.
- Pinned mixed valid/invalid long-receipt barcode inputs so QA/admin diagnostics
  can see scan coverage without exposing raw paths.
- Recorded `BUG-RECEIPT-0315` under `barcode_qr_scanning`.
- Archived Pass 790 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 834 - 11:41:00 EDT to active cleanup

Scope:
- Set Android native camera focus diagnostics from the effective continuous
  focus policy after CameraX bind.
- Pinned configured, unavailable, and not-requested focus-status tokens in the
  Android native bridge regression so review/admin telemetry does not fall back
  to `not_used` after autofocus setup.
- Recorded `BUG-RECEIPT-0314` under `native_bridge`.
- Archived Pass 789 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android native bridge
  analysis/exposure regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 827 - 14:58:00 EDT to active cleanup

Scope:
- Extended review-result barcode handoff QA so OCR-source-first scans also prove
  privacy-safe batch format/type counts.
- Pinned that long-receipt barcode scans keep UPC/QR evidence visible while raw
  code values stay out of summaries.
- Recorded `BUG-RECEIPT-0313` under `qa_harness`.
- Archived Pass 788 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode handoff regression.
- Passed doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and diff
  whitespace gates.

## Pass 826 - 14:51:00 EDT to active cleanup

Scope:
- Added privacy-safe aggregate barcode/QR format and value-type counts to
  multi-image batch scan summaries.
- Pinned batch summaries so admin/QA can see UPC versus QR coverage across long
  receipt segments without raw barcode payloads.
- Recorded `BUG-RECEIPT-0312` under `barcode_qr_scanning`.
- Archived Pass 787 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and diff
  whitespace gates.

## Pass 825 - 14:43:00 EDT to active cleanup

Scope:
- Hardened barcode/QR privacy lookup blocking for compact customer/account
  identifiers that do not use a separator after the sensitive token.
- Added focused barcode scanner regression coverage so customer/account QR text
  cannot become an inventory lookup candidate or leak raw values in summaries.
- Recorded `BUG-RECEIPT-0311` under `barcode_qr_scanning`.
- Archived Pass 786 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and diff
  whitespace gates.

## Pass 824 - 14:01:00 EDT to active cleanup

Scope:
- Carried typed receipt review-depth OCR diagnostics into OCR completion
  telemetry, parser telemetry, privacy-safe receipt events, and Command One
  rollups.
- Exposed review-depth signal/status counts so price-only versus detailed-line
  review mode remains visible without receipt text or item content.
- Added focused telemetry and source-guard regressions for review-depth handoff
  metadata.
- Recorded `BUG-RECEIPT-0310` under `receipt_line_review_mode`.
- Archived Pass 785 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer and focused telemetry/source-guard regressions.
- Passed doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and diff
  whitespace gates.

- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 821 - 13:07:00 EDT to active cleanup

Scope:
- Added a parser-risk parity contract so every saved-photo warning
  `parserRiskCode` must be recognized by OCR source handoff status and
  parser/admin diagnostics.
- The guard prevents future warning families from carrying parser risk in photo
  review while dropping the same risk in OCR-source handoff.
- Recorded `BUG-RECEIPT-0306` under `qa_harness`.
- Archived Pass 814 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted parser-risk parity format/analyzer and focused contract
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 820 - 12:44:00 EDT to active cleanup

Scope:
- Preserved saved-photo parser-risk codes as OCR source risk flags in both
  shared capture-flow and attachment-panel handoff builders.
- Taught OCR source handoff and parser/admin diagnostics to classify the
  parser-risk tokens even if a future path lacks the matching action token.
- Added focused regressions for source builder parity and parser-risk-only
  source handoff classification.
- Recorded `BUG-RECEIPT-0305` under `ocr_handoff_contract`.
- Archived Pass 813 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted parser-risk handoff format/analyzer and focused regressions.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 819 - 12:06:00 EDT to active cleanup

Scope:
- Added a warning-profile parity contract so saved-photo review warning
  profiles must stay wired into OCR handoff `warningProfileStatus` and
  `reviewCueStatus`.
- The contract prevents the shadow-warning drift class from returning when a
  future camera-quality warning family is added.
- Recorded `BUG-RECEIPT-0304` under `qa_harness`.
- Archived Pass 812 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted warning-profile parity format/analyzer and focused contract
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 818 - 11:49:00 EDT to active cleanup

Scope:
- Restored warning-profile parity for saved-photo shadow risk in the OCR source
  handoff summary.
- Added a focused regression proving shadow risk now drives
  `warningProfileStatus`, `reviewCueStatus`, and the privacy-safe contract while
  keeping the existing source-quality review action.
- Recorded `BUG-RECEIPT-0303` under `ocr_handoff_contract`.
- Archived Pass 811 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted OCR source handoff format/analyzer and focused shadow
  warning-profile regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 817 - 11:41:00 EDT to active cleanup

Scope:
- Carried backup scanner and phone-camera fallback risk tokens through the OCR
  source handoff summary.
- Added `backup_capture_review` with a crop/focus/totals review action so
  fallback-source warnings do not collapse back to generic scanner prep.
- Added parser task-count diagnostics for backup scan crop review and phone
  backup focus review.
- Added a focused OCR service regression for the backup capture review family.
- Recorded `BUG-RECEIPT-0302` under `ocr_handoff_contract`.
- Archived Pass 810 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted OCR source handoff format/analyzer and focused backup
  capture review regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 816 - 11:32:00 EDT to active cleanup

Scope:
- Promoted native backup scanner and phone-camera fallback warnings from
  generic review actions into explicit crop/focus review handoff families.
- Kept fallback-only backup capture from becoming the primary accepted warning
  profile while still exposing parser risk and receipt-reader handoff counts.
- Added focused regressions for document-scanner backup crop review and
  phone-camera backup focus review.
- Recorded `BUG-RECEIPT-0301` under `camera_review_state`.
- Archived Pass 809 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted saved-photo warning format/analyzer and focused native
  backup warning handoff regressions.
- Corrected one invalid focused-test command that combined two `--plain-name`
  filters and reran the two focused tests individually.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
