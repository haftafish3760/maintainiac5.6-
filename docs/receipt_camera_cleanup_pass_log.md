# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 619 - 21:44:42 EDT to active cleanup

Scope:
- Added privacy-safe stitch fallback reason metadata for receipt-reader handoff
  diagnostics.
- Added failed adjacent section numbers for fallback stitch pairs so admin
  review can identify the problem pair without receipt photo paths.
- Added a new focused regression file instead of growing the oversized stitch
  scanner test file.
- Recorded `BUG-RECEIPT-0140` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for stitch fallback metadata.
- Passed focused Flutter stitch fallback metadata regression.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 620 - 21:47:12 EDT to active cleanup

Scope:
- Added an explicit privacy-safe OCR/proof relationship code for receipt
  handoff summaries.
- Distinguished same accepted-source reuse from saved-proof OCR fallback risk
  so admin QA and downstream review code do not have to infer from paths.
- Added focused regressions for same-source, fallback, and separate clear-source
  OCR handoff classifications.
- Archived Pass 595 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0141` under `ocr_handoff_contract`.

Verification:
- Passed targeted Dart format/analyzer for OCR source relationship handoff.
- Passed focused Flutter OCR source relationship regression.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 621 - 21:50:00 EDT to active cleanup

Scope:
- Removed stale `tapFocusCoordinateSpace` metadata from Android and iOS native
  receipt camera diagnostics.
- Replaced it with `readabilityGuidanceCoordinateSpace` so QA/admin handoff
  evidence matches the continuous-focus/readability camera strategy.
- Updated the native staging safe-key allowlist and fixture metadata.
- Added negative source-contract regressions so tap-focus coordinate metadata
  cannot return quietly.
- Recorded `BUG-RECEIPT-0142` under `camera_capture_quality`.

Verification:
- Passed targeted Dart analyzer for native diagnostic safe-key and fixture
  updates.
- Passed focused Android and iOS native source-contract regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 622 - 21:51:22 EDT to active cleanup

Scope:
- Replaced active tap-focus camera docs with continuous autofocus/readability
  guidance.
- Added a doc regression rejecting tap-focus-first wording in active receipt
  camera docs.
- Recorded `BUG-RECEIPT-0143` under `camera_capture_quality`.

Verification:
- Passed targeted Dart analyzer and focused active-doc focus-policy regression.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 623 - 21:52:39 EDT to active cleanup

Scope:
- Corrected native helper expectations so retired tap focus is not expected in
  previous-section or staging diagnostics.
- Archived Pass 596 from the active cleanup log.
- Recorded `BUG-RECEIPT-0144` under `camera_capture_quality`.

Verification:
- Fixed stale helper assertions exposed by the first focused test run.
- Passed targeted analyzer and focused previous-section/staging regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 624 - 21:56:17 EDT to active cleanup

Scope:
- Added continuous-focus expected counts to expense receipt telemetry and the
  native camera Command Center map.
- Updated telemetry fixtures so retired tap focus reports 0 while continuous
  focus reports 1.
- Archived Pass 597 from the active cleanup log.
- Recorded `BUG-RECEIPT-0145` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused expense telemetry regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 625 - 21:58:40 EDT to active cleanup

Scope:
- Removed the legacy `focus_assist` alias from native UI health tap-focus
  checks.
- Added a source-contract regression rejecting that alias.
- Archived Pass 598 from the active cleanup log.
- Recorded `BUG-RECEIPT-0146` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused native UI health regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 626 - 22:01:05 EDT to active cleanup

Scope:
- Renamed retired tap-focus telemetry counters to legacy tap-focus counters.
- Added regressions rejecting the old active tap-focus telemetry key names.
- Recorded `BUG-RECEIPT-0147` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused telemetry/source regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 627 - 22:02:52 EDT to active cleanup

Scope:
- Renamed the retired tap-focus enabled telemetry counter to
  `legacyTapFocusEnabledCount`.
- Added a source regression rejecting the old active key name.
- Archived Pass 599 from the active cleanup log.
- Recorded `BUG-RECEIPT-0148` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused OCR-source handoff source regression.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 628 - 22:04:55 EDT to active cleanup

Scope:
- Removed the public `onTapFocus` callback hook from the shared native receipt
  camera shell and preview controls.
- Added a source regression proving the tap-focus shell hook stays absent.
- Archived Pass 600 from the active cleanup log.
- Recorded `BUG-RECEIPT-0149` under `camera_capture_quality`.

Verification:
- Passed targeted analyzer and focused native shell/session regressions.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 618 - 21:42:32 EDT to active cleanup

Scope:
- Hardened long-receipt retake diagnostics so replacement photos include
  privacy-safe previous/next alignment section numbers.
- Preserved the existing no-paths diagnostic rule while making middle, top, and
  bottom retake context easier to audit downstream.
- Added focused regression coverage for middle, top, and bottom retake
  alignment context numbers.
- Recorded `BUG-RECEIPT-0139` under `multi_photo_ordering`.

Verification:
- Passed targeted Dart format/analyzer for retake-order planning.
- Passed focused Flutter receipt photo retake/order regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 617 - 21:39:59 EDT to active cleanup

Scope:
- Hardened native Android and iOS optional auto capture so shadow-risk or
  dirty-lens/haze readability guidance holds auto capture back.
- Added native `waiting_for_quality_review` status and mapped it to
  `manual_only_quality_review` diagnostics on both platforms.
- Kept manual capture available while preventing automatic capture from firing
  on frames that need user review.
- Added Android and iOS source-contract regressions for the new holdback.
- Recorded `BUG-RECEIPT-0138` under `camera_capture_quality`.

Verification:
- Passed targeted Dart analyzer for native auto-capture source-contract tests.
- Passed focused Flutter Android/iOS native auto-capture/settings regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 616 - 21:37:36 EDT to active cleanup

Scope:
- Carried `manual_only_quality_review` into receipt review copy so users see
  sharpness, light, and receipt-text guidance instead of a silent unknown state.
- Extended native camera result diagnostics so the new readiness state appears
  in health counts, receipt-reader handoff counts, and held-back auto-capture
  evidence.
- Added focused handoff regressions for the source copy and result-level
  diagnostics.
- Recorded `BUG-RECEIPT-0137` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for review copy and diagnostics tests.
- Passed focused Flutter quality handoff and native quality regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 615 - 21:35:42 EDT to active cleanup

Scope:
- Hardened capture readiness so optional auto capture cannot fire just because
  the frame is stable when the photo quality still needs manual review.
- Added `manual_only_quality_review` for soft focus, low contrast, dim
  readable frames, and other noncritical review-needed receipt photos.
- Kept manual shutter available in those cases so the user remains in control.
- Added regression coverage for soft, low-contrast, and dim review-needed
  receipt photos.
- Recorded `BUG-RECEIPT-0136` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for receipt photo quality readiness.
- Passed focused Flutter receipt camera quality guidance regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 614 - 21:33:08 EDT to active cleanup

Scope:
- Removed remaining active product-doc wording that described tap-focus as part
  of the expected receipt camera flow.
- Replaced those docs with continuous autofocus, readability guidance,
  brightness/glare checks, and sharpness-focused real-device expectations.
- Updated Command Center soft-blur recovery action copy so it tells reviewers
  to trust continuous focus/readable text, not ask users to tap receipt text.
- Added focused telemetry regression coverage proving soft-blur guidance keeps
  continuous focus primary and rejects tap-focus wording.
- Recorded `BUG-RECEIPT-0135` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for telemetry soft-blur recovery copy.
- Passed focused Flutter telemetry photo-recovery action regressions.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 613 - 21:27:56 EDT to active cleanup

Scope:
- Extended the permanent receipt QA fixture contract so damaged receipt sources
  can assert light labels, focus/sharpness labels, warning text, and review
  guidance text instead of only action gates.
- Added blur, glare, cropped-edge, and low-contrast fixture expectations that
  keep receipt-photo guidance centered on readable text, brightness/glare, and
  sharpness.
- Added regression coverage requiring the QA runner to expose those checks.
- Recorded `BUG-RECEIPT-0134` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for the receipt QA runner, damaged
  fixtures, and runner contract test.
- Passed focused Flutter receipt QA runner contract regressions.
- Passed damaged OCR fixture runner at 108/108 checks.
- Passed cleanup log, doc size, source audit, and diff whitespace gates.

## Pass 612 - 21:23:12 EDT to active cleanup

Scope:
- Hardened receipt layout line numbering so malformed zero or negative line
  numbers clamp before stable line IDs, proof redaction anchors, parser line
  lists, and client-proof default visible line lists use them.
- Filtered invalid requested redaction line numbers out of generated
  client-proof redaction plans.
- Added regression coverage for malformed layout lines and privacy-safe proof
  anchors.
- Recorded `BUG-RECEIPT-0133` under `receipt_line_numbering`.
- Archived Pass 589 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for receipt layout intelligence and
  direct parser parity regressions.
- Passed focused Flutter direct parser parity regression coverage.

## Pass 611 - 21:21:50 EDT to active cleanup

Scope:
- Hardened receipt line review allocation so padded business-use values and
  unsafe split percentages normalize before labels, proof references, and
  client-proof line selections use them.
- Added privacy-safe business/personal percentage fields to selected line
  references for later proof/redaction workflows.
- Added regression coverage for padded split/personal values, overrange split
  percentages, and non-finite split percentages.
- Recorded `BUG-RECEIPT-0132` under `business_personal_split`.

Verification:
- Passed targeted Dart format/analyzer for receipt line models, receipt
  processing contracts, and focused line-model regressions.
- Passed focused Flutter receipt line model regressions.

## Pass 610 - 21:20:25 EDT to active cleanup

Scope:
- Hardened OCR source handoff so marginal saved-photo lighting warnings
  (`brightness_assist_still_dim` and `dimmer_than_preview`) count as
  dark/exposure review risks instead of looking ready for OCR.
- Mirrored the same dim-light risk family into OCR diagnostic warning buckets.
- Added regression coverage proving dimmer receipt-photo handoff contracts now
  report `saved_dark_exposure_review` and the matching review action.
- Recorded `BUG-RECEIPT-0131` under `ocr_handoff_contract`.

Verification:
- Passed targeted Dart format/analyzer for OCR source handoff review,
  diagnostics helpers, and OCR service regressions.
- Passed focused Flutter OCR service and OCR source-quality regressions.

## Pass 609 - 21:18:35 EDT to active cleanup

Scope:
- Hardened Flutter receipt capture evidence so saved-photo brightness buckets
  use the same `captured_*` vocabulary as native Android/iOS diagnostics.
- Fixed preview-parity warning precedence so direct saved-photo glare evidence
  surfaces as glare guidance instead of a generic brighter-than-preview warning.
- Added regression coverage proving dark and glare saved photos from shared
  capture evidence create the correct review warnings.
- Recorded `BUG-RECEIPT-0130` under `camera_capture_quality`.

Verification:
- Passed targeted Dart format/analyzer for receipt capture diagnostics, saved
  photo warnings, and focused regression tests.
- Passed focused Flutter regressions for best-shot capture diagnostics,
  saved-photo warning diagnostics, and native quality handoff.

## Pass 608 - 21:15:24 EDT to active cleanup

Scope:
- Retired tap-to-focus from the user-facing native receipt camera settings so
  continuous autofocus and readability guidance remain the primary camera
  behavior.
- Hardened the session config so legacy `tapFocusEnabled` requests cannot
  enable focus-assist tags or native tap-focus arguments.
- Hardened the shared camera shell so preview taps do not route to focus
  callbacks even if a legacy caller passes tap-focus settings.
- Recorded `BUG-RECEIPT-0129` under `camera_capture_quality`.
- Archived Pass 588 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format for the touched camera settings, session, shell,
  and regression tests.
- Passed targeted analyzer for native camera contract and shell sources/tests.
- Passed focused Flutter regressions for native camera contract and shell.

## Pass 607 - 21:12:42 EDT to 21:13:25 EDT

Scope:
- Hardened native Android and iOS long-receipt ghost-guide argument restore so
  padded or uppercase `previousSectionReasonCode` values normalize before
  title, instruction, and bottom/totals checks run.
- Added native bridge source regressions requiring Android `.lowercase()` and
  iOS `.lowercased()` in the long-receipt settings contracts.
- Recorded `BUG-RECEIPT-0128` under `ghost_overlap_stitching`.
- Archived Passes 586 and 587 out of the live cleanup log to keep the active
  log under the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS native long-receipt
  source regressions.
- Passed focused Flutter Android settings-quality and iOS long-receipt quality
  bridge regressions.

## Pass 606 - 21:10:31 EDT to 21:11:41 EDT

Scope:
- Hardened long-receipt continuation handoff so uppercase or padded
  `missing_bottom_edge_and_totals` reason codes normalize before ghost guide
  fractions, continuation source, and bottom/totals flags are chosen.
- Added behavior coverage proving continuation guides keep the last prior
  section path and normalize the missing-bottom reason for expense flow
  options.
- Added source coverage requiring the shared flow diagnostics path to keep the
  lowercase normalization guard.
- Recorded `BUG-RECEIPT-0127` under `ghost_overlap_stitching`.
- Archived Pass 585 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Fixed the first focused regression assertion after Dart formatting split the
  source expression across lines.
- Passed targeted Dart format/analyzer for continuation handoff code and tests.
- Passed focused Flutter continuation handoff and capture-flow recovery
  regressions.

## Pass 605 - 21:09:04 EDT to 21:09:49 EDT

Scope:
- Hardened iOS native receipt camera parity so the bridge reads, stores, and
  reports the shared `continuousFocusEnabled` session flag.
- Gated iOS startup continuous autofocus configuration behind
  `continuousFocusEnabled` so diagnostics match the actual focus request.
- Added iOS bridge regressions for session argument restore, diagnostics, and
  startup continuous-focus gating.
- Recorded `BUG-RECEIPT-0126` under `camera_capture_quality`.
- Archived Pass 584 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for the focused iOS bridge regressions.
- Passed focused Flutter iOS bridge UI-session and analysis/exposure
  regressions.

## Pass 604 - 21:07:15 EDT to 21:08:00 EDT

Scope:
- Hardened Android CameraX startup so the native bridge consumes
  `continuousFocusEnabled` and applies continuous picture autofocus plus normal
  auto exposure through Camera2Interop for preview and still capture builders.
- Added Android diagnostics for `continuousFocusEnabled` so real-device logs
  can prove whether continuous autofocus was actually requested.
- Added Android bridge source regression coverage for the session argument,
  diagnostics, and Camera2 continuous-focus request.
- Recorded `BUG-RECEIPT-0125` under `camera_capture_quality`.
- Archived Pass 583 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for the Android bridge regression.
- Passed focused Flutter Android bridge analysis/exposure regression.
- Attempted `./gradlew :app:compileDebugKotlin`, but Gradle could not start
  because this Mac has no Java runtime available.

## Pass 603 - 21:04:01 EDT to 21:06:10 EDT

Scope:
- Hardened native receipt camera focus policy so session diagnostics only claim
  continuous autofocus when the device reports continuous-focus support.
- Added a `continuousFocusEnabled` session contract flag, native argument, and
  control tag, with unsupported devices downgraded to readability review.
- Configured iOS AVFoundation to set continuous autofocus and continuous auto
  exposure at session startup when supported.
- Added regressions for capable and unsupported focus policy paths plus the iOS
  startup focus/exposure source contract.
- Recorded `BUG-RECEIPT-0124` under `camera_capture_quality`.
- Archived Pass 582 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for native camera session contracts,
  service arguments, and iOS source-contract coverage.
- Passed focused Flutter native camera session, shared camera contract, and iOS
  bridge analysis/exposure regressions.

## Pass 602 - 21:02:12 EDT to 21:03:17 EDT

Scope:
- Hardened privacy-safe receipt line review/proof contracts so split
  business/personal lines expose clamped business and personal percentages
  without exposing receipt item text.
- Added regression coverage proving over-range split percentages are clamped in
  both line-review and proof-redaction contracts.
- Recorded `BUG-RECEIPT-0123` under `business_personal_split`.
- Archived Pass 581 out of the live cleanup log to keep the active log under
  the project line-count cap.

Verification:
- Passed targeted Dart format/analyzer for expense receipt line models and
  focused line-record regression coverage.
- Passed focused Flutter expense receipt line-record regression coverage.
- Corrected the focused test file after line-count review so it remains under
  the project cap.

## Pass 601 - 20:59:16 EDT to 21:00:52 EDT

Scope:
- Hardened native receipt review-depth aggregation so padded or differently
  cased `pricesOnly`/`detailedLines` diagnostics normalize before review-mode
  handoff.
- Preserved invalid review-depth diagnostics as bounded invalid tokens.
- Added regression coverage proving detailed-line intent is not downgraded by
  case or whitespace drift in camera/recovery diagnostics.
- Recorded `BUG-RECEIPT-0122` under `receipt_line_review_mode`.

Verification:
- Fixed the first focused Flutter compile failure by returning a canonical
  non-null review-depth string from the normalizer branch.
- Passed targeted Dart format/analyzer for native review-depth aggregation and
  frozen review handoff regression coverage.
- Passed focused Flutter review-depth regression coverage.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.
