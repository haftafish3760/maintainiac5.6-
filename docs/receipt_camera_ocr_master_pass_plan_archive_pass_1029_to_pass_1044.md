# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 1029: Privacy-Safe Vendor Review Reasons

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 1029: Privacy-Safe Vendor Review Reasons

Status: complete.

What changed:
- Added a dedicated `vendorReviewStatus`, `vendorReviewLabel`, and
  privacy-safe `vendorReviewDiagnostics` layer to the local OCR parser handoff
  and diagnostics.
- Tagged address/contact metadata rows with `address_or_contact_metadata`, then
  exposed only their line ids and counts in privacy-safe contracts.
- Distinguished recoverable missing-store cases caused by suppressed
  address/phone rows from recoverable missing-store cases where OCR simply did
  not see header text.
- Kept bad-order missing-vendor receipts in an unrecoverable review state so the
  app does not proceed just because date, total, and item text exist somewhere.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "address and phone rows are not promoted to vendor on damaged headers" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "missing vendor recovery explains no header text without raw content" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "missing vendor with unsafe order stays unrecoverable for review" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "damaged merchant header recovers receipt structure with review" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening generic
  merchant/header recovery by adding privacy-safe weak-header candidate buckets
  for non-address text that is near the top of the receipt but not trusted
  enough to auto-fill the vendor field.

### Receipt Camera Reopen Pass 1030: Weak Header Candidate Review Bucket

Status: complete.

What changed:
- Added conservative weak-header candidate tagging for OCR-damaged store-name
  rows that are near the top of the receipt but fail trusted vendor detection.
- Added privacy-safe weak-header line id/count diagnostics to the parser handoff,
  header recovery diagnostics, vendor review diagnostics, and aggregate counts.
- Updated vendor review status so a recoverable receipt with weak header text is
  routed to store-name review instead of pretending the merchant is trusted or
  treating the receipt as headerless.
- Added regression coverage proving damaged header text is not leaked through
  the privacy-safe parser handoff contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "weak damaged merchant header is review-only and privacy safe" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "address and phone rows are not promoted to vendor on damaged headers" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "missing vendor recovery explains no header text without raw content" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "missing vendor with unsafe order stays unrecoverable for review" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a privacy-safe
  parser handoff status for receipts that look complete enough for review versus
  receipts that should immediately prompt for another long-receipt photo.

### Receipt Camera Reopen Pass 1031: Post-Capture OCR Route Status

Status: complete.

What changed:
- Added `receiptPostCaptureRouteStatus` and `receiptPostCaptureRouteLabel` to
  OCR diagnostics so the capture flow can consume one local route decision after
  photo acceptance.
- Routes now distinguish parsed receipt review, parsed review with vendor check,
  parsed review with missing-total check, add-next-section long receipt flow,
  user-confirmed complete review, and retake/manual fallback.
- Added the route status to receipt totals coverage diagnostics and parser
  signal summaries so local QA and later Command One health can audit the
  decision without receipt text.
- Added regression coverage for complete receipts, missing totals without bottom
  edge risk, missing bottom-edge plus missing totals, and user-confirmed
  complete receipts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics exposes receipt totals coverage evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr totals evidence can trigger missing bottom coverage decision" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "user confirmed complete receipt separates review from continuation" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is connecting the route
  status to the receipt capture review flow so accepted photos advance to the
  correct app-assisted review or long-receipt continuation path.

### Receipt Camera Reopen Pass 1032: Accepted Photo Route Handoff Wiring

Status: complete.

What changed:
- Wired `receiptPostCaptureRouteStatus` into the expense receipt entry handoff
  state after OCR completes.
- Added route-status helpers that map OCR routes to the receipt handoff stage
  and route-result copy, including next-section, bottom-total check, store-name
  check, manual-check, user-confirmed complete, and unreadable fallback routes.
- Added `receiptPostCaptureRouteStatus` and `receiptPostCaptureRouteLabel` to
  OCR completion telemetry metadata.
- Kept the state-actions OCR path consistent with the main receipt entry screen
  so accepted photos and attached receipt proof use the same route decision.
- Hardened the missing-bottom handoff so the stronger
  `receiptMissingBottomEdgeAndTotals` signal keeps a dedicated warning/result
  instead of being flattened into the softer missing-total review path.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a focused local
  route-status unit test around `ReceiptOcrDiagnostics` and the expense entry
  handoff helpers for vendor-check and manual-check routes.

### Receipt Camera Reopen Pass 1033: Coverage Decision Evidence Contract

Status: complete.

What changed:
- Added a privacy-safe evidence contract to `ReceiptPhotoCoverageDecision` so a
  missing-bottom route can prove when it was driven by both bottom-edge evidence
  and subtotal/total OCR evidence.
- Added explicit evidence labels for the strong
  `bottom_edge_missing_plus_totals_text_missing` case versus softer/manual
  coverage review.
