# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 107 of 150: Long Receipt Review Language Alignment

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 107 of 150: Long Receipt Review Language Alignment

Status: completed.

Goal:
- Make long-receipt stitch/fallback UI match the current app-assisted receipt
  workflow: `Next` leads to filled receipt review, not a vague hidden read step.

Completed:
- Reworded successful stitch preview copy so it says `Next` reviews one
  combined receipt image.
- Reworded fallback stitch copy so unsafe matches tell the user the app will
  review photos top to bottom.
- Renamed long-receipt fallback labels from `Read Photos In Order` to
  `Review Photos Top To Bottom`.
- Renamed the fallback action pill from `Next Reads Top To Bottom` to
  `Next Reviews Top To Bottom`.
- Reworded stitch-mode helper copy so it describes filling/reviewing the
  receipt review instead of reading the receipt.
- Updated the match-wait warning to say the receipt review fill is waiting on
  the photo match check.
- Updated source guards to protect the new long-receipt review language.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_stitching_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 106 of 150: Empty Photo Review Recovery

Status: completed.

Goal:
- Prevent the receipt photo review route from throwing if a picker/scanner edge
  case opens review without a usable photo path.

Completed:
- Added an empty-review recovery surface before the review screen indexes into
  the selected photo path.
- Added a clear back action to return to the receipt form.
- Added plain recovery copy explaining that the photo was not available and no
  receipt fields were changed.
- Added source guards so this recovery path remains in the receipt review
  screen.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 105 of 150: Filled Review Handoff Copy

Status: completed.

Goal:
- Make the handoff from captured receipt photo to expense receipt review clear:
  `Next` prepares the app-assisted filled review section, not a mystery read
  or a return to the attachment button.

Completed:
- Updated the expense receipt reading status to say the app is preparing the
  filled review section below.
- Reworded the app-assisted receipt review panel to say it is the filled review
  from the photo.
- Called out the exact fields the user must check: store, date, totals, and
  lines.
- Updated OCR/parser success snackbars to say receipt fields were filled and
  must be reviewed before saving.
- Updated assisted-flow source guards so the camera `Next` copy and expense
  review handoff copy stay aligned.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 104 of 150: Native Capture Regression Guard

Status: completed.

Goal:
- Keep production receipt capture on native phone camera/scanner surfaces and
  prevent the legacy custom Flutter camera screen from returning to the expense
  receipt flow by accident.

Completed:
- Strengthened receipt capture source guards so production review/import actions
  must not launch `ReceiptCameraScreen`.
- Guarded against production receipt action files depending on `CameraController`
  or `CameraPreview`.
- Kept Android document scanning unavailable until an offline/non-Play-Services
  scanner path is available.
- Guarded the scanner service against Android-specific document scanner routing
  that could make a user wait for Google Play Services updates before taking a
  receipt photo.

