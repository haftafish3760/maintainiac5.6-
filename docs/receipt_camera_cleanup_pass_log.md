# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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
