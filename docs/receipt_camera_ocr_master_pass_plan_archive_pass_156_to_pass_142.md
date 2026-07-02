# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 156: Receipt Review Warning Visibility Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 156: Receipt Review Warning Visibility Batch

Status: completed.

Goal:
- Make the visible filled receipt review screen show OCR warning burden clearly
  instead of burying it behind one generic read label.

Completed:
- Reworked the OCR review row title to include the warning count when warnings
  exist.
- Added the warning review instruction directly to the visible receipt review
  detail.
- Added a count for additional OCR warnings so multiple warnings are not hidden
  behind the first warning.
- Added guards proving the review row uses warning instructions, warning count
  wording, and warning pluralization.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Map warning kinds to the specific review areas the user should check first:
  receipt photos, overlap/stitch sections, totals, or app-filled line items.

### Receipt Camera Reopen Pass 155: OCR Warning Source-Aware Review Batch

Status: completed.

Goal:
- Make successful OCR reads with warnings tell the user exactly what review
  burden remains before saving.

Completed:
- Added `ReceiptOcrWarning.reviewInstruction` so blocked, partial, and review
  warnings each carry plain-language save guidance.
- Added warning review instructions to `ReceiptOcrResult.reviewMessage`.
- Changed receipt read status so any OCR warning marks the panel as needing
  review, not only blocking or partial warnings.
- Added a behavior test proving duplicate/overlap OCR warnings tell the user to
  compare the filled form with the receipt proof before saving.
- Added a source guard proving review-level warnings affect receipt read status.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Make the visible receipt review screen surface OCR warning details clearly
  enough that the user knows which lines or receipt sections need checking.

### Receipt Camera Reopen Pass 154: OCR Failure Source-Aware Recovery Batch

Status: completed.

Goal:
- Make app-assisted receipt reading failures explain what source failed and
  what the user should do next instead of giving one generic retry message.

Completed:
- Added `_receiptReadRecoveryAction` for photos, PDFs, saved receipt text, and
  mixed readable source sets.
- Reworded OCR exception failures to name the source summary before explaining
  the next action.
- Reworded no-text/unreadable states to pair the OCR warning with source-aware
  recovery instructions.
- Added source guards for photo, PDF, saved-text, mixed-source recovery copy,
  and source-aware reading failure copy.
- Added expense coordination note: expenses must stay active-vehicle aware so a
  single owner, employee, or fleet account can assign each expense to the right
  vehicle/profile for cost tracking.
- Added inventory/materials coordination note: inventory parsing can advance in
  another workstream, but it should consume the shared receipt capture/OCR
  output instead of forking the camera flow.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with OCR warning review copy so partial/low-confidence read states
  make the exact review burden clear before the user saves.

### Receipt Camera Reopen Pass 153: OCR Read Status Source Detail Batch

Status: completed.

Goal:
- Make generic app-assisted receipt reading status explain what kind and count
  of source files are being read instead of saying every source is a single
  clear receipt image.

Completed:
- Added `_receiptReadSourceSummary` for readable attachment sets.
- The source summary distinguishes clear receipt photos, receipt PDFs, and saved
  receipt text.
- Reworded generic OCR read-start status to use the source summary.
- Kept the filled receipt review destination explicit in the status copy.
- Added source guards for single/multiple photos, PDFs, saved receipt text, and
  the new source-summary read message.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with OCR failure recovery copy so unreadable/no-text states explain
  which source type failed and what the user should do next.

### Receipt Camera Reopen Pass 152: OCR Source Count And Proof Handoff Guard Batch

Status: completed.

Goal:
- Make the receipt handoff explain the difference between saved proof photos and
  clear OCR source images, especially for long receipts.

Completed:
- Added `savedProofCountLabel` to receipt review results.
- Added `ocrSourceCountLabel` to receipt review results, including combined OCR
  image wording when stitching succeeds.
- Reworded the app-assisted read-start message to say how many saved proof
  photos were kept and how many clear OCR sources are being read.
- Reworded the missing-OCR-source warning to include the saved proof count.
- Added source guards for proof count, OCR source count, combined OCR image
  wording, and missing clear OCR source messaging.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with OCR read-status source detail so generic attachment OCR status
  can also explain what type and count of source files are being read.

### Receipt Camera Reopen Pass 151: Receipt Review Result Handoff Evidence Batch

Status: completed.

Goal:
- Make the post-review OCR handoff agree with the long-receipt decision so the
  app explains whether it is reading one combined image or multiple receipt
  photos in order.

