# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 307 / Total Pass 387: Native Back During Capture Handoff Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 307 / Total Pass 387: Native Back During Capture Handoff Batch

Status: complete.

What changed:
- Fixed Android CameraX back/close behavior during an active receipt capture so
  Back no longer marks the camera as fully closing before the in-flight photo
  can finish saving.
- Fixed iOS AVFoundation back/close behavior the same way so both native camera
  bridges preserve an in-flight manual photo instead of aborting the capture
  prep path.
- Added a shared no-photo cancel helper per platform so back/no-photo,
  done/no-photo, and capture-failed-after-back exits produce one clear
  diagnostic reason.
- Added a specific `back_capture_failed_cancel` reason when the user presses
  Back during capture and the native camera fails to save the photo anyway.
- Added source guards proving the in-flight back branch runs before the normal
  `closingCamera = true` path on both Android and iOS.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Run targeted bridge tests/analyzer, then continue with native capture review
  layout and capture-to-parsed-receipt handoff before PDF work.

### Receipt Camera Reopen Pass 308 / Total Pass 388: Review Next Destination Copy Batch

Status: complete.

What changed:
- Changed the normal single-photo review primary action from plain `Next` to
  `Next: Review` so the user can tell the next step is reviewing receipt
  details, not silently saving or returning to the form.
- Reworded single-photo and multi-photo review status copy so it states that
  `Next: Review` opens item prices and business/personal use.
- Kept critical-photo behavior as `Next Anyway` and multi-photo order behavior
  as `Check Match` so warning and long-receipt flows remain explicit.
- Updated source guards for camera help, capture layout, and assisted receipt
  handoff copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Validate the review-copy tests, then continue with capture-to-parsed-receipt
  handoff and review layout hardening before PDF work.

### Receipt Camera Reopen Pass 309 / Total Pass 389: Receipt Reader Stage Handoff Batch

Status: complete.

What changed:
- Added a receipt-read handoff stage label so the expense receipt screen can
  distinguish preparing saved photo, reading receipt text, filling receipt
  review, review ready, and manual-review states.
- Wired the handoff stage through the visible `Reading Receipt Details` panel
  so the user is not left wondering whether the app is reading OCR, parsing, or
  opening the filled review.
- Updated OCR start, reviewed-photo accept, parser start, parser success, and
  parser/manual-review failure paths to set plain user-facing stage text.
- Kept the stage content privacy-safe and content-free: no merchant, line item,
  total, address, or receipt text is logged or shown in the handoff status.
- Added source guards for the stage state and parser transitions.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Validate receipt entry/parser handoff, then continue tightening the review
  layout and photo-to-parsed-lines path before PDF work.

### Receipt Camera Reopen Pass 310 / Total Pass 390: Readable Coverage Warning Softening Batch

Status: complete.

What changed:
- Softened post-capture receipt coverage warnings when native framing reports a
  possible cutoff but saved-photo quality says the receipt is readable and edge
  coverage is strong.
- Added `native_cut_off_readable_check` so the app tells the user to check the
  top and bottom instead of forcing an add-another-photo warning on an otherwise
  readable receipt.
- Preserved the hard `native_cut_off_risk` path for weak, low-quality, or
  low-edge-coverage photos where another photo/crop is still the right advice.
- Updated quality and native contract tests so readable photos do not get
  blocked by overconfident native edge signals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Validate coverage warning behavior, then continue with post-capture review
  layout and native image-quality parity before PDF work.

### Receipt Camera Reopen Pass 311 / Total Pass 391: Receipt Still Capture Sharpness Defaults Batch

Status: complete.

What changed:
- Changed Android CameraX still capture away from an always-maximize-quality
  setting into receipt-first fast/sharp capture modes.
- Flagship Android devices use zero-shutter-lag where available; other tiers
  use minimize-latency with high JPEG quality to reduce handheld blur.
- Changed iOS AVFoundation still capture priority to balanced on non-flagship
  tiers while preserving quality priority for flagship devices.
- Added still-capture mode diagnostics on Android and iOS so camera health can
  explain which capture path produced a dark or blurry receipt.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Validate native capture sharpness guards, then continue with post-capture
  review layout and native image-quality parity before PDF work.

### Receipt Camera Reopen Pass 312 / Total Pass 392: Saved Photo Bottom-Band Diagnostics Batch

Status: complete.

What changed:
- Added Android saved-photo top, middle, and bottom luma diagnostics plus
  bottom edge-score diagnostics.
- Added matching iOS saved-photo vertical-band diagnostics.
- Added `latestCapturedVerticalQualitySignal` so the app can distinguish a
  bottom section that is too dark, softer than the rest, darker than the upper
  receipt, or evenly readable.
- Surfaced bottom-section review warnings in Flutter so the user is told to
  zoom into the bottom lines, retake, or raise Brightness instead of getting a
  vague whole-photo score.
