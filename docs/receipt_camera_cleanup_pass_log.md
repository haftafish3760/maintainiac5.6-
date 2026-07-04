# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 823 - 13:36:37 EDT to active cleanup

Scope:
- Exposed receipt review-depth handoff as typed OCR diagnostics fields:
  `ocrSourceReviewDepthSignalCounts` and `ocrSourceReviewDepthStatus`.
- Kept detailed-line versus price-only receipt review intent available to
  downstream UI, admin diagnostics, and telemetry without forcing callers to
  scrape the privacy-safe contract map.
- Added focused OCR service regression coverage for the typed review-depth
  diagnostics fields.
- Recorded `BUG-RECEIPT-0309` under `receipt_line_review_mode`.
- Archived Pass 784 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused OCR service regression.
- Passed doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and diff
  whitespace gates.

## Pass 822 - 13:18:00 EDT to active cleanup

Scope:
- Classified `receipt_review_depth_*` OCR source document signals into explicit
  handoff counts and a `reviewDepthStatus`.
- Exposed price-only versus detailed-line camera intent in the privacy-safe OCR
  source handoff contract for downstream receipt review/admin diagnostics.
- Added focused OCR service regression coverage for detailed-line review-depth
  handoff.
- Recorded `BUG-RECEIPT-0307` under `receipt_line_review_mode`.
- Fixed a receipt PDF inspector compile failure found by the focused OCR service
  test by routing trailer-name checks through `AppPdfSecurityPolicy`.
- Recorded `BUG-RECEIPT-0308` under `qa_harness`.
- Archived Pass 815 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted review-depth handoff/PDF inspector format/analyzer and
  focused OCR service plus PDF inspector regressions.
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

## Pass 807 - 10:24:00 EDT to active cleanup

Scope:
- Hardened barcode/QR batch scanning so duplicate receipt image paths are
  skipped before decoder/ML Kit work.
- Added a privacy-safe duplicate-image batch warning bucket.
- Added a regression proving duplicate long-receipt image paths do not trigger
  duplicate barcode scans.
- Recorded `BUG-RECEIPT-0291` under `barcode_qr_scanning`.
- Archived Pass 775 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 806 - 10:16:00 EDT to active cleanup

Scope:
- Treated native camera `review_required` health tokens as actionable
  attachment risk flags.
- Applied the same risk classification to shared capture-flow and
  attachment-panel native camera signal helpers.
- Added regressions proving focus/readability fallback review reaches receipt
  attachment risk flags and the duplicated helper paths stay aligned.
- Recorded `BUG-RECEIPT-0290` under `native_bridge`.
- Archived Pass 774 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native UI handoff
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 805 - 10:05:51 EDT to active cleanup

Scope:
- Added an explicit native camera `focusReadabilityFallbackPolicy` so devices
  without continuous focus declare whether live or saved-photo readability
  review is required.
- Surfaced the policy through native session arguments, control diagnostics,
  and photo-review native UI health counts.
- Added regressions for session policy, service handoff, and review health
  aggregation.
- Recorded `BUG-RECEIPT-0289` under `native_bridge`.
- Archived Pass 773 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native camera regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 804 - 09:39:00 EDT to active cleanup

Scope:
- Fixed manual Add Photo continuation so a valid previous receipt section can
  activate the ghost overlay even when no OCR-specific reason code exists yet.
- Added the safe default `manual_add_photo_continuation` reason while keeping
  no-photo/no-reason continuation inactive.
- Updated continuation guide regressions for manual Add Photo ghost behavior.
- Recorded `BUG-RECEIPT-0288` under `ghost_overlap_stitching`.
- Archived Pass 772 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused capture-flow shareability
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 803 - 09:31:00 EDT to active cleanup

Scope:
- Added explicit price-only versus detailed-line review mode fields to the
  pre-save assisted receipt line privacy-safe contract.
- Added business-use label parity so draft contracts match saved receipt line
  review contracts more closely.
- Added source regressions for draft review-mode and business-use labels.
- Recorded `BUG-RECEIPT-0287` under `receipt_line_review_mode`.
- Archived Pass 771 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused assisted-review source
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 802 - 09:22:00 EDT to active cleanup

Scope:
- Added a pre-save privacy-safe receipt line review contract to the assisted
  receipt entry draft line model.
- Kept draft price-only versus detailed-line decisions aligned with saved
  receipt line records.
