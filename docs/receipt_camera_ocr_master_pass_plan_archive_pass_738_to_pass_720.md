# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Pass 738: Edited OCR Source Selection Diagnostics Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Pass 738: Edited OCR Source Selection Diagnostics Batch

Status: complete.

What changed:
- Added a privacy-safe `photoEditReplacedOriginal` diagnostic when manual crop
  or rotate replaces a reviewed receipt photo with an edited copy.
- Added edited-source selection and edited-replaced-original counts to receipt
  reader handoff counts and metadata.
- Added matching OCR attachment document signals and risk flags in both the
  shared capture flow and expense import flow so edited copies are clearly
  treated as OCR sources without exposing receipt content.
- Added regression coverage for the result model, shared-flow source guards,
  and expense import source guards.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --reporter compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening receipt review handoff
  recovery when the user taps back/close after editing or adding long-receipt
  sections, so accepted photos are never silently discarded.

### Receipt Camera Pass 737: Reviewed Photo Edit Handoff Diagnostics Batch

Status: complete.

What changed:
- Added privacy-safe `editedPhotoActionCounts` to accepted receipt photo
  review results.
- Counted manual crop/rotation edit actions in receipt reader handoff counts
  and metadata without storing receipt content.
- Added OCR-source document signals and risk flags for manually edited review
  photos in both the shared capture-flow path and the attachment import path.
- Added regression coverage for manual crop diagnostics, handoff counts,
  metadata, and module-neutral source guards.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --reporter compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making edited-photo OCR source
  selection clearer when a crop/rotation copy replaces the original proof.

### Receipt Camera Pass 730: Dim-Capture Bridge Warning Parity Batch

Status: complete.

What changed:
- Tightened the saved-photo warning mapper so camera-result bridge diagnostics
  and native CameraX/AVFoundation diagnostics use the same review risk language.
- Treated `live_dim_capture_dim` and plain `dim` as dim saved-photo evidence
  instead of missing the warning because the bridge wording differs from native
  `live_ok_capture_dim` / `captured_dim`.
- Treated `live_glare_capture_glare` and plain `too_bright` as glare evidence
  so washed-out captures carry the same OCR risk forward.
- Added focused guard coverage for the bridge wording so review, parser-risk,
  and Command One-style health signals do not drift.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native brightness/exposure review
  surfacing and accepted-photo handoff timing so dim or delayed captures are
  visible without blocking a manually accepted readable receipt.

### Receipt Camera Pass 731: Filled Review Handoff Contract Batch

Status: complete.

What changed:
- Added an explicit accepted-photo next-step label stating that Next opens the
  filled receipt review with store, date, total, tax, item prices, and
  Business/Personal/Mixed choices.
- Added a machine-readable `receiptReaderHandoffMustOpenFilledReview` flag to
  the receipt reader handoff metadata.
- Passed the same flag and next-step label through the shared receipt capture
  flow diagnostics so module callers and admin health views can verify the
  intended destination.
- Added guard coverage so the accepted photo path cannot drift back into a
  generic attachment/home-screen handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is accepted-review status timing and
  camera review copy for delayed OCR handoff so the user sees what is happening
  after tapping Next.

### Receipt Camera Pass 732: Accepted Next Status Clarity Batch

Status: complete.

What changed:
- Changed the accepted-photo reading status from vague preparation copy to
  explicit "Next accepted" handoff copy.
- Updated the attachment status card title to "Opening Filled Receipt Review"
  while OCR/parsing runs.
- Made the status hint say the filled receipt details appear on the same screen
  as soon as OCR and parsing finish.
- Allowed one extra line in the status body so the handoff copy is less likely
  to truncate on phone screens.
- Added source guards for the import-action status message and the visible
  status card wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native/photo-review control
  surface around add-next-photo, crop/edit, and saved-photo warnings.

### Receipt Camera Pass 733: Review Next Opening Copy Batch

Status: complete.

What changed:
- Replaced vague post-capture wait-state wording in the review controls with
  "Opening filled receipt review."
- Shortened the visible busy button text to "Opening" / "Opening Review" so it
  fits compact phone controls while still telling the user what is happening.
- Added guard coverage so the receipt review controls do not regress to
  "Preparing receipt review."

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking add-next-photo/crop warning
  actions for long-receipt section flow.

