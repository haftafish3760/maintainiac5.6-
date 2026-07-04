# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

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

## Pass 600 - 20:56:33 EDT to 20:58:38 EDT

Scope:
- Hardened Android and iOS native close outcome classifiers so
  `back_capture_failed_returned_existing_sections` becomes the distinct
  `capture_failed_returned_existing_sections` outcome instead of generic
  `capture_failed_after_close`.
- Wired that partial-success close outcome through review handoff labels,
  native health codes, document signals, and risk flags.
- Added native source-contract and review-result regressions for the failed
  latest section / existing sections returned path.
- Recorded `BUG-RECEIPT-0121` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for native close source-contract and
  review-handoff regressions.
- Passed focused Flutter Android native diagnostics, review close handoff, and
  explicit iOS native storage/close regressions.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.

## Pass 599 - 20:54:50 EDT to 20:55:59 EDT

Scope:
- Hardened Android and iOS native pre-capture exposure outcome classification
  so `aborted_camera_closing` remains a stable diagnostic outcome instead of
  collapsing to `not_evaluated`.
- Added Android and iOS source-contract regressions for the abort outcome.
- Recorded `BUG-RECEIPT-0120` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for Android and iOS native diagnostics
  source-contract regressions.
- Passed focused Flutter native diagnostics/storage regressions for Android
  and iOS.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.

## Pass 598 - 20:52:16 EDT to 20:54:10 EDT

Scope:
- Hardened iOS pre-capture exposure adjustment so losing camera UI during the
  AVFoundation exposure callback clears in-flight capture state instead of
  silently returning.
- Added iOS pre-capture exposure abort diagnostics matching the Android
  behavior: abort count plus abort reason.
- Updated iOS source-contract regressions so the unsafe `guard let self,
  self.isCameraUiUsable else { return }` does not come back in capture prep.
- Recorded `BUG-RECEIPT-0119` under `native_bridge`.

Verification:
- Fixed the first focused regression by scoping the negative early-return check
  to `ReceiptCameraViewControllerCapture.swift` instead of the full iOS bridge
  bundle, where live-frame callbacks still have their own valid guard.
- Passed targeted Dart format/analyzer for the iOS bridge source-contract
  regressions.
- Passed focused Flutter iOS bridge analysis/exposure and UI-session
  regressions.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.

## Pass 597 - 20:50:44 EDT to 20:51:48 EDT

Scope:
- Hardened Android saved-photo auto-capture cooldown so successful captures use
  the configured `autoCaptureCooldownMs` instead of a hard-coded 2600ms delay.
- Hardened iOS saved-photo auto-capture cooldown with the same session-driven
  behavior.
- Added Android and iOS source-contract regressions rejecting hard-coded
  saved-photo cooldowns.
- Recorded `BUG-RECEIPT-0118` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for Android and iOS native auto-capture
  source-contract regressions.
- Passed focused Flutter Android native auto-capture regression.
- Passed focused Flutter iOS native settings/close regression separately for
  explicit evidence.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.

## Pass 596 - 20:46:21 EDT to 20:50:14 EDT

Scope:
- Removed tap-focus as a default receipt-camera behavior so continuous
  autofocus and readability guidance are the primary camera path.
- Changed shared camera settings plus Android and iOS native fallback defaults
  so `tapFocusEnabled` is false unless explicitly enabled by settings.
- Removed the standard camera-shell "Tap text to focus" chip and replaced it
  with continuous-focus/readability copy through "Auto sharpness".
- Updated native diagnostics policy defaults from focus-assist-first wording to
  continuous-focus/readability-first wording.
- Recorded `BUG-RECEIPT-0117` under `camera_capture_quality`.

Verification:
- Fixed stale QA expectations that still counted tap-focus as a required
  default native control.
- Passed targeted Dart format/analyzer for the shared camera contract/shell and
  native bridge source-contract regressions.
- Passed focused Flutter regressions for the native camera contract/session,
  shell, Android/iOS bridge defaults, coverage contract, and native UI health.
- Passed cleanup log gate, doc-size gate, source audit, and whitespace check.

## Pass 595 - 20:43:24 EDT to 20:44:44 EDT

Scope:
- Hardened generated edit and best-shot cleanup so kept receipt artifacts are
  checked with normalized receipt-photo path identity instead of raw set
  membership.