Completed:
- Reused the stitch review decision label when receipt photos are saved and the
  app-assisted read begins.
- Reworded the read-start status to say the app is reading into the filled
  receipt review form.
- Reworded matched-image success copy from a vague matched photo to `One
  combined receipt image was read`.
- Kept fallback success copy explicit: receipt photos are read from top to
  bottom.
- Added source guards for the review-decision handoff and combined-image
  success message.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with OCR source count and proof handoff guards so the app can explain
  when the saved proof is separate from the clear OCR source images.

### Receipt Camera Reopen Pass 150: Review Stitch Fallback Copy And Evidence Batch

Status: completed.

Goal:
- Make long-receipt stitch decisions visible in plain language so the user can
  tell whether Maintainiac made one combined receipt image or is safely reviewing
  the photos from top to bottom.

Completed:
- Added plain stitch-result decision labels for match confidence, review path,
  and final review decision.
- Shows a compact `Decision:` line on the long-receipt match card.
- The decision line distinguishes `1 combined receipt image` from
  `photos top to bottom`.
- Keeps fallback behavior honest: if the stitch is unsafe, `Next` still works
  by reviewing the photos in order.
- Added source guards for stitch decision labels and the review-card decision
  evidence.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with receipt review result handoff evidence so the import/OCR side
  can explain whether it is reading one combined image or multiple top-to-bottom
  receipt photos.

### Receipt Camera Reopen Pass 149: Review Continuation Copy And Action Clarity Batch

Status: completed.

Goal:
- Make receipt review continuation wording explain the user's next screen
  instead of exposing internal OCR/read/save pipeline wording.

Completed:
- Reworded save-prep status copy to say the app is preparing the filled receipt
  review form.
- Changed critical-quality continue copy from `Review Anyway` to
  `Use Photo Anyway`.
- Reworded multi-photo pre-stitch continue copy to `Check Long Receipt`.
- Reworded stitch mode title to `Long Receipt Match` and clarified that unsafe
  matches still let `Next` review photos in order.
- Reworded preview status and tool-mode copy so `Next` means opening the filled
  receipt review form.
- Added source guards so future receipt UI changes keep the clearer
  continuation language and do not reintroduce vague match/review labels.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with stitch fallback copy and evidence so long receipts clearly show
  when the app made one combined receipt image versus when it safely reviews
  photos top to bottom.

### Receipt Camera Reopen Pass 148: Review Save/Continue State Audit Batch

Status: completed.

Goal:
- Harden the `Next` path so preparing saved proof images, OCR source images, and
  stitch output cannot leave the review screen in a stale "preparing" state.

Completed:
- Added an empty-photo guard before receipt review save preparation begins.
- Snapshots the current photo paths before storage checks and image prep so the
  async save path does not use a mutable `_photoPaths` list directly.
- Added `_stopReceiptReviewSave` as a shared cleanup point for interrupted save
  preparation.
- Clears `_savingPhotos` when a closing review interrupts image prep before
  stitch, after stitch, or after generated-file cleanup.
- Added guard coverage proving the save path snapshots photo paths and clears
  interrupted saving state.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue with review continuation copy and action clarity so every save,
  stitch, and fallback state tells the user exactly what `Next` will do.

### Receipt Camera Reopen Pass 147: Review Add/Retake State Recovery Batch

Status: completed.

Goal:
- Keep add-photo, retake, remove, and reorder actions from leaving stale crop,
  stitch-preview, saved-proof, or saving state behind in the receipt photo
  review screen.

Completed:
- Added a shared `_recoverReviewAfterPhotoSetChanged` recovery path for review
  photo-set changes.
- Routed add-photo, retake, remove, and reorder through the recovery path after
  the photo list changes.
- Clamp the selected photo index and stitch-pair index after photo changes so
  the review cannot point at a missing receipt photo or missing stitch pair.
- Return multi-photo receipts to order review and single-photo receipts to
  preview review with controls visible.
- Clear stale crop source bytes, crop rectangles, crop display state, saving
  flags, and crop-processing flags after photo-set changes.
- Reset the tool controls scroll position so the next action stays reachable.
- Updated receipt camera layout guards so future changes keep this recovery
  behavior.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue with review save/continue state auditing so `Next` never leaves the
  user in a hidden or stale receipt-review state after image prep, stitching, or
  storage warnings.

### Receipt Camera Reopen Pass 146: Camera Review Navigation Safety Batch

Status: completed.

