# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 685 - 00:39:25 EDT to active cleanup

Scope:
- Hardened the real-device receipt QA script so testing cannot be treated as
  Samsung-plus-iPhone-only.
- Added a non-Samsung Android target and a lighting/interruption matrix covering
  bright, dim, glare, shadow, wrinkled receipt, app switch, lock screen, and
  low-storage/storage-saver conditions.
- Added a contract test that pins the real-device QA matrix.
- Archived Pass 658 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0201` under `qa_harness`.

Verification:
- Passed targeted Dart format/analyzer for the real-device script contract.
- Passed focused Flutter real-device script contract regression.

## Pass 684 - 00:36:27 EDT to active cleanup

Scope:
- Hardened long-receipt stitch input validation so normalized aliases of the
  same receipt section cannot be treated as separate stitch inputs.
- Reused the shared receipt photo path identity guard for stitch duplicate
  detection, aligning stitching with retake/order path safety.
- Added a stitching regression for duplicate input aliases that include
  normalized path traversal.
- Archived Pass 657 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0200` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for stitch processor files.
- Passed focused Flutter receipt stitching regressions.

## Pass 683 - 00:34:45 EDT to active cleanup

Scope:
- Hardened continuation ghost-guide source selection so malformed latest
  previous-photo paths cannot become the guide image.
- Reused the receipt photo path identity guard and fall back to the latest valid
  previous section when continuation paths include unnormalized entries.
- Added a continuation handoff regression for malformed latest guide paths.
- Archived Pass 656 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0199` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for capture-flow continuation files.
- Passed focused Flutter continuation handoff regressions.

## Pass 682 - 00:33:07 EDT to active cleanup

Scope:
- Fixed multi-photo retake diagnostics when one old middle receipt section is
  replaced by multiple new photos.
- Shifted the safe next-context section number to match the final receipt order
  after extra replacement sections are inserted.
- Strengthened retake-order regressions so both replacement photos preserve the
  correct previous/next alignment context without leaking paths.
- Archived Pass 655 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0198` under `multi_photo_ordering`.

Verification:
- Passed targeted Dart format/analyzer for retake order files.
- Passed focused Flutter receipt photo retake/order regressions.

## Pass 681 - 00:30:56 EDT to active cleanup

Scope:
- Hardened receipt selected-line local maps so source-section labels are bounded
  before they enter job proof, export, or debug-style bridge artifacts.
- Preserved raw source-section labels on the original receipt line draft while
  keeping derived selection references privacy-safe.
- Added regressions for single-line and multi-receipt selection bundles so
  private merchant/job section text cannot leak through local selection maps.
- Archived Pass 654 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0197` under `source_preservation`.

Verification:
- Passed targeted Dart format/analyzer for receipt selection contract files.
- Passed focused Flutter receipt line model and selection-bundle regressions.

## Pass 680 - 00:29:25 EDT to active cleanup

Scope:
- Removed active very-soft receipt review guidance that told users to use
  focus assist after the camera moved to continuous autofocus/readability
  coaching.
- Replaced it with hold-steady, refocus, move-closer, or retake guidance.
- Tightened the photo-quality guidance regression so active review copy cannot
  reintroduce focus-assist wording.
- Archived Passes 652 and 653 from the active cleanup log to keep the doc
  under cap.
- Recorded `BUG-RECEIPT-0196` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for photo-quality guidance files.
- Passed focused Flutter receipt camera quality guidance regression.

## Pass 679 - 00:28:07 EDT to active cleanup

Scope:
- Removed stale tap-focus, focus-lock, auto-exposure-lock, and white-balance
  lock language from the active native camera service spec.
- Replaced pro-camera control wording with continuous autofocus, readability
  guidance, auto exposure/brightness assist, and device-safe diagnostics.
- Extended the active camera docs regression so current camera docs cannot
  reintroduce tap focus or focus/exposure/white-balance lock controls.
- Archived Pass 651 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0195` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for the active camera doc regression.
- Passed focused Flutter active camera docs focus-policy regression.

## Pass 678 - 00:21:28 EDT to active cleanup

Scope:
- Removed stale focus-lock, exposure-lock, and white-balance-lock settings from
  the receipt native camera descriptor contract after tap focus was retired.
- Stopped treating retired lock controls as missing required native capability
  policy codes in previous-section channel diagnostics.
