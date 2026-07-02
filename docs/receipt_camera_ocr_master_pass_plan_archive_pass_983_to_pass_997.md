# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 983: Bottom Totals Telemetry Buckets

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 983: Bottom Totals Telemetry Buckets

Status: complete.

What changed:
- Receipt photo review telemetry now records privacy-safe bottom-edge status and
  detected buckets.
- Telemetry now records subtotal, total, total-amount, and totals-evidence
  status buckets so the combined missing-bottom/missing-total rule can be
  diagnosed without storing receipt text.
- Section-order counts and outcomes now flow into the same OCR-start telemetry,
  letting health dashboards distinguish top-to-bottom numbered sections from
  generic multi-photo receipts.
- Updated assisted-review guards so the expense flow keeps those diagnostic
  buckets connected alongside the existing missing-total recovery labels.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the capture
  path that launches the next section with the prior bottom overlap ghost guide,
  so Add Bottom Section/Add Next Section reliably starts the camera with the
  previous section guide.

### Receipt Camera Reopen Pass 984: Add Bottom Section Ghost Guide Copy

Status: complete.

What changed:
- The long-receipt alignment sheet now uses bottom-section language when the
  reason is `missing_bottom_edge_and_totals`.
- The sheet title now distinguishes `Add Bottom Receipt Section` from the normal
  `Add Next Receipt Section` path.
- The sheet body now reuses the decision's completion message, then adds the
  overlap instruction to repeat 3-5 readable lines.
- The primary camera action uses the decision's section button label, so the
  same reason drives both the completion dialog and ghost-guide launch sheet.
- Updated the ghost-guide source guard so this path cannot quietly regress to
  generic additional-photo copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --plain-name "add another photo carries partial receipt reason to ghost guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is verifying native camera
  session arguments preserve the previous-section reason/guidance for
  bottom-missing flows on both Android and iOS bridge tests.

### Receipt Camera Reopen Pass 985: Native Bottom Section Reason Parity

Status: complete.

What changed:
- Native camera session config now exposes
  `previousSectionGuideMissingBottomAndTotals` when the previous section reason
  is `missing_bottom_edge_and_totals`.
- The platform-channel payload now sends
  `previousSectionMissingBottomAndTotals` with the previous section guide.
- Android CameraX diagnostics now echo
  `previousSectionMissingBottomAndTotals`.
- iOS AVFoundation diagnostics now mirror the same key.
- Native contract tests now use the exact bottom-edge plus missing totals reason
  instead of a generic possible-cutoff sample.
- Android and iOS bridge guards now require the missing-bottom/totals diagnostic
  key and reason string.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "session carries previous section guide only for long receipt flow" -r compact`
- `flutter test test/receipt_native_camera_contract_test.dart --plain-name "native service sends previous section guide through channel" -r compact`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is giving OCR/parser handoff
  a clear local reason when totals are missing after text extraction, so the
  parser review can separate missing-bottom recovery from ordinary low-confidence
  parsing.

### Receipt Camera Reopen Pass 986: OCR Missing Bottom Reason

Status: complete.

What changed:
- `ReceiptOcrDiagnostics` now exposes `receiptMayNeedBottomSection` when OCR
  found text but no subtotal/total/tax evidence.
- Added `receiptCompletionReviewReasonCode` so local OCR/parser handoff can
  distinguish `possible_missing_bottom_totals` from no-text and normal summary
  evidence.
- Added `receiptCompletionReviewActionLabel` for the local review UI/admin
  health path.
- The privacy-safe totals evidence diagnostics now include the bottom-section
  boolean, reason code, and action label.
- The assisted parser review now keys missing-bottom structure guidance from
  `receiptMayNeedBottomSection` instead of duplicating raw status checks.
- Updated OCR and assisted-review tests for the new reason/action contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics exposes receipt totals coverage evidence" -r compact`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr totals evidence can trigger missing bottom coverage decision" -r compact`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_ocr_service_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is flowing
  `receiptCompletionReviewReasonCode` into expense OCR telemetry and parser
  handoff metadata so Command One can group missing-bottom reads separately from
  ordinary parser misses.

### Receipt Camera Reopen Pass 987: OCR Completion Reason Handoff

Status: complete.

What changed:
- The expense entry screen now records privacy-safe OCR completion metadata from
  `ReceiptOcrDiagnostics`, including `receiptCompletionReviewReasonCode`,
  `receiptCompletionReviewActionLabel`, `receiptMayNeedBottomSection`, and
  totals/subtotal/tax candidate counts.
- The direct attachment OCR completion callback now uses
  `receiptMayNeedBottomSection` instead of a generic raw missing-totals check
  when setting the handoff stage/action.