### Receipt Camera Pass 734: Long-Receipt Add Section Copy Batch

Status: complete.

What changed:
- Renamed the partial-receipt prompt title from "Finish This Receipt Photo" to
  "Add Missing Receipt Section."
- Renamed the guide action from generic "Open Receipt Camera" to "Add Next
  Receipt Photo."
- Kept the repeat-lines / ghost-slice guidance intact so the next photo can
  overlap enough for stitching or ordered OCR fallback.
- Added tests that reject the generic camera label and require the
  receipt-section wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review/crop save safeguards and
  accepted-photo cleanup behavior.

### Receipt Camera Reopen Pass 724: Native Device Memory Policy Bridge Batch

Status: complete.

What changed:
- Added a native camera session `maxLocalPhotoBytes` limit so CameraX and
  AVFoundation receive the same per-photo budget selected by the device
  capability profile.
- Added a privacy-safe `nativeCaptureMemoryPolicy` token that tells the native
  camera whether it should use bounded, older-phone, small-proof, or tiny-proof
  capture handling while still preserving the original source for OCR first.
- Threaded both fields through the Dart native-camera service payload and into
  Android and iOS receipt camera diagnostics.
- Added regression coverage proving the Dart session planner, Android bridge,
  and iOS bridge all keep these storage/device-tier rails in place.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using these explicit native memory
  rails in review/capture recovery diagnostics so interrupted captures,
  older-phone paths, and storage-saver paths can be separated cleanly without
  exposing receipt content.

### Receipt Camera Reopen Pass 725: Native Recovery Memory Policy Diagnostics Batch

Status: complete.

What changed:
- Added `maxLocalPhotoBytes` and `nativeCaptureMemoryPolicy` to the
  privacy-safe native capture staging whitelist.
- Added those same fields to the interrupted-capture recovery evidence label so
  Command One and recovery UI can tell older-phone, storage-saver, and tiny-proof
  paths apart without receipt content.
- Extended native capture staging tests so the manifest and Hive recovery index
  preserve the new memory-policy fields while still dropping private receipt
  text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making review/capture user actions
  respond better to storage-saver and older-phone memory policies, especially
  when the user backs out after capture or when staged photos are recovered.

### Receipt Camera Reopen Pass 726: Review Memory Policy Copy Batch

Status: complete.

What changed:
- Added review-screen status copy that appears only when the native capture
  diagnostics show an older-phone or storage-saver memory policy.
- The copy explains the important user promise plainly: Maintainiac reads the
  full captured photo first, while smaller saved copies are only for storage and
  recovery.
- Kept the normal review screen uncluttered by hiding this copy when no
  storage/device memory policy requires it.
- Added layout guard coverage so the review copy stays tied to
  `nativeCaptureMemoryPolicy` and `storageConstrained` diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening accepted-photo handoff
  diagnostics so the app-assisted receipt review can distinguish normal,
  recovered, phone-backup, storage-saver, and older-phone capture sources.

### Receipt Camera Reopen Pass 727: Accepted Capture Source Classification Batch

Status: complete.

What changed:
- Added privacy-safe accepted-capture source policy counts to
  `ReceiptPhotoReviewResult`.
- Capture source classification now separates normal native capture, recovered
  native capture, storage-saver native capture, older-phone native capture, and
  phone-camera backup capture without using receipt text, merchant names, item
  lines, prices, or paths.
- Allowed one capture to carry multiple safe source tags when appropriate, such
  as recovered plus storage-saver plus older-phone workload.
- Added those source tags to OCR attachment document signals and review risk
  flags in both the shared receipt capture flow and the expense import-actions
  path.
- Extended focused tests so source policy counts, metadata, document signals,
  and risk flags survive the app-assisted receipt handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the UI and diagnostics for
  recovered/staged accepted photos so backing out, resuming, and accepting
  photos always leaves the user with a clear next action and the app with
  privacy-safe evidence.

### Receipt Camera Reopen Pass 728: Recovery Banner Next-Action Clarity Batch

Status: complete.

What changed:
- Added `recoveryNextActionLabel` and `recoveryNextActionDetail` to interrupted
  native capture recovery records.