- Added safe diagnostic-key forwarding and source guards for the native bridge,
  staging sanitizer, and review-warning model.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_quality_guidance_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_quality_guidance_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Validate saved-photo vertical diagnostics, then continue with native review
  layout and image-quality parity before PDF work.

### Receipt Camera Lane Boundary / Inventory Lockout

Status: active.

Scope rule:
- This thread owns the shared receipt camera, OCR, image cleanup, review, and
  receipt-capture engine.
- Do not edit `lib/screens/work_supplies`, inventory screens, inventory parser
  files, or materials-specific intake flows while inventory/materials work is
  being handled separately.
- Shared receipt-camera infrastructure under
  `lib/shared/widgets/receipt_capture` should remain module-neutral so
  expenses, materials, maintenance, and future app sections can import it.
- Do not wire new behavior into materials/inventory from this thread unless the
  lane is explicitly reopened.

Next camera/OCR focus:
- Keep the receipt camera reusable at the shared infrastructure level.
- Validate the engine through the existing expense receipt flow first.
- Continue native capture/review/OCR hardening before PDF work.

### Receipt Camera Reopen Pass 313 / Total Pass 393: Shared Camera OCR Facade Batch

Status: complete.

What changed:
- Added `ReceiptCaptureFlow` as a module-neutral shared facade for receipt
  camera capture, native staging, photo review, and OCR handoff.
- Exported the facade through
  `lib/shared/widgets/receipt_capture/receipt_capture.dart` so future app
  sections can import the receipt engine from one stable barrel.
- Added module labels for expenses, materials/inventory, maintenance/repairs,
  and shared usage without wiring this pass into inventory screens.
- Added `captureAndReview`, `captureReviewAndReadText`,
  `readTextFromReviewResult`, and `attachmentsFromReviewResult` so the engine
  can be reused without copying expense attachment internals.
- Added a source guard test proving the facade uses shared native camera,
  review, and OCR services without importing expenses, work supplies, or
  maintenance screens.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart lib/shared/widgets/receipt_capture/receipt_capture.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Keep hardening the native camera/review path while preserving this shared
  import boundary.
- Continue validating through the expense receipt flow before wiring new
  modules into the facade.

### Receipt Camera Reopen Pass 314 / Total Pass 394: Shared Facade Expense Route Batch

Status: complete.

What changed:
- Routed `SharedReceiptAttachmentPanel` native receipt capture through
  `ReceiptCaptureFlow` instead of duplicating permission, native camera,
  staging, and review setup inside the panel.
- Preserved the existing attachment state, photo ID retention, review accepted
  callback, OCR read status, and temporary OCR-source cleanup after the shared
  flow returns an accepted review result.
- Extended `ReceiptCaptureFlowOptions` so existing photos and existing quality
  checks can be passed into shared review without losing prior receipt sections.
- Kept the shared camera/OCR facade module-neutral and did not wire this pass
  into inventory/work-supplies screens.
- Removed stale native camera permission/service imports and the old duplicated
  native-capability helper from the panel path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue hardening the shared capture/review engine itself: review result
  continuity, photo recovery, and native image-quality parity before PDF work.

### Receipt Camera Reopen Pass 315 / Total Pass 395: Accepted Photo Module Metadata Batch

Status: complete.

What changed:
- Audited native capture recovery and confirmed CameraX/AVFoundation captures
  are staged to device storage and indexed in Hive before review.
- Added privacy-safe source metadata to accepted receipt photo attachments so
  downstream screens can tell the proof came from the Maintainiac receipt camera
  review flow.
- Added module metadata for expenses, materials/inventory, and
  maintenance/repairs on accepted receipt photo records without wiring new
  behavior into inventory screens.
- Added a source guard so accepted camera photos do not regress back to
  anonymous attachment records.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue interruption safety and native image-quality parity: accepted photo
  recovery should remain local-first and explainable without uploading private
  receipt content.

### Receipt Camera Reopen Pass 316 / Total Pass 396: Accepted Recovery Manifest Cleanup Batch

Status: complete.

What changed:
- Added `clearRecoveryManifestPath` to `ReceiptNativeCaptureStaging` so accepted
  native camera sessions can remove only recovery manifest/index records while
  leaving attached staged receipt photo files intact.
- Added `recoveryManifestPath` to `ReceiptCaptureFlowResult` and passed the
  staged native recovery manifest path through accepted shared camera results.
- Updated the receipt attachment native-camera path to clear the interrupted
  recovery manifest/index only after `_acceptReviewedPhotoResult` publishes the
  accepted attachment state.
- Added regression tests proving accepted recovery cleanup keeps the attached
  photo file, removes the manifest, removes the Hive recovery index, and happens
  after accepted review attachment handling.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_native_capture_staging_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_native_capture_staging_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue native image-quality parity and review recovery: the camera should
  keep accepted photos local-first while avoiding stale interrupted-capture
  banners after a successful review.