- Added source regression coverage proving generated cleanup uses
  `receiptPhotoPathSetContains` and does not return to raw `keptPaths.contains`.
- Updated a stale lifecycle regression to assert the current generalized
  order-diagnostics merge contract.
- Recorded `BUG-RECEIPT-0116` under `source_preservation`.

Verification:
- Fixed the first focused lifecycle regression mismatch by updating the stale
  source-contract assertion to the current generalized merge helper.
- Passed targeted Dart format/analyzer for generated cleanup and lifecycle
  source-contract coverage.
- Passed focused Flutter lifecycle regression.

## Pass 594 - 20:41:22 EDT to 20:42:20 EDT

Scope:
- Hardened Android native auto-capture session parsing so blocked or
  unavailable auto-capture keeps `requiredStableFrames` and cooldown diagnostics
  at zero instead of clamping them back to runtime minimums.
- Hardened iOS native auto-capture session parsing with the same zero-when-
  blocked threshold behavior.
- Added Android and iOS source-contract regressions for honest blocked
  auto-capture threshold diagnostics.
- Recorded `BUG-RECEIPT-0115` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer for native auto-capture source-contract
  regressions.
- Passed focused Flutter Android and iOS native auto-capture/settings
  regressions.

## Pass 593 - 20:39:15 EDT to 20:40:06 EDT

Scope:
- Wired `focusStrategyPolicy`, `readabilityGuidancePolicy`, and
  `receiptCameraQualityBaseline` through Android native receipt camera session
  arguments and capture diagnostics.
- Wired the same focus/readability policy diagnostics through iOS native
  receipt camera session arguments and capture diagnostics.
- Added Android and iOS source-contract regressions so native diagnostics prove
  the continuous-focus/readability baseline rather than only Dart settings.

Verification:
- Passed targeted Dart analyzer for Android/iOS native bridge source-contract
  tests.
- Passed focused Flutter Android and iOS native bridge UI regressions.

## Pass 592 - 20:37:15 EDT to 20:38:26 EDT

Scope:
- Removed remaining user-facing tap-focus-first wording from the receipt camera
  first-use sheet, help sheet, Android settings dialog, and iOS settings copy.
- Updated Android and iOS native touch-control diagnostics to report
  `focus_assist_and_pinch_zoom_on_preview_v1`.
- Updated native Android/iOS default focus policy strings so platform defaults
  match the Dart continuous-focus-primary contract.
- Kept the legacy fallback policy only for non-continuous focus modes.

Verification:
- Confirmed stale tap-focus copy scan only finds the non-continuous fallback.
- Passed targeted Dart analyzer for edited Flutter help/copy and native bridge
  source-contract tests.
- Passed focused Flutter native bridge UI and receipt camera help regressions.

## Pass 591 - 20:32:44 EDT to 20:36:37 EDT

Scope:
- Reframed the receipt camera focus contract so continuous autofocus is the
  primary capture behavior and tap-to-focus is only optional focus assist.
- Added shared focus/readability policy diagnostics for continuous focus,
  brightness assist, sharpness guidance, and live readability guidance.
- Updated user-facing camera quality guidance to tell users to hold steady and
  let the camera refocus before using focus assist.
- Added `focus_assist` as a native control contract alias while preserving
  legacy `tapFocus...` bridge diagnostics for compatibility.
- Recorded `BUG-RECEIPT-0114` under `camera_capture_quality`.

Verification:
- Fixed one focused regression mismatch for devices without focus-assist
  support and one health-tag alias mismatch before proceeding.
- Passed targeted Dart analyzer for the edited receipt camera contract,
  guidance, diagnostics, and regression tests.
- Passed focused Flutter regressions for native camera contract/session,
  privacy diagnostics, assistance policy diagnostics, quality guidance, and
  native UI health.

## Pass 590 - 20:11:15 EDT to active cleanup

Scope:
- Added a work-supply barcode scan bridge that converts shared ML Kit
  barcode/QR results into inventory package alias suggestions.
- Preserved the existing inventory alias normalization path instead of creating
  a second barcode identity model.
- Added privacy-safe suggestion summaries that expose format/type/length but
  not the scanned code value.
- Added focused regressions for UPC, QR, duplicate scan values, sensitive QR
  payload exclusion, and unknown-format guessing.
- Recorded `BUG-RECEIPT-0113` under `barcode_qr_scanning`.
- Archived Pass 570 out of the live cleanup log before recording Pass 590.

