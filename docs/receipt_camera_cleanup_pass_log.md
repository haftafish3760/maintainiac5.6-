# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 708 - 02:45:00 EDT to active cleanup

Scope:
- Removed stale iOS native settings copy that still told users to use focus
  assist after the receipt camera moved to continuous-autofocus/readability
  guidance.
- Added focused iOS bridge source regression coverage so the retired focus
  assist copy cannot return through settings/help text.
- Fixed stale iOS bridge QA assertions that still expected direct raw
  readability-signal equality checks instead of the named readability-review
  policy set.
- Recorded `BUG-RECEIPT-0195` under `camera_capture_quality`.
- Recorded `BUG-RECEIPT-0196` under `qa_harness`.
- Archived Pass 650 from the active cleanup log to keep the doc under cap.

Verification:
- First focused iOS settings bridge regression failed because the test still
  expected raw `latestReadabilitySignal == ...` checks; fixed the regression to
  require the helper/set policy and reject direct equality checks.
- Passed targeted Dart format/analyzer for the iOS settings bridge test.
- Passed focused iOS settings bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 707 - 02:38:00 EDT to active cleanup

Scope:
- Audited native long-receipt ghost-guide argument parsing after the tap-focus
  boundary hardening.
- Fixed iOS previous-section guide path handling so it stores the trimmed path
  instead of keeping whitespace around the local receipt image path.
- Added focused iOS bridge regression coverage for the trimmed ghost-guide path.
- Recorded `BUG-RECEIPT-0194` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for iOS long-receipt bridge test.
- Passed focused iOS long-receipt bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 649 from the active cleanup log to keep the doc under cap.

## Pass 706 - 02:31:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native session argument readers so stale or malformed
  bridge arguments cannot re-enable tap-focus for receipt capture.
- Forced the native tap-focus policy to
  `continuous_focus_primary_no_tap_focus` at both platform boundaries.
- Updated Android and iOS bridge regressions to reject raw tap-focus argument
  trust.
- Recorded `BUG-RECEIPT-0193` under `native_bridge`.
- Archived Pass 647 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native bridge tests.
- Passed focused Android/iOS bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 648 from the active cleanup log to keep the doc under cap.

## Pass 705 - 02:25:00 EDT to active cleanup

Scope:
- Aligned in-entry draft receipt line numbering with the saved ledger line
  guardrails so malformed OCR line or section numbers cannot show impossible
  proof labels before save.
- Added bounded draft line/section helpers and routed draft proof labels, OCR
  source labels, and redaction anchors through them.
- Expanded the assisted-review source fixture so regression coverage includes
  the shared draft line support and label helpers.
- Recorded `BUG-RECEIPT-0192` under `receipt_line_numbering`.
- Archived Pass 646 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for draft receipt line helpers and
  assisted-review source regression.
- Passed focused Flutter assisted receipt review flow regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 704 - 02:18:00 EDT to active cleanup

Scope:
- Audited the shared Google ML Kit barcode/QR scanner foundation after the
  camera-lane reminder to keep scanner support shared across expenses,
  inventory, and maintenance without touching inventory internals.
- Added corrupted/wrong-file style regression coverage so generic decoder
  failures become safe `barcode_scan_failed` warnings.
- Proved raw exception text from barcode failures does not leak into
  privacy-safe scanner summaries.
- Recorded `BUG-RECEIPT-0191` under `barcode_qr_scanning`.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service tests.
- Passed focused Flutter barcode scanner service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 645 from the active cleanup log to keep the doc under cap.

## Pass 703 - 02:12:00 EDT to active cleanup

Scope:
- Audited active receipt camera docs and focus policy after retiring tap-focus
  as a product answer.
- Strengthened the active-doc focus regression so the exact `tap-focus` phrase
  cannot come back into active camera docs.
- Removed the stale active native service spec sentence that still described
  tap-focus as legacy diagnostics.
- Recorded `BUG-RECEIPT-0190` under `qa_harness`.