Goal:
- Prevent camera/review navigation from interrupting native capture or image
  preparation in ways that can leave the user stuck or the review flow in a
  dead-end state.

Completed:
- Added a close/back guard to the live receipt camera when a manual or assisted
  capture is already in progress.
- Shows a short user hint instead of tearing down the camera while a receipt
  photo is being captured.
- Added a close/back guard to receipt photo review while saved proof and OCR
  source photos are being prepared.
- Added a close/back guard while crop processing is active, directing the user
  to finish or cancel crop before leaving the review.
- Added guard tests proving camera close protection happens before teardown and
  review close protection happens before `_closingReview` is set.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue with review add/retake state recovery so newly added, retaken, or
  removed receipt photos keep the user in the right review mode with obvious
  next actions.

### Receipt Camera Reopen Pass 145: Receipt Review Correction Telemetry Batch

Status: completed.

Goal:
- Track whether app-filled receipt lines are confirmed or corrected after the
  user reviews them, without collecting private receipt text or item details.

Completed:
- Added privacy-safe telemetry event types for app-filled receipt line
  confirmations and corrections.
- Recorded the event after an app-filled receipt line is saved from the review
  editor.
- Kept telemetry metadata limited to source area, line use, review-needed flag,
  parser-review presence, category group, and parser confidence bucket.
- Added Command One summary counts for confirmed app-filled receipt lines,
  corrected app-filled receipt lines, and app-filled receipt line correction
  rate.
- Counted corrected app-filled receipt lines as user corrections while keeping
  confirmed lines separate.
- Added source guards and snapshot tests proving the new metrics exist and do
  not include private receipt content.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue with camera/review navigation safety: back/close behavior, staged
  photo escape paths, and making sure every photo review state has an obvious
  next action.

### Receipt Camera Reopen Pass 144: Receipt Review Line Editing Flow Batch

Status: completed.

Goal:
- Make editing an app-filled receipt line resolve its review state cleanly so
  corrected or confirmed OCR/parser lines do not keep warning the user after the
  line has been reviewed.

Completed:
- Changed the receipt line editor save path to mark app-filled lines reviewed
  when the user saves the line.
- Added `Corrected` parser review labeling when the user changes line details
  before saving.
- Added `Confirmed` parser review labeling when the user saves an app-filled
  line without changing it.
- Added review reasons for corrected and confirmed app-filled lines.
- Preserved parser confidence and receipt evidence while clearing
  `parserNeedsReview`.
- Added line-editor copy explaining that saving an app-filled line marks it
  reviewed.
- Added source guards for corrected/confirmed review labels, cleared review
  state, and the editor guidance copy.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart lib/screens/expenses/entry/expense_receipt_line_fields.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_line_editor_actions.dart lib/screens/expenses/entry/expense_receipt_line_fields.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 143: Receipt Mixed Allocation And Tax Review Batch

Status: completed.

Goal:
- Make mixed business/personal receipt allocation visible before save so users
  can understand how line subtotals, tax, fees, discounts, and receipt
  adjustments are split.

Completed:
- Added a `MIXED ALLOCATION REVIEW` block to the receipt-paper recap when line
  use controls are active.
- Shows business line count, personal line count, and split line count.
- Shows business subtotal, business tax/adjustment, and business final total.
- Shows personal subtotal, personal tax/adjustment, and personal final total.
- Updated mixed-total explanatory copy to explicitly mention sales tax, fees,
  discounts, and receipt adjustments.
- Kept return handling conservative by using nonnegative business/personal bases
  for the visible allocation breakdown.
- Added source guards for the mixed allocation review UI and allocation math.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_recap.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_recap.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 142: Receipt Line Review Save-Gate Polish Batch

Status: completed.

Goal:
- Make receipt save readiness behave like a real review checklist: it should
  identify what still needs attention, send the user back to the filled receipt
  review, and use strongest OCR warning logic before committing records.

Completed:
- Added a save-readiness issue for mixed receipt lines that do not have a usable
  business percent.
- Updated the Save Receipt panel to show mixed-line split-percent warnings
  before the user taps Save.
- Changed OCR save-readiness warning selection to prioritize blocking warnings,
  then partial warnings, then review warnings.
- Changed the `Review Receipt` path to scroll back to the app-filled receipt
  review and show clear next-step copy instead of silently closing the dialog.
- Added source guards for split-percent readiness, strongest OCR save warnings,
  and visible Save panel split warnings.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/entry/expense_receipt_totals.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_save_actions.dart lib/screens/expenses/entry/expense_receipt_totals.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`