- Kept receipt readability guidance visible in the native control contract even
  when live analysis is reduced to saved-photo review.
- Updated current staging and recovery fixtures so tap-focus counts stay zero,
  last focus status is `not_used`, and lock-control expectations remain false.
- Archived Pass 650 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0194` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native camera settings policy,
  session config, descriptors, UI health tests, and staging expectations.
- Passed focused Flutter native camera contract, native UI ready, staging,
  recovery index, and previous-section channel regressions.

## Pass 677 - 00:18:55 EDT to active cleanup

Scope:
- Added an explicit native tap-focus gesture retirement diagnostic for Android
  and iOS receipt camera captures.
- Routed `nativeTapFocusGesturePolicy` through the privacy-safe native staging
  allowlist and shared native UI health counts.
- Added `tap_focus_gesture_removed` result evidence so admin/debug handoffs can
  prove tap focus was removed instead of inferring it from missing controls.
- Removed the dead Android `lastSinglePointerUpAt` field left after tap-focus
  gesture removal.
- Archived Pass 649 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0193` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native tap-focus retirement
  diagnostics.
- Passed focused Flutter native source and result-health regressions.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 676 - 00:14:51 EDT to active cleanup

Scope:
- Removed active tap-focus gesture plumbing from native Android and iOS receipt
  camera controls after tap focus was retired from the product contract.
- Kept continuous focus, pinch zoom, exposure assist, brightness controls, and
  readability guidance intact.
- Removed obsolete tap-after-zoom suppression timers and tap-driven focus lock
  copy from native source.
- Updated native bridge tests to reject tap-focus gesture, metering, and lock
  code paths while preserving legacy diagnostic counters as zero-state evidence.
- Archived Pass 648 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0192` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native bridge focus tests.
- Passed focused Flutter Android/iOS native bridge source regressions.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 675 - 00:04:40 EDT to active cleanup

Scope:
- Hardened the receipt QA runner so barcode/QR fixture expectations are scored
  as behavior checks instead of manifest-only fields.
- Added synthetic scanner input codes and privacy-safe scanner summary scoring
  for code count, QR count, inventory lookup candidates, format buckets, and
  warning buckets.
- Extended the external fixture schema with scanner input code fields and
  pinned scanner checks in the QA runner contract.
- Fixed an overbroad contractor-supply assertion so receipts without barcodes
  are not forced to emit scanner checks.
- Archived Passes 646 and 647 from the active cleanup log to keep the doc under
  cap.
- Recorded `BUG-RECEIPT-0191` under `fixture_generation`.

Verification:
- Passed targeted Dart format/analyzer for scanner fixture scoring files.
- Passed focused Flutter receipt QA runner contract regression.
- Fixed the cleanup-log gate failure by archiving one more old active pass.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 674 - 23:58:31 EDT to active cleanup

Scope:
- Hardened receipt QA fixture contracts so external fixture packs can express
  privacy-safe barcode/QR scanner expectations.
- Added scanner expected count/bucket fields to the fixture model, required
  field coverage, and external JSON schema.
- Pinned scanner fixture readiness through the QA runner contract test and a
  contractor-supply synthetic fixture.
- Archived Pass 645 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0190` under `fixture_generation`.

Verification:
- Passed targeted Dart format/analyzer for fixture scanner contract files.
- Passed focused Flutter receipt QA runner contract regression.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 673 - 23:53:16 EDT to active cleanup

Scope:
- Hardened the receipt QA fixture manifest so external fixture readiness tracks
  camera photo-quality expectations, not only parser expected fields.
- Extended the external fixture schema with `photoQuality` source inputs and
  expected blur/glare/retake/review guidance fields.
- Pinned the schema/manifest contract through the pure Dart receipt QA runner
  contract test.