Verification:
- Initial focused regression failed on the stale native service spec sentence;
  fixed it before moving on.
- Passed targeted Dart format/analyzer for the active camera docs policy test.
- Passed focused Flutter active camera docs focus-policy regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 644 from the active cleanup log to keep the doc under cap.

## Pass 702 - 02:06:00 EDT to active cleanup

Scope:
- Hardened continuation guide application so manual guide construction cannot
  leak untrimmed reason/guidance/path values or malformed ghost overlay
  fractions into shared capture options.
- Clamped out-of-range ghost fractions and dropped non-finite fractions before
  native camera session arguments can inherit continuation context.
- Added focused regression coverage for malicious/manual continuation guide
  values.
- Recorded `BUG-RECEIPT-0189` under `ghost_overlap_stitching`.
- Archived Passes 642 and 643 from the active cleanup log to keep the doc
  under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow models.
- Passed focused Flutter receipt capture flow shareability regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 701 - 01:45:00 EDT to active cleanup

Scope:
- Strengthened long-receipt continuation coverage so Add Photo/continuation
  guides prove they preserve module-default detailed review intent.
- Added direct assertions for materials inventory and maintenance continuation
  staying detailed-line review while expense continuation remains price-only by
  default unless forced.
- Kept missing-bottom/totals ghost context expectations pinned in the same
  shared-flow regression.
- Recorded `BUG-RECEIPT-0188` under `qa_harness`.
- Archived Pass 641 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt capture flow shareability.
- Passed focused Flutter receipt capture flow shareability regression.

## Pass 700 - 01:40:00 EDT to active cleanup

Scope:
- Promoted module-specific receipt review depth into a direct
  `ReceiptCaptureFlowOptions.effectiveReviewDepth` contract.
- Updated the shared capture settings builder to use that model contract instead
  of a private helper, making the inventory/maintenance detailed-line default
  directly testable.
- Strengthened the shareability regression so it asserts behavior for expenses,
  shared, materials inventory, maintenance/repair, and forced overrides.
- Recorded `BUG-RECEIPT-0187` under `qa_harness`.
- Archived Pass 640 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow models.
- Passed focused Flutter receipt capture flow shareability regression.

## Pass 699 - 01:34:00 EDT to active cleanup

Scope:
- Hardened receipt line review-mode detection so raw OCR evidence, catalog item
  evidence, or parser classification keeps a line in detailed review even when
  the cleaned display description is still generic.
- Preserved privacy-safe output by proving raw OCR receipt text does not leak
  through the line review contract.
- Added focused regression coverage for OCR-only detailed line evidence.
- Recorded `BUG-RECEIPT-0186` under `receipt_line_review_mode`.
- Archived Pass 639 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for expense receipt line records.
- Passed focused Flutter expense receipt line record regression.

## Pass 698 - 01:29:00 EDT to active cleanup

Scope:
- Fixed shared receipt capture defaults so materials-inventory and
  maintenance/repair launches use detailed-line review when no caller forces a
  review depth.
- Kept expenses and generic shared launches price-only by default, preserving
  the fast review path unless the caller or expense settings asks for details.
- Added a focused shared-flow regression guarding the module-specific review
  depth default and the existing attachment UI override path.
- Recorded `BUG-RECEIPT-0185` under `receipt_line_review_mode`.
- Archived Pass 638 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for shared receipt capture flow.
- Passed focused Flutter receipt capture flow shareability regression.

## Pass 697 - 01:23:00 EDT to active cleanup

Scope:
- Removed stale active handoff wording that still said users can tap to focus
  during the production receipt camera flow.
- Replaced it with continuous autofocus/readability guidance plus pinch zoom,
  brightness/exposure, and torch controls where supported.
- Extended the active camera docs focus-policy regression to cover the long
  2026-07-03 receipt camera handoff and reject tap-to-focus flow wording.
- Recorded `BUG-RECEIPT-0184` under `camera_capture_quality`.
- Archived Pass 637 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer for the active camera docs focus-policy test.
- Passed focused Flutter active camera docs focus-policy regression.