- Extended camera-result regression coverage so the bottom-section ghost-guide
  decision carries the combined evidence contract, while a receipt with detected
  totals remains out of the long-receipt continuation path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "detected totals avoid long receipt prompt when bottom is present" -r compact`
- `flutter test test/receipt_camera_quality_guidance_test.dart --plain-name "coverage" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is feeding the coverage
  decision evidence contract into the accepted photo document signals so OCR
  source diagnostics and Command One health can count this path without raw
  receipt text.

### Receipt Camera Reopen Pass 1034: Coverage Evidence OCR Source Signals

Status: complete.

What changed:
- Added coverage-decision document signals to both shared `ReceiptCaptureFlow`
  OCR source attachments and the expense attachment-panel OCR source path.
- The OCR source now receives privacy-safe tokens for coverage status, reason,
  continuation contract, evidence contract, and the combined bottom-edge plus
  totals-missing condition.
- Added shared-flow quality lookup so coverage decisions in the reusable flow
  can use the matching photo quality check or the weakest section quality for a
  combined OCR source.
- Extended the shared-flow/attachment-flow guard so both paths must keep the
  coverage evidence tokens aligned.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --plain-name "accepted shared flow clears interrupted native recovery after attach" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is teaching
  `ReceiptOcrSourceHandoffSummary` to count the new receipt coverage evidence
  tokens so parser/diagnostics can distinguish true bottom-section continuation
  from softer coverage review.

### Receipt Camera Reopen Pass 1035: OCR Coverage Evidence Counts

Status: complete.

What changed:
- Added `coverageSignalCounts` to `ReceiptOcrSourceHandoffSummary` and threaded
  it through `ReceiptOcrDiagnostics` as `ocrSourceCoverageSignalCounts`.
- Coverage evidence tokens now influence
  `hasMissingBottomEdgeAndTotalsEvidence`, so the OCR/parser route can recognize
  the combined bottom-edge plus subtotal/total-missing case from coverage
  signals as well as continuation signals.
- Added the coverage signal bucket to the privacy-safe OCR source handoff
  contract and receipt totals coverage diagnostics.
- Extended OCR regression coverage for normal accepted handoff signals and the
  strong missing-bottom/ghost-guide route without storing receipt text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr result carries accepted photo handoff signals without receipt content" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is surfacing
  `ocrSourceCoverageSignalCounts` into expense entry telemetry metadata so the
  accepted-photo and attachment-read paths expose the same privacy-safe coverage
  health for local diagnostics and later Command One.

### Receipt Camera Reopen Pass 1036: Expense OCR Coverage Telemetry Metadata

Status: complete.

What changed:
- Added `ocrSourceCoverageSignalCounts` to the shared OCR completion metadata
  helper used by the expense receipt entry screen.
- The accepted-photo OCR completion path and the attached-receipt scan path now
  expose the same privacy-safe coverage signal counts through existing
  completion telemetry metadata.
- Extended the assisted receipt flow guard so this coverage count map remains
  present beside the existing missing-bottom/totals route fields.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is threading coverage
  signal counts into expense parse diagnostics so the parsed receipt review can
  distinguish camera coverage failures from parser failures.

### Receipt Camera Reopen Pass 1037: Parse Diagnostics Coverage Handoff

Status: complete.

What changed:
- Added `ocrSourceCoverageSignalCounts` to `ExpenseReceiptParseDiagnostics`.
- Added helpers for parser-side coverage checks, including
  `hasOcrSourceCoverageSignals` and
  `hasOcrSourceMissingBottomCoverageEvidence`.
- Threaded `ReceiptOcrDiagnostics.ocrSourceCoverageSignalCounts` through
  `parseExpenseReceiptOcrResult` so parsed receipt review can distinguish
  camera coverage failures from parser failures.
- Extended the OCR parser-ready receipt regression to prove parsed diagnostics
  retain bottom-edge plus subtotal/total-missing coverage evidence.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is surfacing parser-side
  coverage evidence in the receipt parse review UI copy/metadata so users see
  a camera coverage problem as "add/check receipt section" instead of a generic
  parser failure.

### Receipt Camera Reopen Pass 1038: Parser-Side Coverage Review Surface

Status: complete.

What changed:
- Added parser-side coverage review getters to
  `ExpenseReceiptParseDiagnostics`, including a stable review code, user-facing
  label, action label, and instruction for the bottom-edge plus subtotal/total
  missing case.
- Updated the assisted receipt review intro so parser-carried coverage evidence
  can trigger the same bottom-section alert even when the direct OCR diagnostics
  object is not the only source of truth.
- The review chip row now includes a compact coverage chip, and the missing
  bottom action can use the parser-side "add next receipt section" wording.
- Extended the assisted receipt flow guard to keep this behavior wired to the
  long-receipt ghost-overlap contract.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is hardening the capture
  review route so accepting a receipt photo always leads into the filled
  receipt review when app assistance is enabled, with add-next-section as the
  clear path for missing bottom/totals evidence.

