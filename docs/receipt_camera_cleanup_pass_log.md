# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 815 - 12:42:00 EDT to active cleanup

Scope:
- Added a saved-photo shadow warning family for native `shadow_risk` captures.
- Wired shadow risk through review action labels, OCR source review status,
  source-quality action, and parser/admin diagnostics.
- Added focused regressions for saved shadow warning diagnostics and OCR source
  handoff contract.
- Recorded `BUG-RECEIPT-0300` under `camera_capture_quality`.
- Archived Pass 808 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted native warning/handoff format/analyzer and focused shadow
  warning plus handoff regressions.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 814 - 12:34:00 EDT to active cleanup

Scope:
- Surfaced dirty-lens/hazy saved-photo warnings in the receipt review warning
  profile and next-action handoff copy.
- Added result-level regression coverage proving hazy photos keep the
  `saved_photo_dirty_lens_or_haze` profile, wipe-lens action, and parser risk.
- Recorded `BUG-RECEIPT-0299` under `camera_review_state`.
- Archived Pass 782 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted saved-photo warning format/analyzer and focused dirty-lens
  result regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 813 - 12:27:00 EDT to active cleanup

Scope:
- Promoted dirty-lens/hazy saved-photo warnings into a first-class OCR source
  quality review family.
- Added `saved_hazy_lens_review` with `wipe_lens_or_retake` action and parser
  task-count mapping for admin/review diagnostics.
- Added a source handoff regression for dirty lens saved-photo review.
- Recorded `BUG-RECEIPT-0298` under `ocr_handoff_contract`.
- Archived Pass 781 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted handoff/diagnostics format/analyzer and focused dirty-lens
  source handoff regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 812 - 12:20:00 EDT to active cleanup

Scope:
- Added sibling OCR source-quality regressions for generic glare and blur photo
  warning tokens.
- Pinned glare to `saved_glare_review`/`reduce_glare_or_retake` and blur to
  `saved_soft_blur_review`/`retake_hold_steady`, including parser task counts.
- Recorded `BUG-RECEIPT-0297` under `ocr_handoff_contract`.
- Archived Pass 780 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted source-quality format/analyzer and focused glare/blur service
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 811 - 12:14:00 EDT to active cleanup

Scope:
- Hardened derived OCR diagnostics so generic saved photo quality warning tokens
  also feed dark/glare/blur parser task-count review buckets.
- Added focused service coverage proving a too-dark saved receipt surfaces
  `photo_saved_dark_or_exposure_review` for admin/parser diagnostics.
- Recorded `BUG-RECEIPT-0296` under `ocr_handoff_contract`.
- Archived Pass 779 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted OCR diagnostics format/analyzer and focused service
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.

## Pass 810 - 12:08:00 EDT to active cleanup

Scope:
- Hardened OCR source handoff classification for saved photo quality warnings.
- Mapped generic dark/glare/blur `photo_quality_*` warning tokens into the same
  review families as native saved-photo and OCR-source action risks.
- Added a service regression proving a too-dark saved receipt produces
  `saved_dark_exposure_review` and the retake/raise-brightness action.
- Recorded `BUG-RECEIPT-0295` under `ocr_handoff_contract`.
- Archived Pass 778 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted OCR source-quality format/analyzer and focused service
  regression.
- Passed doc-size, bug-ledger, source-audit, test-audit, cleanup-log, and diff
  whitespace gates.