## Pass 696 - 01:18:00 EDT to active cleanup

Scope:
- Removed stale active native-camera service spec wording that still listed tap
  focus as a camera hardware control.
- Reworded native service current-state guidance around continuous
  focus/readability instead of generic focus adjustment.
- Extended the active camera docs focus-policy regression to cover the native
  service spec and reject tap focus as an active control list item.
- Recorded `BUG-RECEIPT-0183` under `camera_capture_quality`.
- Archived Pass 636 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart analyzer for the active camera docs focus-policy test.
- Passed focused Flutter active camera docs focus-policy regression.

## Pass 695 - 01:10:00 EDT to active cleanup

Scope:
- Carried layout redaction telemetry into the expense telemetry client-proof
  summary so Command Center can see visible, hidden, ignored, protected-type,
  merchant-context, and totals-context layout counts.
- Added Command Center and Firestore summary sanitizer coverage for the new
  layout redaction rollup keys and top layout status.
- Extended focused telemetry workflow and parity fixtures so admin summaries
  cannot silently drop layout redaction evidence.
- Recorded `BUG-RECEIPT-0182` under `privacy_redaction`.
- Archived Pass 635 from the active cleanup log to keep the doc under cap.

Verification:
- First focused test run exposed that layout context booleans were missing from
  the expense telemetry metadata allowlist; fixed before continuing.
- Second focused test run exposed missing Firestore parity keys and an
  under-exercised rich parity fixture; fixed both before continuing.
- Passed targeted Dart analyzer for expense telemetry redaction rollups.
- Passed focused Flutter expense telemetry workflow, sanitizer, and Firestore
  Command Center parity regressions.

## Pass 694 - 01:05:00 EDT to active cleanup

Scope:
- Aggregated privacy-safe layout redaction telemetry into the receipt privacy
  health snapshot and Command Center map.
- Added policy and telemetry metadata allowlist coverage for layout redaction
  status, visible/hidden/ignored counts, protected-type counts, and context
  booleans.
- Extended the health fixture regression so stored layout redaction events prove
  the rollup cannot silently drop QA/admin redaction visibility.
- Recorded `BUG-RECEIPT-0181` under `privacy_redaction`.
- Archived Pass 634 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt privacy health redaction
  telemetry.
- Passed focused Flutter receipt privacy event store regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 693 - 00:55:10 EDT to active cleanup

Scope:
- Added a privacy-safe receipt event path for layout redaction plans so
  QA/admin telemetry can see visible, hidden, ignored, and protected line
  counts without receipt text or anchor IDs.
- Added scalar serialization for layout redaction status, counts, and context
  booleans.
- Added regression coverage proving ignored line-target telemetry stays
  privacy-safe.
- Recorded `BUG-RECEIPT-0180` under `privacy_redaction`.
- Archived Passes 633 and 632 from the active cleanup log to keep the doc under
  cap.

Verification:
- First focused regression run failed because the tiny fixture did not prove
  merchant-context detection; fixed the fixture to use recognizable receipt
  structure.
- Passed targeted Dart format/analyzer for receipt privacy event redaction
  telemetry.
- Passed focused Flutter receipt privacy event regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

## Pass 692 - 00:53:45 EDT to active cleanup

Scope:
- Added a privacy-safe receipt layout redaction summary so QA/admin diagnostics
  can see visible, hidden, ignored, and protected line counts without receipt
  text.
- Included safe redaction anchor codes and protected content buckets while
  keeping raw OCR/item text out of the summary.
- Added regression coverage proving ignored line-target requests are summarized
  safely and raw receipt text is not exposed.
- Recorded `BUG-RECEIPT-0179` under `privacy_redaction`.
- Archived Pass 631 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for receipt layout redaction summary.
- Passed focused Flutter direct parser/layout redaction regression.
- Passed cleanup log, doc size, bug ledger, source audit, tests-only source
  audit, and diff whitespace gates.

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