### Receipt Camera Reopen Pass 1039: Accepted Photo Handoff Contract

Status: complete.

What changed:
- Added `acceptedPhotoHandoffProcessingLabel` to the shared
  `ReceiptPhotoReviewResult` handoff contract.
- The accepted-photo metadata now carries an explicit processing label stating
  that Next reads the clearest OCR source first, keeps the smaller saved proof
  copy, and opens the filled receipt review.
- The reviewed-photo read status now uses that shared processing label instead
  of repeating a near-duplicate sentence in the import action.
- Extended the assisted receipt flow guard to keep the Next-to-filled-review
  contract, processing metadata, and status copy wired together.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the
  user-facing receipt photo review controls around Next/Add Next Section so the
  user is never left guessing whether they should add another receipt section
  or proceed to filled receipt details.

### Receipt Camera Reopen Pass 1040: Clearer Add-Section Control Labels

Status: complete.

What changed:
- Replaced the ambiguous compact "Add Bottom" label with "Add Bottom Section"
  in the receipt photo preview primary row and recovery strip.
- Kept "Add Next Section" for normal long-receipt continuation and "Next:
  Review Receipt Details" for proceeding into the filled receipt review.
- Extended the assisted receipt flow guard to read the preview controls part
  file directly and protect the clearer add-bottom-section wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is reviewing the photo
  preview tray layout constraints so the clearer labels do not overflow or hide
  the receipt preview on smaller phones.

### Receipt Camera Reopen Pass 1041: Preview Tray Overflow Guardrails

Status: complete.

What changed:
- Added compact-aware max-width constraints to the primary preview row action
  buttons so longer labels like "Add Bottom Section" cannot force the tray to
  grow wider than the available preview surface.
- Capped and flexed the recovery strip buttons so Retake, Crop, and Add Bottom
  Section can share the row without pushing the receipt image out of view.
- Added tooltips to mini recovery buttons so a shortened visual label still has
  a complete accessible action name.
- Extended the assisted receipt flow guard to protect the max-width controls and
  full-label tooltip behavior.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is strengthening the
  coverage decision copy so the user sees why bottom-edge and subtotal/total
  evidence means "add another section" before OCR review.

### Receipt Camera Reopen Pass 1042: Bottom/Totals Evidence Rationale

Status: complete.

What changed:
- Updated the missing-bottom coverage guidance to explain the two independent
  checks: the bottom edge was not detected and subtotal/total text was not
  found.
- Added `evidenceRationaleCode` and `evidenceRationaleLabel` to
  `ReceiptPhotoCoverageDecision` so UI, telemetry, and later diagnostics can
  distinguish the two-signal bottom/totals case from generic visual review.
- Extended the privacy-safe evidence contract with the rationale code.
- Hardened the coverage regression test so the ghost-overlap recommendation is
  tied to both edge evidence and word evidence.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "detected totals avoid long receipt prompt when bottom is present" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is carrying the new
  evidence rationale code into the document-signal list used by shared capture
  and attachment paths.

### Receipt Camera Reopen Pass 1043: Coverage Rationale Signal Propagation

Status: complete.

What changed:
- Added `receipt_coverage_rationale_*` document signals to the shared
  `ReceiptCaptureFlow` OCR-source handoff path.
- Added the same rationale signal to the attachment import path so the native
  receipt camera review and imported/reviewed photo path stay consistent.
- Extended the shared capture flow guard to require both the rationale signal
  prefix and `decision.evidenceRationaleCode`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --plain-name "accepted shared flow clears interrupted native recovery after attach" -r compact`
- `flutter test test/receipt_camera_result_test.dart --plain-name "missing bottom edge and totals recommends next receipt section" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making OCR diagnostics
  count the new coverage rationale signals so parser review can report not only
  the decision, but why that decision was made.

### Receipt Camera Reopen Pass 1044: OCR Coverage Rationale Counts

Status: complete.

What changed:
- Taught `ReceiptOcrSourceHandoffSummary` that the
  `receipt_coverage_rationale_edge_missing_and_totals_text_missing` signal is
  bottom-coverage evidence, not just passive metadata.
- Taught expense parse diagnostics to treat that same rationale signal as
  missing-bottom coverage evidence so parser review can keep the capture
  decision, OCR handoff, and expense review in agreement.
- Extended OCR and parser tests so the bottom-edge plus subtotal/total
  rationale is counted in the privacy-safe coverage signal maps.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics combines missing totals with bottom coverage risk" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --plain-name "parses expense fields from OCR parser-ready receipt signals" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/data/expense_receipt_parse_models.dart test/receipt_ocr_service_test.dart test/expense_receipt_parser_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the review flow
  use this evidence to keep the user in the long-receipt capture path when both
  the receipt bottom and subtotal/total text are missing, instead of acting like
  the photo is ready to become a final expense.