- Archived Pass 644 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0189` under `fixture_generation`.

Verification:
- Passed targeted Dart format/analyzer for fixture manifest/schema contract
  files.
- Passed focused Flutter receipt QA runner contract regression.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 672 - 23:52:05 EDT to active cleanup

Scope:
- Hardened the receipt bug regression ledger gate so duplicate bug IDs fail the
  QA harness instead of passing silently.
- Repaired an existing duplicated `BUG-RECEIPT-0170` row by assigning the
  camera tap-focus priority regression a unique ID.
- Added `BUG-RECEIPT-0188` under `qa_harness` to track the gate hardening.
- Archived Pass 643 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the ledger gate.
- Passed the receipt bug regression ledger gate and a duplicate-ID scan.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.

## Pass 671 - 23:50:35 EDT to active cleanup

Scope:
- Hardened customer/client proof visibility counts so duplicate OCR stable line
  IDs cannot inflate review or redaction totals.
- Routed proof visibility counts through the first-occurrence line draft map to
  match the actionable customer-proof line-ID lists.
- Added parser handoff regression coverage and reran receipt privacy/proof
  processing tests.
- Archived Passes 641 and 642 from the active cleanup log to keep the doc under
  cap.
- Recorded `BUG-RECEIPT-0186` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format/analyzer for parser proof handoff maps.
- Passed focused Flutter parser handoff, privacy event, and receipt processing
  regressions.
- Fixed the first cleanup-log gate run by archiving one more old active pass.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 670 - 23:49:11 EDT to active cleanup

Scope:
- Hardened OCR parser handoff source-section maps so duplicate stable line IDs
  cannot appear under multiple receipt sections.
- Kept first-seen section assignment for consumer-facing line maps and aligned
  item source-section counts to those visible line IDs.
- Added duplicate-line regression coverage plus focused long-receipt
  source-section continuity checks.
- Archived Pass 640 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0185` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format/analyzer for parser source-section maps.
- Passed focused Flutter parser handoff, read-warning, and totals coverage
  regressions.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 669 - 23:47:36 EDT to active cleanup

Scope:
- Hardened OCR parser handoff role maps so duplicate OCR stable line IDs do
  not appear twice in `lineIdsByRole` or the privacy-safe parser contract.
- Preserved raw ordered line IDs for audit while keeping consumer-facing role
  groups first-occurrence deduped.
- Added focused regression coverage to the existing duplicate line-ID parser
  handoff test.
- Archived Pass 639 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0184` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format/analyzer for parser handoff line maps.
- Passed focused Flutter parser handoff structure regression.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 668 - 23:50:00 EDT to active cleanup

Scope:
- Hardened shared Google ML Kit barcode/QR scanner results so oversized QR
  payloads cannot become inventory lookup candidates.
- Added a bounded inventory lookup length and privacy-safe
  `lookupValueTooLong` evidence without exposing the QR payload.
- Added scanner and work-supply bridge regressions proving giant QR payloads
  are ignored while normal UPC/EAN/package codes still flow.
- Archived Pass 638 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0183` under `barcode_qr_scanning`.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner and bridge tests.
- Passed focused Flutter barcode scanner and work-supply bridge regressions.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 667 - 23:47:00 EDT to active cleanup

Scope:
- Removed stale Android and iOS settings copy that still told receipt camera
  users to use focus assist after tap focus had been retired.
- Replaced it with release-one camera guidance: hold steady for continuous
  focus, move closer, reduce glare, use Brightness, and pinch to zoom.
- Added Android and iOS bridge regressions proving the retired focus-assist
  phrase does not return.
- Archived Pass 637 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0182` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native bridge settings tests.
- Passed focused Flutter Android/iOS native settings bridge regressions.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 666 - 23:44:00 EDT to active cleanup

Scope:
- Hardened native camera session contracts so retired tap-focus controls do not
  reappear as expected focus, exposure, or white-balance lock controls.
- Preserved the intended release-one camera behavior: continuous focus,
  brightness assist, and readability guidance are the primary receipt capture
  path.
- Updated capable-phone session regressions to prove lock controls remain off
  even when the hardware supports them.
- Archived Pass 636 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0181` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for native camera session contracts.
- Passed focused Flutter native camera session contract regression.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 665 - 23:38:21 EDT to active cleanup

Scope:
- Hardened receipt-details review handoff metadata so price-only versus
  detailed-line intent is exposed as product-level receipt review evidence,
  not only as native camera bridge diagnostics.
- Added explicit `receiptDetailsReviewIntent` and
  `receiptDetailsLineReviewMode` fields for downstream OCR/parser/review
  contracts.
- Added focused regressions for both detailed-line and price-only receipt
  handoff metadata.