### Receipt Camera Reopen Pass 317 / Total Pass 397: Accepted Photo Diagnostic Metadata Batch

Status: complete.

What changed:
- Preserved native capture diagnostics by accepted receipt photo path inside
  `SharedReceiptAttachmentPanel` after camera review and after later photo
  review edits.
- Added privacy-safe `documentSignals` to accepted receipt photo attachments for
  camera review source, linked module, data saver level, quality score bucket,
  light/focus/framing state, native readability/framing/perspective/exposure
  signals, coverage status, and saved-photo warning action/severity.
- Added privacy-safe `riskFlags` to accepted receipt photo attachments for
  dark photos, glare risk, soft/blurry photos, possible partial receipt,
  low-resolution receipt text, low contrast, weak receipt lines, native saved
  photo warnings, and add-more-photos recommendations.
- Kept the metadata content-free: no receipt text, vendor names, customer names,
  addresses, phone numbers, notes, or item descriptions are stored in these
  diagnostic fields.
- Did not wire anything into inventory/work-supplies or maintenance screens.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera-first hardening: turn these accepted-photo signals into
  stronger review decisions and OCR handoff behavior before any PDF work.

### Receipt Camera Reopen Pass 318 / Total Pass 398: OCR Source Handoff Guard Batch

Status: complete.

What changed:
- Hardened the app-assisted receipt read path so temporary OCR attachments are
  explicitly built from `ReceiptPhotoReviewResult.ocrSourcePhotoPaths`, not the
  saved backup proof photo paths.
- Labeled OCR source attachments as staged `Maintainiac OCR source photo`
  records, separate from permanent backup receipt proof records.
- Added document signals that state OCR reads the prepared OCR source instead
  of the saved backup proof, plus scanner decision, stitch/fallback, module,
  and data saver signals.
- Added OCR-source risk flags for retake risk, review-needed risk, dark/soft
  source risk, possible cutoff, and stitch fallback.
- Applied the same OCR source labeling/signaling to the module-neutral
  `ReceiptCaptureFlow` facade so future callers do not bypass the rule.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera-first hardening by using these source/proof distinctions to
  improve the post-capture user flow and OCR review handoff before PDF work.

### Receipt Camera Reopen Pass 319 / Total Pass 399: Post-Capture Action Label Clarity Batch

Status: complete.

What changed:
- Audited post-capture receipt review labels for confusing "read receipt" style
  wording.
- Confirmed the main photo review flow uses Next/review language that explains
  the next user-visible screen: item prices and business/personal review.
- Renamed the multi-photo non-stitch action from `Check Match` to
  `Check Photo Match` so long-receipt users know it is about matching receipt
  photo sections, not saving or reading the receipt.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue camera-first hardening on the actual post-capture flow: after Next,
  the user should land in the filled receipt details review when app assistance
  is enabled, with clear fallback when OCR cannot read enough text.

### Receipt Camera Reopen Pass 320 / Total Pass 400: Filled Review Handoff Stage Batch

Status: complete.

What changed:
- Tightened the app-assisted receipt handoff stage after OCR/parser completion
  so it no longer reports the same generic `Receipt review ready` state for
  every outcome.
- Added `_receiptReviewReadyStageLabel`, which reports whether parsed receipt
  lines are ready to classify, whether parsed lines need review, or whether the
  user should check parsed fields and add lines manually.
- Updated parsed receipt application to set the handoff stage only after parsed
  fields, totals, maintenance hints, and line items have been applied.
- Kept the user routed to the filled receipt review surface after successful
  OCR/parser work, and preserved manual-review routing when OCR/parser cannot
  produce usable text.
- Updated source guards for the clearer `Check Photo Match` long-receipt action
  label.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue hardening the camera/OCR review path by improving no-text/no-line
  recovery and making sure the user never loses accepted receipt photos or
  lands back at an ambiguous starting point.

### Receipt Camera Reopen Pass 321 / Total Pass 401: No-Line OCR Recovery Explanation Batch

Status: complete.

What changed:
- Added `onReceiptOcrCompleted` to `SharedReceiptAttachmentPanel` so the parent
  expense receipt screen receives the actual `ReceiptOcrResult`, not only a
  success/failure boolean.
- Updated the expense receipt entry screen to store OCR diagnostics and
  structured OCR warnings from the shared camera/OCR panel.
- Made failed OCR handoff stages more specific, for example
  `Needs manual review: No readable text`, without storing private receipt
  text.
- Added no-line recovery labels for `What Happened` and `Next Step`, using the
  highest-priority OCR warning when available.
- Allowed receipt review metric values to wrap to two lines so recovery actions
  are not silently cut off.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue hardening accepted-photo retention and recovery: back/cancel paths
  should never silently throw away accepted photos, OCR sources, or recovery
  manifests before the user has a safe path forward.
