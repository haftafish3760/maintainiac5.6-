# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 189: OCR Source Recovery Action Drilldown Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 189: OCR Source Recovery Action Drilldown Batch

Status: completed.

Goal:
- Make app-assisted OCR recovery guidance more specific for the receipt source
  type without collecting or exposing private receipt content.

Completed:
- Replaced the loose failure/recovery strings with `_ReceiptReadRecoveryAdvice`
  so each OCR failure has a source-specific lead, a full on-screen recovery
  action, and a shorter returned warning.
- Added separate recovery guidance for single receipt photos, multi-photo/long
  receipts, PDF-only proofs, saved receipt text, mixed proof sources, and
  unknown proof states.
- Multi-photo failures now tell the user to check photo order and add a clearer
  missing section instead of giving the same generic retake advice as a single
  photo.
- Single-photo failures now mention brighter light, full receipt framing, and
  adding another photo for long receipts.
- PDF/text/mixed-source failures now steer users toward the best next proof
  source while still allowing manual continuation.
- Updated receipt-flow regression guards for the recovery-advice object,
  source-specific action copy, and short-action handoff.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

### Receipt Camera Reopen Pass 188: OCR Source Failure Specificity Batch

Status: completed.

Goal:
- Make OCR read failures explain which kind of receipt source failed and what
  broad recovery path applies, without exposing private receipt content.

Completed:
- Added `_receiptReadFailureLead` for photo-only, PDF-only, saved-text-only,
  mixed-source, and unknown-source read failures.
- Prefixed OCR exceptions and no-text OCR failures with source-specific plain
  language before the recovery action.
- Kept recovery actions source-specific and privacy-safe: keep proof attached,
  add a clearer receipt photo, retake, paste cleaner text, or enter manually.
- Updated focused regression guards so the receipt flow no longer protects the
  older vague failure wording.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

### Receipt Camera Reopen Pass 187: OCR Source Readability Handoff Batch

Status: completed.

Goal:
- Carry photo quality/readability evidence into the OCR handoff status so the
  user understands what the app is reading without exposing private receipt
  content.

Completed:
- Added a privacy-safe OCR source quality summary to the post-review read
  status message.
- The status now distinguishes unmeasured photo quality, readable OCR source
  quality, and OCR sources that may need review.
- For stitched long receipts that become one OCR image, the quality summary uses
  the weakest source-section quality as the handoff warning.
- Kept the handoff message limited to proof count, OCR source count, quality
  score/issue, and stitch decision; no receipt text, vendor, address, total, or
  image content is surfaced.
- Added focused regression coverage for the new quality handoff helper and
  status message shape.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Note:
- A broader `test/receipt_ocr_service_test.dart` run still has an unrelated PDF
  expectation failure around PDF overflow wording. Pass 187 did not modify PDF
  OCR service behavior.

### Receipt Camera Reopen Pass 186: Camera Exposure Evidence Summary Batch

Status: completed.

Goal:
- Make camera capture diagnostics explain brightness/exposure behavior without
  storing private receipt content.

Completed:
- Added `hasUnderexposedLiveFrame` to capture evidence so diagnostics can
  distinguish truly dark previews from previews that are merely darker than
  ideal.
- Added `Live preview was darker than ideal` to the brightness summary.
- Added `exposureSummaryLabel` so evidence can say whether the selected shot
  used native auto-exposure baseline or a bracketed exposure candidate.
- Added model tests for dark, underexposed, native-baseline, and bracketed
  exposure summaries.
- Added string contract coverage so the camera evidence surface keeps these
  privacy-safe diagnostics.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 185: Camera Brightness Recovery Copy Batch

Status: completed.

Goal:
- Align live camera guidance, assisted capture feedback, and review guidance so
  dim-but-usable receipt photos are handled differently from truly too-dark
  photos.

Completed:
- Added a live camera status label for underexposed receipt frames:
  `Brighter helps`.
- Added live feedback that says the receipt is readable but brighter light will
  help bottom text.
- Added assisted-capture feedback titled `Could Be Brighter` for photos that
  may work but need better light for lower receipt lines.
- Kept hard `Too Dark` guidance separate for genuinely dark photos.
- Added focused regression coverage for the new live, assisted, and review copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 184: Camera Capture Brightness Comparison Batch

Status: completed.

Goal:
- Make the receipt camera detect and prefer against app-captured photos that are
  darker than ideal, even when they are not dark enough to be a hard blocker.

Completed:
- Added an `isUnderexposedForReceipt` quality band below the existing hard
  `isTooDark` blocker.
- Added review guidance that tells the user a receipt is readable but darker
  than ideal and calls out dim bottom text.