- Archived Pass 635 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0180` under `receipt_line_review_mode`.

Verification:
- Passed targeted Dart format/analyzer for receipt review handoff metadata.
- Passed focused Flutter receipt metadata regression.
- Passed cleanup log gate, doc-size gate, bug ledger gate, source audit, and
  whitespace check.

## Pass 664 - 23:35:31 EDT to active cleanup

Scope:
- Hardened admin OCR-failure diagnostics so camera-source quality failures can
  carry safe quality buckets such as `saved_glare_review` without receipt text,
  paths, or raw target hints.
- Compactly encoded admin diagnostic evidence to stay inside the existing
  telemetry token-length cap instead of weakening the sanitizer.
- Added regressions proving glare quality evidence survives sanitization while
  private receipt/store/total hints are still bucketed away.
- Archived Pass 634 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0179` under `privacy_redaction`.

Verification:
- Fixed the first focused run by shortening the safe admin evidence token
  instead of increasing telemetry token limits.
- Passed targeted Dart format/analyzer for OCR failure/admin diagnostics.
- Passed focused Flutter OCR-failure and admin diagnostic contract tests.

## Pass 663 - 23:32:03 EDT to active cleanup

Scope:
- Hardened camera-source glare handoff so washed-out/glare receipt photos
  produce explicit parser-review task evidence.
- Routed `photo_saved_glare_review` through expense OCR cause codes, failure
  stage labeling, and photo-quality action guidance.
- Added focused regressions proving glare saved-photo risk reaches OCR
  diagnostics and the expense parser failure bridge.
- Archived Pass 633 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0178` under `ocr_handoff_contract`.

Verification:
- Fixed a stale test assertion that looked for parser task counts on the
  OCR-source handoff contract instead of `diagnostics.parserTaskCounts`.
- Passed targeted Dart format/analyzer for OCR diagnostics and expense bridge
  changes.
- Passed focused Flutter OCR-service and expense OCR-handoff regressions.

## Pass 662 - 23:30:17 EDT to active cleanup

Scope:
- Added focused QA coverage for long-receipt section-order path safety.
- Pinned insert-after, remove, move, and moved-photo diagnostics against
  normalized path aliases that could otherwise confuse section identity.
- Archived Pass 632 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the new path-safety regression.
- Passed focused Flutter order path-safety regression.

## Pass 661 - 23:26:34 EDT to active cleanup

Scope:
- Hardened long-receipt continuation handoff summaries so a requested and ready
  previous-section ghost guide that is not visible becomes explicit
  `ghost_guide_visible_missing` evidence.
- Added OCR-source risk flags for hidden/missing ghost-guide UI in both shared
  capture-flow and attachment-panel handoff paths.
- Added focused regression coverage proving a ready ghost guide cannot silently
  look healthy when native UI diagnostics say it was not shown.
- Repaired the bug-ledger gate taxonomy so existing barcode/QR and camera
  review-state regression rows validate instead of failing the quality gate.
- Archived Pass 631 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0176` under `ghost_overlap_stitching` and
  `BUG-RECEIPT-0177` under `qa_harness`.

Verification:
- Passed targeted Dart format/analyzer for continuation handoff files.
- Passed focused Flutter continuation handoff regression.

## Pass 660 - 23:24:40 EDT to active cleanup

Scope:
- Updated Android/iOS source regressions so auto-capture quality-review holdback
  requires helper/set membership for readability signals instead of direct
  `latestReadabilitySignal == ...` checks.
- Added negative assertions against direct shadow/haze equality checks so future
  native edits keep the more maintainable signal-set contract.
- Archived Pass 630 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS native auto-capture
  source-contract tests.
- Passed focused Flutter Android auto-capture and iOS settings/close tests.

## Pass 659 - 23:23:30 EDT to active cleanup

Scope:
- Tightened Android/iOS visible-control diagnostics so `readability_guidance`
  appears only when continuous focus is also enabled.
- Tightened result-level visible-readability health buckets so fallback camera
  sessions with missing continuous focus do not claim live readability UI proof.
- Added focused regression coverage for fallback readability-visible behavior.
- Recorded `BUG-RECEIPT-0175` under `camera_capture_quality`.
- Archived Pass 629 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native bridge/result health tests.
- Passed focused Flutter Android bridge, iOS bridge, native UI ready/health, and
  readability-visible health regressions.
