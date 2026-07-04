# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 658 - 23:20:55 EDT to active cleanup

Scope:
- Added result-level native UI health buckets for
  `readability_guidance_visible` and `readability_guidance_visible_missing`.
- Made missing visible readability guidance a camera UI risk when the native
  policy says live readability guidance is active.
- Extended ready-path and missing-visible regressions so attachment signals,
  risk flags, receipt-reader handoff counts, and metadata keep the evidence.
- Recorded `BUG-RECEIPT-0174` under `camera_capture_quality`.
- Archived Pass 628 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for result-level native UI health files.
- Passed focused Flutter native UI ready/health regressions.

## Pass 657 - 23:19:08 EDT to active cleanup

Scope:
- Added `readability_guidance` to Android and iOS visible-control diagnostics
  when live readability guidance is active.
- Updated native bridge source regressions and the result-level UI-ready fixture
  so admin/review diagnostics can prove the user-facing readability guidance
  surface was present.
- Recorded `BUG-RECEIPT-0173` under `camera_capture_quality`.
- Archived Pass 618 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native bridge UI contract tests.
- Passed focused Flutter Android bridge, iOS bridge, and native UI-ready
  regressions.

## Pass 656 - 23:15:47 EDT to active cleanup

Scope:
- Added an explicit `readability_guidance` native control contract tag for
  capable continuous-focus receipt camera sessions.
- Kept fallback devices on `focus_readability_review` so the app does not
  advertise fake live guidance when native focus support is missing.
- Updated native session, previous-section handoff, and UI-health regressions
  to prove the tag is present only on the capable camera path.
- First focused test run failed because the tag was too broad and the manual UI
  fixture count was stale; fixed both before continuing.
- Recorded `BUG-RECEIPT-0172` under `camera_capture_quality`.
- Archived Pass 617 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native camera session contract files
  and focused helper fixtures.
- Passed focused Flutter native camera session and native UI-ready regressions.

## Pass 655 - 23:08:03 EDT to active cleanup

Scope:
- Hardened native camera UI health outcome priority so missing continuous focus,
  focus policy, live readability guidance, or camera-quality baseline cannot be
  hidden by generic control-readiness gaps.
- Added a focused regression where continuous focus and pinch zoom both fail,
  proving `continuous_focus_missing` remains the top-level camera health result.
- Recorded `BUG-RECEIPT-0171` under `camera_capture_quality`.
- Archived Pass 616 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native UI health helper and
  focused native UI health regression.
- Passed focused Flutter native UI health regressions.

## Pass 654 - 23:06:27 EDT to active cleanup

Scope:
- Hardened native camera UI health outcome priority so stale tap-focus expected
  payloads cannot be hidden by generic missing-control readiness outcomes.
- Added a focused regression where tap focus is expected but missing, proving
  `tap_focus_retirement_regressed` remains the top-level camera health result.
- Recorded `BUG-RECEIPT-0170` under `camera_capture_quality`.
- Archived Pass 615 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native UI health helper and
  focused native UI health regression.
- Passed focused Flutter native UI health regressions.

## Pass 653 - 23:01:54 EDT to active cleanup

Scope:
- Revised `docs/receipt_camera_double_team_handoff.md` so the second model owns
  a true Lane B half of the work: receipt review, OCR/parser handoff contracts,
  line numbering, fixture generation, parser-facing QA, and review truth.
- Kept Lane A focused on native capture, quality/readability, long receipts,
  segment ordering, ghost/overlap, stitching, source preservation, and
  camera-side diagnostics.
- Archived Pass 614 from the active cleanup log to keep the doc under cap.

Verification:
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 652 - 23:00:00 EDT to active cleanup

Scope:
- Added `docs/receipt_camera_double_team_handoff.md` so a second Codex model can
  work on the OCR/review handoff lane without editing native camera or capture
  orchestration files.