- Added safe OCR source line and section-line anchors for pre-save review and
  customer proof/redaction tooling.
- Added source regressions so draft contracts use sanitized line numbers and
  do not expose raw section-line input directly.
- Recorded `BUG-RECEIPT-0286` under `receipt_line_numbering`.
- Archived Pass 770 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused assisted-review source
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 801 - 09:14:00 EDT to active cleanup

Scope:
- Hardened privacy-safe receipt line review contracts so long-receipt lines
  expose both OCR source line number and OCR source section line number.
- Preserved price-only and detailed-line review modes while giving customer
  proof/redaction tooling enough numbered line anchors for long receipts.
- Added regressions for simple line numbers, section line numbers, malformed
  line-number exclusion, and capped huge source row numbers.
- Recorded `BUG-RECEIPT-0285` under `receipt_line_numbering`.
- Archived Pass 769 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused receipt line record
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 800 - 09:07:30 EDT to active cleanup

Scope:
- Renamed unreadable OCR source-prep cleanup actions that implied the original
  image was used after a missing file or decode failure.
- Kept stable failure decision codes while changing cleanup action labels to
  no-clear-OCR-source wording.
- Added unreadable-source regressions rejecting the old `_original_used`
  action family.
- Recorded `BUG-RECEIPT-0284` under `source_preservation`.
- Archived Pass 768 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused OCR source-guard
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 799 - 09:03:30 EDT to active cleanup

Scope:
- Renamed scanner decision codes and cleanup actions that described temporary
  full-quality source selection as original-source preservation.
- Updated receipt handoff count names, telemetry fixtures, and OCR-source risk
  assertions to the new temporary full-quality source guard token.
- Preserved explicit original-quality wording only for user-selected
  original-proof storage and immutable proof-record metadata.
- Added regressions against the stale scanner decision and cleanup action names.
- Recorded `BUG-RECEIPT-0283` under `source_preservation`.

Verification:
- Passed targeted Dart format/analyzer and focused source-prep, stitch-scanner,
  telemetry, and OCR-source quality regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 798 - 09:00:00 EDT to active cleanup

Scope:
- Renamed stale OCR source policy guard tokens away from
  original-quality wording to temporary full-quality source wording.
- Kept explicit original-quality proof wording only for user-selected
  original proof retention.
- Updated shared flow and attachment risk flags to use the new temporary source
  guard token.
- Added scanner-prep regression assertions that reject the old internal guard
  wording.
- Recorded `BUG-RECEIPT-0282` under `source_preservation`.

Verification:
- Passed targeted Dart format/analyzer and focused stitch-scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 797 - 08:52:23 EDT to active cleanup

Scope:
- Hardened the shared ML Kit barcode/QR scanner boundary so only local absolute
  image paths can reach the decoder.
- Blocked relative paths, URLs, PDFs/text files, whitespace-padded paths, and
  NUL-tainted paths before ML Kit invocation.
- Added barcode scanner path-family regressions.
- Recorded `BUG-RECEIPT-0281` under `barcode_qr_scanning`.
- Archived Pass 767 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 794 - 08:46:29 EDT to active cleanup

Scope:
- Fixed native capture staging fixtures that still reported retired tap-focus
  activity.
- Reset tap-focus and suppressed-after-zoom counts to zero and changed focus
  status to continuous-focus evidence.
- Updated staging manifest, signal, and recovery-index expectations.
- Recorded `BUG-RECEIPT-0280` under `qa_harness`.
- Archived Pass 766 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native staging regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 792 - 08:12:44 EDT to active cleanup

Scope:
- Completed the OCR source-first token rename by replacing the remaining
  `original_source_ready` outcome/status references.
- Updated continuation action copy routing to use `temporary_full_quality_ready`.
- Added source regressions rejecting the old outcome token.
- Recorded `BUG-RECEIPT-0279` under `source_preservation`.
- Archived Pass 765 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused handoff source regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 791 - 08:09:17 EDT to active cleanup

Scope:
- Renamed OCR source-first handoff/status tokens from original-source wording
  to temporary full-quality source wording.
- Updated decision, relationship, review-status, and continuation source labels
  while keeping user-facing review copy unchanged.
- Added a source regression rejecting the stale original-source decision token.
- Recorded `BUG-RECEIPT-0278` under `source_preservation`.
- Archived Pass 764 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused handoff source regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

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