- Updated the interrupted receipt-photo banner to tell the user the real next
  action: resume the saved photo/sections, review them, then tap Next to attach
  and read the receipt into the form.
- Kept the wording privacy-safe and action-oriented; it does not expose receipt
  text, store names, item lines, prices, or photo paths.
- Updated recovery record and panel guard tests to enforce the clearer resume,
  attach, read, and discard wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening the accepted-photo review
  exit/Back path so leaving review cannot silently discard useful staged photos
  and the diagnostic action taken is clear.

### Receipt Camera Reopen Pass 729: Review Exit Form-Fill Warning Batch

Status: complete.

What changed:
- Tightened the receipt photo review Back/exit confirmation copy.
- The dialog now explicitly says receipt reading has not filled the form yet
  until the user taps `Next: Attach + Review Details`.
- Kept the saved-for-later wording for locally recoverable photos, so backing
  out does not feel like the receipt was attached or read when it was only saved
  for recovery.
- Added layout guard coverage for the new form-fill warning.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking the native preview/capture
  brightness and exposure-assist diagnostics path again so dark-preview/dim-save
  cases are visible and actionable without blocking manual capture.

### Receipt Camera Reopen Pass 717: Native Bridge Control Parity Batch

Status: complete.

What changed:
- Audited the native CameraX and AVFoundation receipt bridges for the
  user-facing control contract.
- Confirmed both bridges expose a compact `visibleControlSet` summary for
  privacy-safe diagnostics, rather than leaking receipt text or image content.
- Tightened Android and iOS bridge tests so the always-visible controls stay
  present: back, settings, manual shutter, and status.
- Added test guards for conditional native controls: light/torch, brightness,
  long receipt done, section ghost guide, and edge guide.
- Kept the pass camera/OCR-only and did not touch PDF, Firebase, inventory, or
  5.5.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening the native receipt capture
  review transition so accepted photos keep the staged source image and move
  toward the app-assisted parsed receipt review without dropping back into a
  confusing home/add-receipt state.

### Receipt Camera Reopen Pass 718: Accepted Photo Review Priority Batch

Status: complete.

What changed:
- Refactored the receipt attachment panel into a local build helper so the
  expense receipt screen can place it based on workflow state.
- Kept the attachment panel near the top before the user starts the receipt
  reading flow.
- Once photo review is accepted or receipt reading starts, the app-assisted
  filled receipt review becomes the primary next work area.
- Moved the attachment panel below the filled review in that state so add-more,
  retake, and proof recovery remain available without making the user feel
  dumped back at the add-receipt area.
- Added regression coverage for the conditional layout so accepted receipt
  photos do not regress into the old “handoff then attachment panel before
  review” order.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the user-facing accepted
  photo copy and recovery actions so the button language stays “Next” oriented
  and the app makes clear that OCR/parse review is the next step.

### Receipt Camera Reopen Pass 719: Accepted Photo Status Copy Batch

Status: complete.

What changed:
- Replaced the live reviewed-photo reading status that sounded like backend
  storage plumbing.
- The status now tells the user that the receipt photo is attached, Maintainiac
  is reading the clear source, and the next screen will show filled receipt
  details.
- Kept the privacy-safe decision, next-check, and evidence fields in the same
  message for diagnostics without exposing receipt content.
- Added a regression guard so the old “reading before the smaller backup copy”
  copy does not return to the user-facing flow.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking native review/back/close
  behavior against staged recovery so tapping back after capture cannot trap the
  user or silently throw away accepted receipt photos.

### Receipt Camera Reopen Pass 720: Empty Review Back Recovery Batch

Status: complete.

What changed:
- Audited receipt review back/close behavior after native capture staging.
- Confirmed the normal review screen already blocks system back and routes
  through the explicit attach/keep-reviewing/keep-saved-for-later choice.
- Added the same `PopScope(canPop: false)` protection to the empty/missing-photo
  recovery screen so Android/system back cannot silently bypass the recovery
  path.
- Kept the explicit Return To Receipt Entry button and routed system back
  through `_leaveReceiptReviewWithoutSaving`.
- Added regression coverage that the empty recovery layout uses the same
  no-silent-pop pattern.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening recovery-copy behavior
  so generated previews/crops/stitch/data-saver files are cleaned up without
  touching staged accepted receipt photos that must remain recoverable.