- Documented allowed files, forbidden camera-owned files, product invariants,
  test rules, branch setup, and the suggested first safe OCR handoff pass.

Verification:
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 651 - 22:54:25 EDT to active cleanup

Scope:
- Hardened barcode/QR diagnostic summaries so raw warning text cannot leak into
  admin or telemetry-style privacy-safe maps.
- Replaced raw barcode scan warning summaries with whitelisted warning buckets
  and a generic `barcode_scan_warning` fallback.
- Added regression coverage for private barcode warning text.
- Recorded `BUG-RECEIPT-0169` under `barcode_qr_scanning`.
- Archived Pass 613 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the barcode scanner service and
  focused scanner regression.
- Passed focused Flutter barcode scanner regression.

## Pass 650 - 22:51:56 EDT to active cleanup

Scope:
- Hardened the shared ML Kit barcode/QR scanner boundary so privacy-safe
  summaries expose sanitized value-type buckets instead of raw scanner text.
- Made sensitive QR/barcode payload blocking case-insensitive and passed only
  safe value-type buckets into the work-supply barcode bridge.
- Added regressions for uppercase sensitive QR types and malformed value-type
  strings.
- First focused test run failed because `privacySafeSummaryMap` still exposed
  the raw `valueType`; fixed by removing that raw key.
- Recorded `BUG-RECEIPT-0168` under `barcode_qr_scanning`.
- Archived Pass 612 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared scanner and bridge tests.
- Passed focused Flutter barcode scanner and work-supply barcode bridge
  regressions.

## Pass 649 - 22:50:22 EDT to active cleanup

Scope:
- Strengthened native capability parity QA so Android, iOS, and the Dart method
  channel test all prove `supportsContinuousFocus` remains wired.
- Added bridge assertions for Android Camera2 continuous-picture AF capability
  and iOS AVFoundation continuous autofocus capability reporting.
- Archived Pass 611 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native bridge/service parity tests.
- Passed focused Flutter native Android bridge, iOS bridge, and receipt native
  camera service regressions.

## Pass 648 - 22:47:13 EDT to active cleanup

Scope:
- Hardened hardware capability summaries so normal receipt-camera copy exposes
  continuous focus/readability support instead of legacy tap-focus behavior.
- Wired native `supportsContinuousFocus` into the device hardware profile and
  kept tap-focus support as legacy diagnostic evidence only.
- Fixed Android/iOS native auto-capture readability holdback to use helper/set
  membership instead of direct raw-signal equality checks.
- Recorded `BUG-RECEIPT-0166` under `camera_capture_quality` and
  `BUG-RECEIPT-0167` under `native_bridge`.
- Archived Pass 610 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer for capability/profile/privacy tests.
- Passed focused Flutter capability, privacy, native rejection, install
  strategy, and parser-pack regressions.

## Pass 647 - 22:45:26 EDT to active cleanup

Scope:
- Hardened long-receipt stitch-pair state so UI/control changes cannot pass
  negative or overflow pair indexes into manual overlap review.
- Routed pair selection through a clamped helper and repaired negative recovery
  state before overlap arrays are indexed.
- Added focused lifecycle regression coverage for the bounded callback path.
- Recorded `BUG-RECEIPT-0165` under `camera_review_state`.
- Archived Pass 609 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for stitch-pair state and lifecycle
  regression.
- Passed focused Flutter receipt photo review async lifecycle regression.

## Pass 646 - 22:43:38 EDT to active cleanup

Scope:
- Hardened failed receipt-prep cleanup so accepted saved proof, OCR source, and
  stitched OCR artifacts are forgotten from cleanup candidates before review
  closes.
- Reused normalized receipt path identity for the accepted-artifact guard.
- Added focused regression coverage for the cleanup handoff order.
- Recorded `BUG-RECEIPT-0164` under `source_preservation`.

Verification:
- Passed targeted Dart format/analyzer for receipt photo review save/exit
  cleanup and lifecycle regression.