- The main accepted-proof OCR path now includes the same reason metadata on
  `ocrCompleted`/`ocrFailed` telemetry and sets the bottom-check handoff when
  OCR found text but subtotal/total evidence still suggests the bottom section
  may be missing.
- Added source guards so the assisted review flow keeps the specific
  bottom-section reason/action handoff in both OCR paths.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the parser review
  consume the OCR completion reason as an explicit review banner/action, so the
  user sees "add the bottom section" only when the receipt structure warrants it
  and not as generic low-confidence clutter.

### Receipt Camera Reopen Pass 988: Missing Bottom Review Alert

Status: complete.

What changed:
- The app-assisted receipt review intro panel now shows a compact bottom-section
  alert when OCR found receipt text but no subtotal/total evidence.
- The alert explains the reason in user-facing terms: OCR found text, but did
  not find subtotal or total lines, so the user should add the next section if
  the photo was not the full receipt.
- The alert exposes the intended action label, `Add Next Receipt Section`,
  without adding a new blocking modal or covering the receipt proof.
- Added source guards for the exact alert title, reason copy, and action label.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is connecting this missing
  bottom review alert to the existing Add/Retake recovery action so the user can
  jump straight into the long-receipt continuation flow from the review screen.

### Receipt Camera Reopen Pass 989: Missing Bottom Review Action Wiring

Status: complete.

What changed:
- The app-assisted review intro panel now receives an
  `onAddMissingBottomSection` callback.
- The bottom-section alert's `Add Next Receipt Section` control now calls that
  callback instead of being passive text.
- The expense entry screen wires that callback to `_scrollToReceiptPhotoRecovery`,
  reusing the existing Add/Retake continuation path and keeping the filled
  receipt review below it.
- Added source guards so the bottom-section alert cannot lose its action wiring.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the recovery panel
  label/context adapt when OCR specifically thinks the receipt bottom is missing,
  so the Add/Retake section says "add the bottom section" instead of generic
  photo recovery.

### Receipt Camera Reopen Pass 990: Missing Bottom Recovery Panel Context

Status: complete.

What changed:
- `_ReceiptPhotoRecoveryPanel` now accepts `missingBottomSection`.
- When OCR says the receipt may need the bottom section, the collapsed recovery
  panel title changes to `Add bottom receipt section`.
- The recovery subtitle now explains that subtotal/total lines were not found
  and tells the user to add the lower section if the receipt continues.
- The expense entry screen passes
  `_lastOcrDiagnostics?.receiptMayNeedBottomSection == true` into that panel.
- Added source guards for the adaptive recovery panel title/subtitle and wiring.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is tightening the photo
  continuation handoff so the next capture receives bottom-section context and
  the ghost guide does not fall back to generic "another photo" language.

### Receipt Camera Reopen Pass 991: Missing Bottom Ghost Guide Handoff

Status: complete.

What changed:
- `SharedReceiptAttachmentPanel` now accepts optional
  `receiptContinuationReasonCode` and `receiptContinuationGuidance` values.
- The shared camera launch path passes those values into
  `ReceiptCaptureFlowOptions.previousSectionReasonCode` and
  `previousSectionGuidance`.
- When continuation context exists and previous receipt photos exist, the shared
  panel passes the last accepted receipt photo as
  `previousSectionGuidePhotoPath`, allowing the native camera flow to show the
  ghost guide for the next section.
- The expense receipt entry screen now passes
  `missing_bottom_edge_and_totals` plus bottom-section guidance when OCR found
  text but no subtotal/total evidence.
- Added source guards for the shared panel props, flow-option handoff, last-photo
  guide path, and expense-screen reason wiring.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart --plain-name "continuation guide" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is adding a focused flow
  test around the shared camera launch options so the previous-section guide
  cannot regress without relying only on string guards.

### Receipt Camera Reopen Pass 992: Tested Continuation Guide Options

Status: complete.

What changed:
- Added `ReceiptCaptureContinuationGuide`, a small reusable model that turns a
  continuation reason, guidance text, and previous receipt photos into
  `ReceiptCaptureFlowOptions` previous-section guide values.
- The model trims reason/guidance values, uses the last non-empty previous photo
  as the ghost-guide source, and stays inactive when no reason code is present.
- The shared attachment panel now uses `ReceiptCaptureContinuationGuide` instead
  of private one-off getters before launching `ReceiptCaptureFlow`.
- Added behavior tests proving missing-bottom context flows into options and
  blank reasons leave options untouched.
- Updated assisted-review guards to require the tested continuation guide path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is exposing missing-bottom
  continuation diagnostics in the native capture/open telemetry so Command One
  can show how often OCR-driven bottom-section recovery is used.

### Receipt Camera Reopen Pass 993: Missing Bottom Continuation Diagnostics

Status: complete.