Verification:
- Passed targeted Dart format/analyzer for the work-supply barcode bridge.
- Passed focused barcode bridge and shared scanner service regressions.

## Pass 589 - 16:06:06 EDT to active cleanup

Scope:
- Classified generated work-supply catalog Dart files separately in the source
  audit instead of mixing generated data with hand-written receipt parser code.
- Added an explicit `--include-generated-catalog-data` source-audit mode so
  generated catalog files can still be audited intentionally.
- Added regression coverage proving generated catalog data is skipped by
  default and included when requested.
- Added regression coverage proving vendored native `.symlinks` plugin sources
  do not count against app-owned source caps.
- Hardened Add Another Photo ordering so inserted long-receipt sections carry
  anchor section, final section, offset, and order-policy diagnostics.
- Extended receipt result handoff counts so inserted section metadata reaches
  privacy-safe section-order outcomes and admin/QA summaries.
- Hardened manual move-earlier/move-later ordering so user-reordered receipt
  sections carry privacy-safe original/final section and direction evidence.
- Locked manual reorder plans to adjacent one-section moves so future UI
  controls cannot silently skip receipt sections.
- Added an explicit capture-flow review-depth override so detailed-line intent
  reaches the native camera session.
- Mapped expense simple/full review style to native price-only/detailed-line
  capture, while inventory and maintenance capture request detailed lines.
- Hardened camera quality diagnostics so normalized receipt photo path aliases
  cannot publish duplicate per-photo evidence.
- Added the local Google ML Kit barcode/QR scanner dependency and a shared
  scanner service for receipt, inventory, and maintenance callers.
- Added barcode/QR result models that normalize duplicate lookup values while
  keeping raw code text out of privacy-safe summaries.
- Blocked sensitive QR payload types such as Wi-Fi, contact, phone, geo, and
  driver-license values from inventory lookup suggestions.
- Added focused retake/order and source-contract regressions for inserted
  section metadata and stale inserted-path rejection.
- Added a focused regression for non-adjacent manual reorder requests.
- Added focused shared camera flow regressions for review-depth propagation.
- Added focused camera-result quality regression coverage for path aliases.
- Added focused barcode scanner service regressions for dedupe, invalid paths,
  sensitive payload handling, and platform failure warnings.
- Split section-order helper logic out of native-signal summaries after the
  source audit caught the file over the line cap.
- Recorded `BUG-RECEIPT-0106` and `BUG-RECEIPT-0107` under
  `multi_photo_ordering`.
- Recorded `BUG-RECEIPT-0108` and `BUG-RECEIPT-0109` under
  `multi_photo_ordering`.
- Recorded `BUG-RECEIPT-0110` under `receipt_line_review_mode`.
- Recorded `BUG-RECEIPT-0111` under `camera_capture_quality`.
- Recorded `BUG-RECEIPT-0112` under `barcode_qr_scanning`.
- Archived Pass 564 out of the live cleanup log to keep the active log under the
  project line-count cap.
- Archived Pass 565 out of the live cleanup log after this pass grew the active
  log past the cap.
- Archived Pass 566 out of the live cleanup log before recording result-level
  insert-order handoff coverage.
- Archived Pass 567 out of the live cleanup log before recording adjacent
  manual-reorder guard coverage.
- Archived Pass 568 out of the live cleanup log before recording camera-quality
  path identity coverage.
- Archived Pass 569 out of the live cleanup log before recording barcode/QR
  scanner coverage.

Verification:
- Passed focused Flutter source-audit contract regression coverage.
- Passed focused work-supply data source audit for hand-written files.
- Confirmed `--include-generated-catalog-data` still reports the oversized
  generated catalog data files.
- Passed targeted analyzer and focused Flutter tests for receipt retake/order
  and long-receipt guidance contracts.
- Passed focused receipt result stitch/scanner regressions for valid and
  malformed insert-after metadata.
- Passed focused manual reorder regressions and source contract coverage.
- Passed focused adjacent manual reorder regression coverage.
- Passed focused shared capture-flow review-depth regression coverage.
- Passed focused camera-result quality path identity regression coverage.
- Passed focused barcode scanner service regression coverage.
- Passed the receipt QA runner after the source-audit and long-receipt ordering
  cleanup batch.
- Passed scoped receipt source audit and cleanup/doc size gates.
- Passed `git diff --check`.
