# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 638 - 22:26:47 EDT to active cleanup

Scope:
- Hardened native receipt camera UI health so a result cannot look ready when
  continuous focus, continuous-focus policy, live readability guidance, or the
  receipt camera quality baseline is missing.
- Added health codes for retired tap focus, missing continuous focus, missing
  live readability guidance, and missing receipt camera quality baseline.
- Added a focused regression proving native readiness is rejected when the
  control surface is ready but focus/readability guidance has drifted.
- Archived Pass 601 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0159` under `camera_capture_quality`.

Verification:
- First focused Flutter run correctly exposed a bad test fixture that marked
  controls expected without actual readiness; fixed the fixture before moving on.
- Passed targeted Dart format for native UI health code changes.
- Passed focused Flutter native UI health regression.

## Pass 637 - 22:24:03 EDT to active cleanup

Scope:
- Hardened client-proof receipt line privacy maps so malformed line IDs and
  proof reference labels cannot leak receipt text into future redaction plans.
- Added reusable privacy-safe line ID and proof-line label guards while keeping
  normal labels like `Line 1` intact.
- Added focused regression coverage across line proof references, selected-line
  bundles, and redaction plans.
- Recorded `BUG-RECEIPT-0158` under `privacy_redaction`.

Verification:
- First focused test run exposed a missed selected-line privacy map boundary;
  fixed that before moving on.
- Passed targeted Dart format/analyzer for client-proof line reference guards.
- Passed focused Flutter receipt processing contract regression.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 636 - 22:21:16 EDT to active cleanup

Scope:
- Hardened client-proof receipt line privacy maps so malformed source section
  labels cannot leak store/customer text into future redaction plans.
- Kept normal generic labels such as `Photo 1` while bucketing unsafe labels as
  `source_section` in privacy-safe output only.
- Added focused regression coverage across selected-line, redaction-plan, and
  image-review privacy maps.
- Recorded `BUG-RECEIPT-0157` under `privacy_redaction`.

Verification:
- Passed targeted Dart format/analyzer for client-proof receipt line contracts.
- Passed focused Flutter receipt processing contract regression.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 635 - 22:18:44 EDT to active cleanup

Scope:
- Extended edited-photo action redaction from receipt-reader metadata into
  attachment document signals and OCR-source risk flags.
- Added a focused public attachment handoff regression proving malformed edit
  action text is bucketed without leaking receipt-like content or local paths.
- Archived Pass 624 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0156` under `privacy_redaction`.

Verification:
- Fixed the first targeted test run by adding the missing receipt model import.
- Passed targeted Dart format/analyzer for attachment and capture-flow handoff
  changes.
- Passed focused Flutter recovery handoff regression.
- Passed cleanup log gate, doc-size gate, receipt source audit, and whitespace
  check.

## Pass 634 - 22:16:55 EDT to active cleanup

Scope:
- Hardened edited-photo action telemetry so privacy-safe handoff metadata keeps
  known edit actions but buckets malformed action strings generically.
- Added focused regression coverage proving malformed edit-action text does not
  leak into receipt-reader handoff counts or metadata.
- Archived Pass 623 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0155` under `privacy_redaction`.

Verification:
- Passed targeted Dart format/analyzer for edited-photo metadata.
- Passed focused Flutter native recovery metadata regression.
- Passed whitespace check.

## Pass 633 - 22:15:43 EDT to active cleanup

Scope:
- Hardened malformed native review-depth diagnostics so privacy-safe receipt
  metadata uses a generic invalid bucket instead of tokenizing raw diagnostic
  text that could contain receipt content.
- Added focused review-depth regression coverage proving malformed values stay
  visible without leaking the raw text or receipt paths.
- Archived Pass 622 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0154` under `privacy_redaction`.

Verification:
- Passed targeted Dart format/analyzer for native review-depth metadata.
- Passed focused Flutter frozen camera/result metadata regression.
- Passed whitespace check.

## Pass 632 - 22:14:24 EDT to active cleanup

Scope:
- Hardened OCR parser stable line IDs so malformed negative signal indexes clamp
  to the first receipt line instead of publishing odd negative ID anchors.
- Extended focused parser handoff regression coverage for sanitized stable IDs
  and line-number maps.
- Recorded `BUG-RECEIPT-0153` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format/analyzer for parser stable-line ID changes.
- Passed focused Flutter parser handoff structure regression.
- Passed whitespace check.

## Pass 631 - 22:12:52 EDT to active cleanup

Scope:
- Hardened OCR parser draft line numbering so malformed signal indexes or direct
  draft line numbers cannot publish `Line 0`, negative review labels, or unsafe
  redaction/proof anchors.
- Routed parser handoff `lineNumberByLineId` through the sanitized line number.
- Added focused behavior regression coverage for malformed draft and signal line
  numbers.
- Archived Pass 621 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0152` under `receipt_line_numbering`.

Verification:
- Passed targeted Dart format/analyzer for parser line numbering changes.
- Passed focused Flutter parser handoff structure regression.
- Passed whitespace check.

## Pass 630 - 22:11:18 EDT to active cleanup

Scope:
- Hardened native ghost-guide session getters so direct malformed non-finite
  values fall back to safe long-receipt overlap defaults before native handoff.
- Added focused behavior regression coverage for direct session config `NaN` and
  infinity ghost-guide values.
- Archived Pass 620 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0151` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for native ghost-guide session changes.
- Passed focused Flutter native camera session limits regression.
- Passed whitespace check.

## Pass 629 - 22:08:07 EDT to active cleanup

Scope:
- Added privacy-safe long-receipt ghost slice percent handoff signals so review,
  OCR, admin QA, and future UI/native changes can prove the intended overlap
  guidance without exposing receipt paths or text.
- Added focused continuation handoff regressions for native slice-percent
  diagnostics, fallback fraction-derived slice percent, malformed numeric
  diagnostics, and no receipt-text leakage.
- Archived Pass 619 from the active cleanup log to keep the doc under cap.
- Recorded `BUG-RECEIPT-0150` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for continuation handoff changes.
- Passed focused Flutter continuation handoff regression.
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