What changed:
- `ReceiptCaptureFlow` now adds privacy-safe previous-section guide diagnostics
  to shared capture/open result diagnostics and per-photo review-opening
  diagnostics.
- Diagnostics include only safe facts: whether a previous-section guide was
  requested, whether a guide photo is available, the reason code, whether the
  reason is `missing_bottom_edge_and_totals`, whether guidance text exists, the
  coarse continuation source, and the ghost-guide readiness status.
- The diagnostics intentionally do not include receipt text, merchant names,
  prices, addresses, line details, or photo paths.
- Added shared-flow source guards for the continuation diagnostics and the
  `ocr_missing_bottom_totals` / `ready_with_previous_photo` buckets.

Validation:
- `flutter test test/receipt_capture_flow_shareability_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is propagating those
  continuation diagnostics into OCR source document signals so local OCR/parser
  handoff can tell whether a read came from an OCR-requested bottom-section
  continuation.

### Receipt Camera Reopen Pass 994: OCR Source Continuation Signals

Status: complete.

What changed:
- OCR source attachment records now carry privacy-safe continuation document
  signals when the source came from the missing-bottom receipt recovery path.
- Signals distinguish requested previous-section guidance, ghost-guide photo
  availability, `missing_bottom_edge_and_totals`, OCR missing subtotal/total
  context, guidance availability, continuation source, and ghost-guide status.
- OCR source risk flags now identify missing-bottom continuation reads that
  deserve review, the no-prior-photo edge case, and the ready ghost-guide path.
- The same signal/risk vocabulary is wired into both the shared capture-flow
  OCR source builder and the expense import-actions OCR source builder.
- Added source guards so this missing-bottom continuation context cannot be
  dropped before parser handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using these OCR source
  continuation signals to help the receipt details review explain when another
  section was added because the bottom totals were missing.

### Receipt Camera Reopen Pass 995: Combined Bottom Edge And Totals Decision

Status: complete.

What changed:
- `ReceiptOcrSourceHandoffSummary` now tracks privacy-safe continuation signal
  counts separately from general handoff and quality counts.
- The OCR source handoff summary now exposes
  `hasMissingBottomEdgeAndTotalsEvidence` when continuation/bottom coverage
  signals indicate the receipt bottom may be missing.
- `ReceiptOcrDiagnostics` now exposes
  `ocrSourceBottomCoverageRiskDetected` and
  `receiptMissingBottomEdgeAndTotals`.
- The receipt completion reason now returns
  `missing_bottom_edge_and_totals` only when OCR found text, subtotal/total/tax
  evidence is missing, and source/camera evidence indicates bottom coverage risk.
- The review action label for that combined case is now
  `Add the next receipt section`.
- Added an OCR service regression test for the combined word-detection and
  bottom-coverage decision.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --plain-name "ocr diagnostics" -r compact`
- `dart analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is making the receipt
  details review surface that combined reason cleanly when it exists, without
  adding another noisy camera control.

### Receipt Camera Reopen Pass 996: Combined Bottom Reason Review Wording

Status: complete.

What changed:
- The assisted receipt details review now distinguishes a generic missing totals
  warning from the stronger combined
  `receiptMissingBottomEdgeAndTotals` decision.
- When OCR/camera evidence says the bottom edge and subtotal/total lines were
  not found together, the review panel says so directly and tells the user to
  add the next section with overlap.
- OCR structure action chips now prioritize `Add next receipt section`,
  `Use overlap guide`, and `Review totals after OCR` for the combined case.
- The expense entry handoff stage now says `Receipt details need next section`
  for the combined decision.
- OCR completion metadata now includes the combined bottom/totals flag and the
  source bottom coverage risk flag.
- Added source guards for the combined review copy and handoff labels.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_ocr_service_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_ocr_service_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is ensuring the capture
  flow offers a clear add-next-section path when this combined review reason
  appears, without blocking a user who wants to continue manually.

### Receipt Camera Reopen Pass 997: Recovery Panel Overlap Guidance

Status: complete.

What changed:
- The receipt attachment launch no longer hard-codes
  `missing_bottom_edge_and_totals` for every missing-totals OCR result; it now
  passes `receiptCompletionReviewReasonCode`.
- Continuation guidance now distinguishes the true combined
  bottom-edge/totals case from the looser “totals missing, check bottom”
  situation.
- `_ReceiptPhotoRecoveryPanel` now receives
  `missingBottomEdgeAndTotals`.
- The collapsed recovery panel now shows `Add next section with overlap` plus
  explicit overlap guidance when both bottom edge and subtotal/total evidence
  are missing.
- Added source guards for the overlap-specific recovery copy and diagnostics
  wiring.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --plain-name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `dart analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is testing the generic
  missing-totals path separately from the combined bottom-edge/totals path so
  neither path over-promises edge detection.