- Passed focused Flutter receipt photo review lifecycle regression.

## Pass 645 - 22:41:22 EDT to active cleanup

Scope:
- Strengthened capture-readiness QA so malformed stable-frame inputs cannot
  make auto-capture wait forever or hide manual capture availability.
- Added regression coverage proving negative stable frames clamp to zero and a
  non-positive required-frame threshold clamps to one.
- Archived Pass 608 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format for capture quality guidance regression.
- Passed focused Flutter capture quality guidance regression.

## Pass 644 - 22:39:28 EDT to active cleanup

Scope:
- Hardened continuation handoff risk flags so result-level receipt attachments
  carry actionable bottom/totals, ghost-guide-ready, missing-prior-photo, and
  bottom-overlap policy signals instead of only a generic continuation review.
- Kept shared capture-flow and attachment-import continuation risk builders
  aligned.
- Added focused regression coverage proving bottom-section continuation risk
  flags survive through attachment creation.
- Recorded `BUG-RECEIPT-0163` under `ghost_overlap_stitching`.
- Archived Pass 607 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format for continuation signal builders and regression.
- Passed focused Flutter continuation handoff regression.

## Pass 643 - 22:37:28 EDT to active cleanup

Scope:
- Hardened manual long-receipt reorder summaries so malformed non-adjacent
  section moves cannot be reported as preserved order.
- Added manual-reorder invalid codes for unknown direction, non-adjacent moves,
  and missing preserved-path evidence.
- Added focused regression coverage proving a bad manual reorder stays
  privacy-safe and becomes a section-order handoff risk.
- Recorded `BUG-RECEIPT-0162` under `multi_photo_ordering`.
- Archived Pass 606 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format for section-order helpers and regressions.
- Passed focused Flutter section-order regression.

## Pass 642 - 22:33:47 EDT to active cleanup

Scope:
- Hardened long-receipt retake section summaries so previous/next alignment
  context section numbers survive into privacy-safe section-order counts and
  receipt-reader handoff counts.
- Split section-order review-result regressions into a focused test file so the
  existing stitch/scanner test returned under the project line-count cap.
- Recorded `BUG-RECEIPT-0161` under `multi_photo_ordering`.
- Archived Pass 605 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format for section-order helper and split tests.
- Passed focused Flutter stitch/scanner and section-order regressions.

## Pass 641 - 22:32:34 EDT to active cleanup

Scope:
- Strengthened Android native bridge source coverage so the UI contract test
  pins `continuousFocusEnabled` argument restore and diagnostics.
- Kept Android coverage aligned with existing iOS continuous-focus diagnostics
  assertions.
- Archived Pass 604 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format for the Android bridge UI contract regression.
- Passed focused Flutter Android bridge UI contract regression.

## Pass 640 - 22:31:30 EDT to active cleanup

Scope:
- Strengthened the healthy native camera UI regression so ready results must
  prove continuous focus, continuous-focus policy, live readability guidance,
  and the receipt camera quality baseline.
- Pinned those positive health codes through receipt-reader handoff counts and
  attachment document signals.
- Archived Pass 603 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format for the positive-path native UI health regression.
- Passed focused Flutter native UI ready regression.

## Pass 639 - 22:29:44 EDT to active cleanup

Scope:
- Hardened native receipt camera handoff risk flags so a tap-focus comeback is
  treated as a risk, not just a counted health-code detail.
- Kept the same risk classification aligned between shared capture flow and
  shared attachment import flows.
- Added a focused regression proving `tap_focus_retirement_regressed` becomes a
  receipt attachment risk flag even when every other native control looks ready.
- Archived Pass 602 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0160` under `camera_capture_quality`.

Verification:
- First focused Flutter run exposed that the fixture had not marked the
  regressed tap-focus control actual state ready; fixed the fixture before
  moving on.
- Passed targeted Dart format for native UI risk flag changes.
- Passed focused Flutter native UI health regression.