- Kept blur/sharpness priority above the new underexposed warning so a blurry
  photo is not mislabeled as only a brightness issue.
- Added the same underexposed signal to live camera analysis.
- Updated best-shot candidate ordering so an underexposed receipt candidate
  loses to a similarly readable, better-lit candidate before pixel count can
  decide.
- Updated exposure bracketing so slightly underexposed live frames can trigger
  a bounded positive exposure candidate.
- Added focused regression coverage for the threshold, ranking signal,
  guidance, and exposure-bracket trigger.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 183: Camera And Review Exit Hardening Batch

Status: completed.

Goal:
- Make the receipt review back/exit path behave like a normal professional app
  instead of trapping the user while receipt photos are being prepared.

Completed:
- Changed photo review exit so it no longer blocks Back/Close with a
  "leave after this finishes" message while `_savingPhotos` is true.
- Stopped the review save state before closing when the user backs out during
  receipt photo preparation.
- Preserved the crop safety guard so the user must finish or cancel crop before
  leaving an active crop operation.
- Kept the existing async save safety model: save work already checks
  `_closingReview` and returns without handing off stale results.
- Updated regression coverage to prove the old blocking message is gone and
  save state is stopped before review close.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 182: Receipt Review Action Label Polish Batch

Status: completed.

Goal:
- Keep compact receipt-review actions short enough for phone screens while
  avoiding vague/developer-style labels.

Completed:
- Changed compact long-receipt `Add Next` to `Add Section` so the action maps
  to the next receipt section.
- Changed compact long-receipt `Arrange` to `Order` so the user knows it opens
  photo ordering.
- Changed compact proof-size actions from `Save Size` / `Save Space` to
  `Proof Size`, matching the saved proof image concept used elsewhere.
- Kept the full long-receipt rail labels unchanged where there is room:
  `Add Next Photo`, `Photo Order`, `Match Photos`, and `Saved Proof Size`.
- Updated focused label contract coverage.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 181: Receipt Review Multi-Photo Density Guard Batch

Status: completed.

Goal:
- Keep long-receipt/multi-photo review usable on tight screens without stacking
  thumbnails and the full action rail into a cramped control panel.

Completed:
- Added a compact multi-photo action row for tight bottom-control constraints.
- Kept the compact row focused on the essential multi-photo actions:
  `Add Next`, `Arrange`, `Match`, and `Save Size`.
- Kept the full multi-photo action rail available when there is enough room.
- Preserved the thumbnail strip, with compact height already guarded by Pass 180.
- Added focused regression coverage proving compact and full multi-photo action
  paths are separate.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 180: Receipt Review Bottom Sheet Overflow Guard Batch

Status: completed.

Goal:
- Keep the post-capture review controls from becoming an overflowing mini-screen
  on shorter phones while preserving the recovery actions users need.

Completed:
- Added a `LayoutBuilder`-based compact-control guard for the preview tray.
- Limited the preview status text to one line when the bottom-control height is
  tight.
- Collapsed the quality-warning strip by hiding its detail text in compact
  mode, while keeping `Retake`, `Adjust`, and `Add Photo` visible.
- Reduced multi-photo thumbnail strip height under compact constraints.
- Added focused regression checks for the compact threshold, compact status
  text, thumbnail height guard, and compact warning-strip behavior.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 179: Receipt Review Quality Warning Action Batch

Status: completed.

Goal:
- Make questionable one-photo review states actionable without forcing the user
  to hunt through menus or accept a weak photo.

Completed:
- Added `Add Photo` directly to the photo-quality recovery strip so the user can
  add another receipt section when a photo is blurry, dark, glary, or incomplete.
- Renamed the quality recovery crop action to `Adjust` so it covers crop,
  straighten, and rotation more plainly.
- Kept `Retake`, `Adjust`, and `Add Photo` available inside the warning state
  without showing the full long-receipt action rail.
- Disabled the new add-photo recovery action while the camera is already
  opening, matching the existing retake guard.
- Added focused regression coverage that proves warning recovery exposes the
  add-photo action and does not fall back to ambiguous conditional labels.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 178: Receipt Review Single-Photo Action Density Batch

Status: completed.

Goal:
- Make one-photo receipt review feel like a focused camera workflow instead of
  a long-receipt batch manager.

Completed:
- Split single-photo preview actions away from the long-receipt action rail.
- Added a dedicated single-photo action row with compact labeled actions:
  `Add Photo`, `Retake`, `Adjust`, and `Save Space`.
- Kept long-receipt photo order, matching, and add-next-photo controls scoped to
  multi-photo review only.
- Kept quality-warning recovery focused on retake/crop help instead of stacking
  the full action rail underneath it.
- Reduced the single-photo preview control cap from 112 pixels to 108 pixels so
  the receipt image stays more visible.
