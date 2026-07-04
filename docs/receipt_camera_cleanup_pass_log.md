# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 691 - 00:52:13 EDT to active cleanup

Scope:
- Hardened receipt layout redaction plans so positive selected line numbers that
  do not exist in the current OCR/layout map cannot be counted as visible.
- Added ignored-line diagnostics for unknown positive redaction requests while
  keeping malformed nonpositive requests dropped.
- Added regression coverage for a phantom selected line number that must not
  create a visible line or anchor.
- Recorded `BUG-RECEIPT-0178` under `privacy_redaction`.
- Archived Pass 630 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt layout redaction.
- Passed focused Flutter direct parser/layout redaction regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 690 - 00:50:48 EDT to active cleanup

Scope:
- Hardened directly constructed selected receipt line references so malformed
  business/personal percentages cannot publish non-finite or overallocated
  split totals.
- Made business use the source of truth for selected-line allocation and made
  split personal percent the complement of the clamped business percent.
- Added regression coverage for overallocated and non-finite selected-line
  split allocations.
- Recorded `BUG-RECEIPT-0177` under `business_personal_split`.
- Archived Pass 629 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for selected receipt line allocation.
- Passed focused Flutter receipt processing contract regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 689 - 00:48:40 EDT to active cleanup

Scope:
- Preserved excluded receipt line references in selection bundles so future
  client-proof image redaction can target real receipt line IDs and proof labels
  instead of synthetic placeholders.
- Routed excluded line references into the client-proof redaction plan while
  keeping the old placeholder fallback for legacy constructed bundles.
- Added regression coverage proving excluded personal lines remain privacy-safe
  but retain the real line ID, proof label, and source section needed for
  redaction overlays.
- Recorded `BUG-RECEIPT-0176` under `privacy_redaction`.
- Archived Passes 628 and 618 from the active cleanup log to keep the doc under
  cap.

Verification:
- First focused regression run failed because summary expectations still
  assumed hidden lines did not contribute source sections; fixed that test
  expectation after preserving excluded line references.
- Passed targeted Dart format/analyzer for receipt selection and client-proof
  contracts.
- Passed focused Flutter receipt processing contract regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 688 - 00:46:49 EDT to active cleanup

Scope:
- Added explicit business and personal allocated subtotal, tax, and total
  values to selected receipt line references while preserving raw receipt
  totals for audit.
- Exposed selected business/personal totals on receipt selection bundles and
  privacy-safe readiness maps so split lines cannot be mistaken for all-business
  amounts downstream.
- Added regression coverage for a 50/50 split receipt line in the invoice/client
  proof selection contract.
- Recorded `BUG-RECEIPT-0175` under `business_personal_split`.
- Archived Pass 617 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt line selection contracts.
- Passed focused Flutter receipt processing contract regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 687 - 00:45:35 EDT to active cleanup

Scope:
- Removed old focus-assist wording from blurry receipt quality guidance so the
  user-facing camera flow stays aligned with continuous autofocus as the primary
  product behavior.
- Added regression expectations that blurry receipt guidance names continuous
  autofocus and does not reintroduce focus-assist or tap-focus wording.
- Recorded `BUG-RECEIPT-0174` under `camera_capture_quality`.
- Archived Pass 616 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt photo quality guidance.
- Passed focused Flutter receipt camera quality guidance regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 686 - 00:41:29 EDT to active cleanup

Scope:
- Capped impossible OCR receipt line and section numbers before they can appear
  in proof labels, redaction anchors, serialized expense maps, parser handoff
  labels, or privacy-safe handoff contracts.
- Added regression coverage for huge malformed OCR row/section metadata so this
  class of line-numbering bug cannot return quietly.
- Split receipt line privacy/proof tests into
  `test/expense_receipt_line_privacy_test.dart` to keep the original receipt
  line record test under the project line-count cap.
- Fixed receipt bug ledger gate drift so existing barcode/QR and camera
  review-state regression categories remain accepted by the permanent gate.
- Recorded `BUG-RECEIPT-0172` under `receipt_line_numbering`.
- Recorded `BUG-RECEIPT-0173` under `qa_harness`.
- Archived Pass 615 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt line and parser handoff
  files.
- Passed focused Flutter receipt line, receipt line privacy, and OCR parser
  handoff regressions.
- First ledger gate run failed on stale allowed categories; fixed and reran the
  gate before milestone push.

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