Verification:
- `dart format test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 103 of 150: Review Back Action And Next-Step Copy

Status: completed.

Goal:
- Make the post-capture receipt photo review screen feel like a normal camera
  review step instead of a trapped modal, and make the `Next` action describe
  the actual app-assisted receipt review handoff.

Completed:
- Changed the post-capture review top-left control from a close/X action to a
  plain back arrow labeled `Back to receipt form`.
- Kept crop mode as a cancel-crop action because that stays inside the editor
  instead of leaving the review flow.
- Reworded single-photo and long-receipt preview guidance so `Next` means
  reviewing the filled receipt, not a vague receipt read.
- Updated source guards so the back action and clearer `Next` copy stay in
  place during future receipt-camera passes.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 102 of 150: Stable Photo Proof IDs

Status: completed.

Goal:
- Keep saved receipt photo proof identity stable when the attachment panel
  republishes, removes, reorders, or re-reviews photos.

Completed:
- Added path-based receipt photo ID tracking in the shared attachment panel.
- Initial photo proof attachments now seed stable IDs from existing records.
- Removing or clearing photo proof now clears the matching stable ID entries.
- Publishing attachment changes now reuses the same photo ID for the same saved
  proof path instead of regenerating a timestamp ID every time.
- Re-reviewing existing receipt photos preserves IDs for unchanged proof paths.
- Adding new receipt photos preserves IDs for already attached proof paths while
  assigning new stable IDs to new saved proof paths.
- Added tests/guards proving photo IDs stay stable after removing a long-receipt
  section and that the stable-ID helpers remain wired.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 97 of 150: Retake/Remove Preview Cache Cleanup

Status: completed.

Goal:
- Prevent stale saved-proof previews, quality badges, and in-flight preview work
  from surviving after a receipt photo is retaken or removed.

Completed:
- Centralized per-photo review cache cleanup so crop, rotate, retake, and remove
  all clear the same quality, storage-preview, saved-proof-preview, and
  in-flight preview state.
- Made retake reuse the same path-replacement cleanup that edited photos use.
- Made remove clear stale saved-proof preview files for the removed photo.
- Kept long-receipt review state safe by invalidating stitch preview after
  retake/remove.
- Added source guards proving retake/remove use the shared cleanup path and
  clear in-flight preview keys.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_image_data_saver_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 101 of 150: Reviewed Photo Proof Read State

Status: completed.

Goal:
- Make saved receipt photo proof record whether it was actually read into the
  app-assisted receipt form.

Completed:
- Added per-photo read-state tracking in the shared receipt attachment panel.
- Reviewed photos now publish `readIntoForm` after OCR successfully fills the
  receipt form.
- Reviewed photos now publish `unreadable` when OCR attempts fail to find
  usable text.
- Replacing or newly adding receipt photos resets those photos to `notRead`
  until they are actually read.
- Photo-quality warnings no longer downgrade a proof that OCR already read into
  the form.
- Added tests/guards for read-state preservation and reviewed-photo read-state
  handoff.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_ocr_service_test.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_ocr_service_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 100 of 150: App-Assisted Re-Read Line Replacement

Status: completed.

Goal:
- Prevent duplicated or stale parsed receipt lines when the user retakes,
  replaces, or re-reads receipt proof during app-assisted expense entry.

Completed:
- Added a line-origin helper that identifies lines created by app-assisted
  receipt reading.
- Successful app-assisted parses now remove previous app-filled lines before
  adding the newly parsed lines.
- Unusable app-assisted reads now remove stale app-filled lines too, so old OCR
  results do not remain attached to a new failed read.
- Manual lines remain in place because they do not carry receipt OCR/parser
  evidence.
- Added assisted-flow guards proving the old app-filled lines are removed
  before new parsed lines are added.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_receipt_parser_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_line_models.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 99 of 150: Newly Added Receipt Section Focus

Status: completed.

Goal:
- Keep long-receipt users oriented when they add another receipt photo after
  proof already exists.

Completed:
- Added an initial selected-photo index to `ReceiptPhotoReviewScreen`.
- When the user adds new receipt photos to an existing proof set, review now
  opens on the first newly added photo instead of jumping back to photo 1.
- Clamped the initial selected index so stale or invalid indexes cannot crash
  the review screen.
- Added source guards proving the import path passes the first-new-photo index
  and the review screen clamps it safely.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 98 of 150: Production Native Camera Routing Guard

Status: completed.

Goal:
- Keep production receipt capture routed through the phone camera/gallery
  surfaces and prevent future code from falling back into one-photo-only or
  custom-camera entry points.

Completed:
- Removed unused single-photo helper methods from `ReceiptImagePicker` so
  receipt callers use the set-based camera/gallery APIs that support long
  receipts.
- Added source guards proving receipt review add-photo and receipt import both
  use `ReceiptImagePicker.takeReceiptPhotoSet()` and do not instantiate the
  legacy `ReceiptCameraScreen`.
- Kept Android receipt capture away from Google Play Services document-scanner
  waits; Android uses the phone camera fallback, while iOS can still use the
  native document scanner.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_image_picker.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_image_picker.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for the remaining camera gaps and keep hardening
  only the camera/review path before moving to PDF or maintenance parsing.

## UI Foundation Track

### Pass 01 of 40: App-Assisted Handoff

Status: complete.

Goal:
- After receipt photo review, app-assisted reading must lead into receipt review/classification instead of feeling like a plain attachment picker.

Scope:
- Show reading status during OCR.
- Show success status telling the user to review parsed receipt lines below.
- Make OCR failure reset the reading state.
- Guard that parsed receipts scroll into review/classification.

Done:
- User sees that the app is reading the receipt.
- User sees where to review after reading.
- Parser application scrolls into review.
- Focused tests cover the handoff.

### Pass 02 of 40: Camera Shell Layout

Status: complete.

Goal:
- Make the live camera screen feel like Microsoft Lens plus Google Drive Scanner: fast, obvious, edge-controlled, and uncluttered.

Scope:
- Top bar: back, flash, settings, help if needed, all edge-aligned.
- Bottom bar: shutter, add/import option if appropriate, assisted/manual mode indicator.
- Remove any center-screen buttons that compete with the preview.
- Keep the preview dominant.
- Make settings a full screen or clean route, not a blocking bottom sheet over the camera.
- Keep manual shutter always available.

Done:
- User can open camera and immediately understand how to take a receipt photo.
- Preview is not covered by controls.
- No device capability details are visible to the normal user.
- S24 UI review is appropriate after this pass or after Pass 04 depending on batch size.

### Pass 03 of 40: Camera Interaction Basics

Status: complete.

Goal:
- Make the live camera behave like a normal high-quality camera app.

Scope:
- Pinch to zoom.
- Tap receipt text to focus.
- Flash modes are understandable.
- Manual shutter works even when automatic guidance is unsure.
- Capture button gives immediate feedback.
- Camera errors are plain-language and recoverable.

Done:
- User can zoom, focus, flash, and capture without fighting the app.
- Auto mode cannot prevent manual capture.
- Focus/capture wording matches real behavior.
- Tap focus now attempts focus and exposure independently so partial camera support still helps the user.
- Zoom and torch failures now use compact camera-surface feedback instead of disruptive UI.

### Pass 04 of 40: First-Use Camera Setup

Status: complete.

Goal:
- Explain advanced receipt capture without dumping settings into the capture surface.

Scope:
- First-use setup explains app-assisted receipt fill.
- Explain long receipt sections.
- Explain save-space copies in plain language.
- Explain automatic capture as optional.
- Add reset defaults.
- Keep setup short enough that a user can get to the camera quickly.

Done:
- First-time user understands the workflow.
- Returning user is not forced through setup again.
- UI build should be pushed to S24 after Pass 02-04 batch.
- Auto capture now turns on assisted camera mode because auto capture depends on assisted guidance.
- First-use setup now summarizes assisted fill, manual/auto capture, and saved-copy behavior in plain language.