- Added focused regression coverage for the single-photo action row and the
  long-receipt-only action rail split.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 177: Receipt Review Preview Footprint Batch

Status: completed.

Goal:
- Keep the receipt photo dominant after capture by reducing the bottom-control
  footprint and removing fake chooser UI when there is only one receipt photo.

Completed:
- Reduced the review bottom-control cap from 20% to 18% of screen height.
- Lowered absolute control-height caps for preview, crop, photo order,
  stitching, and data-saver modes.
- Reduced receipt-image bottom padding from controls plus 8 pixels to controls
  plus 4 pixels.
- Reused the calculated image padding for stitch pair previews instead of a
  hard-coded 154-pixel inset.
- Removed the one-photo thumbnail strip from preview mode because one photo has
  nothing to choose.
- Kept thumbnails available for multi-photo long receipts, where they actually
  help the user understand order and sections.
- Removed the unused compact thumbnail branch so the review controls have one
  simpler multi-photo layout path.

Verification:
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 176: Receipt Review Long-Receipt Control Layout Batch

Status: completed.

Goal:
- Make multi-photo/long-receipt review controls read like a professional
  receipt flow instead of generic tooling, while keeping the bottom controls
  compact.

Completed:
- Updated multi-photo preview copy so it reminds the user that Photo 1 should
  be the top of the receipt and the next photo should be the next section.
- Changed ambiguous `Order` and `Match` labels to `Photo Order` and
  `Match Photos`.
- Changed tool-mode add-photo copy to `Add Next Section` for long receipts.
- Made stitch pair navigation say `Previous Pair` / `Next Pair` and show the
  actual photo pair being matched.
- Changed stitch success/fallback labels to `Combined Receipt Ready` and
  `Safe Fallback Ready`.
- Added order-mode copy that says Next reads photos in the displayed order.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 175: Capture Brightness And Exit Regression Batch

Status: completed.

Goal:
- Reduce camera preview/capture lifecycle races by making async capture work
  stop when the route is closing or when the active camera controller has been
  cleared/swapped.

Completed:
- Added an active-controller guard that requires the widget to still be
  mounted, the camera not to be closing, the same controller instance to still
  be active, and the controller to still be initialized.
- Guarded manual and assisted capture loops before/after focus, exposure,
  shot gaps, and result handoff.
- Prevented `_takeReceiptPhoto` from running when the camera is already
  closing.
- Kept exposure restoration best-effort only while the same controller is
  active.
- Added a focused regression guard proving the capture pipeline checks the
  active controller identity before continuing.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`

### Receipt Camera Reopen Pass 174: OCR Summary Privacy Regression Batch

Status: completed.

Goal:
- Prove Command 1-safe OCR summaries cannot leak raw receipt content, vendor
  text, customer text, phone numbers, addresses, totals, invoice numbers, or
  local proof paths even if OCR warning copy is constructed incorrectly.

Completed:
- Hardened `ExpenseReceiptOcrReview.commandCenterSummary` so the admin-facing
  summary uses safe issue/action text when warning labels or instructions look
  private.
- Added safe fallback labels and actions for known OCR warning kinds so Command
  1 still gets useful failure direction without exposing receipt content.
- Added a `privacyScope` marker to the OCR summary payload.
- Added a regression test that injects private store/address/phone/path/amount
  text into OCR warning fields and proves the Command 1 summary does not echo it.

Verification:
- `dart format lib/screens/expenses/data/expense_receipt_ocr_review.dart test/expense_draft_store_test.dart`

### Receipt Camera Reopen Pass 173: OCR Summary Recovery Contract Batch

Status: completed.

Goal:
- Make sure OCR Command 1 summary metadata survives interruption/recovery
  paths, not just the first happy-path receipt scan.

Completed:
- Added draft recovery coverage proving OCR source survives save/load and is
  present in the Command 1 summary.
- Added saved ledger coverage proving source-skipped OCR review data keeps the
  source and action after receipt save/load.
- Updated the Command 1 summary contract test to include the safe OCR source.

Verification:
- `flutter test test/expense_draft_store_test.dart test/expense_ledger_store_test.dart test/expense_screen_telemetry_test.dart test/expense_ocr_failure_diagnostics_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_ocr_review.dart test/expense_draft_store_test.dart test/expense_ledger_store_test.dart`
- `git diff --check`

Known external blocker:
- The full broad receipt/expense sweep remains blocked by unrelated missing
  work-supplies generated catalog files.

Next camera-only focus:
- Add privacy regression checks across OCR summaries to prove raw OCR, receipt
  totals/text, vendor/customer text, and local proof paths do not leak into
  Command 1-safe summary payloads.
