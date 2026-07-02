# Receipt Camera OCR Master Pass Plan Archive - Camera/Receipt Pass 86 of up to 150: Saved Proof Size Language Cleanup

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Camera/Receipt Pass 86 of up to 150: Saved Proof Size Language Cleanup

Status: completed.

Goal:
- Keep storage-saving choices understandable to non-technical users and avoid
  leaking "data saver" or compression-style wording into the receipt UI.

Completed:
- Renamed the photo review top-bar title from backup-size language to "Saved
  proof size."
- Reworded saved-proof preview loading and error text.
- Replaced settings-page "saved-copy" wording with "saved proof" wording.
- Kept the important product rule clear: OCR reads the clear receipt image
  first, while the saved proof size only affects the smaller retained image.
- Updated camera help-flow guards for the new saved-proof title.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_image_data_saver_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around first-run settings and making
  sure settings actions have clear apply/reset/default behavior.

### Camera/Receipt Pass 87 of up to 150: Receipt Camera Settings Apply/Reset Clarity

Status: completed.

Goal:
- Make receipt camera settings honest and clear: switch/size choices save
  immediately, while the Apply button closes the settings screen.

Completed:
- Added a plain settings note explaining that changes save as soon as the user
  taps a switch or saved-proof size choice.
- Clarified that "Apply Settings" closes the screen instead of pretending it is
  the only save action.
- Reworded first-use summary text from backup-copy language to saved-proof
  image language.
- Kept reset defaults visible and tied to recommended receipt camera plus saved
  proof settings.
- Updated camera help-flow guards for the new settings copy.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around capture/review navigation safety, especially
  accidental exits while a receipt photo is staged.

### Camera/Receipt Pass 88 of up to 150: Staged Photo Exit Dialog Clarity

Status: completed.

Goal:
- Make accidental-exit protection explain what the user is choosing before
  leaving staged receipt photos.

Completed:
- Reworded the close/exit dialog to explain that photos are in progress and
  can be prepared for receipt review, kept for editing, or abandoned.
- Replaced vague "Leave" with "Leave Without Saving."
- Replaced misleading "Save Progress" with "Prepare Receipt Review," matching
  the actual flow for both one-photo and multi-photo receipts.
- Added guard coverage for the updated exit-dialog actions.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around photo retake/add-photo
  behavior and making sure inserted photos keep the user in the right review
  state.

### Camera/Receipt Pass 89 of up to 150: Accepted Photo To Filled Review Routing

Status: completed.

Goal:
- Make the accepted receipt photo flow land on the app-filled receipt review
  destination instead of leaving the user at the attachment area.

Completed:
- Added an explicit `_hasAppAssistedReceiptReview` destination guard so the
  filled review section appears after OCR produces receipt text, parser quality,
  field confidence, OCR diagnostics, warnings, classification, or line items.
- Fixed the zero-line receipt path so a readable receipt with no safe parsed
  line items still shows the "No Line Items Found" recovery review instead of
  looking like the photo flow ended early.
- Made `_scrollToReceiptReview` retry briefly when the review section has not
  mounted yet, instead of silently giving up after one frame.
- Changed successful receipt-read completion to clear the reading state and
  focus the filled receipt review again after the awaited OCR/parser handoff.
- Added guard coverage so future camera/receipt changes cannot remove the
  app-assisted review destination, raw OCR fallback destination, retry-safe
  review focus, or successful read focus behavior.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around photo retake/add-photo
  behavior, back navigation, and preventing staged photos from leaving the user
  in a dead-end review state.

### Camera/Receipt Pass 90: Professional Photo Review Tray Tightening

Status: completed.

Goal:
- Make the first screen after taking a receipt photo feel like a professional
  scanner review instead of a cramped control panel.

Completed:
- Reduced the review tray height budget to 20% of the screen so the receipt
  preview keeps roughly the top 80% of the screen.
- Shortened the preview action labels to plain user language: Add Another
  Photo, Add Next Photo, Retake, Crop / Straighten, Saved Proof Size, and Next.
- Changed the primary preview action to a forward Next button instead of a
  scanner/read-style action.
- Added a compact thumbnail strip even for a single captured photo so the user
  can see what photo is selected without needing hidden scrolling.
- Kept multi-photo thumbnails visible for long receipts while preserving the
  larger receipt preview area.
- Updated guard coverage so future receipt-camera passes cannot quietly expand
  the preview controls or restore the confusing long add-photo labels.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture/review hardening around Android back behavior, native
  camera brightness/exposure parity, and avoiding disposed-camera preview
  crashes.

### Camera/Receipt Pass 91: Camera Close And Preview Disposal Safety

Status: completed.

Goal:
- Make camera back/close behavior reliable on Android and reduce the native
  preview race that can show a disposed-camera red screen.

Completed:
- Changed close/back during active capture from a blocked wait state into a
  real close request so the user is not trapped on the camera screen.
- Reworded the close hint to explain that an unfinished photo will be ignored.
- Added a delayed native camera disposal helper used after route pop for both
  cancel/back and successful camera result returns.
- Kept immediate disposal for non-mounted teardown, but avoided disposing the
  active native controller in the same frame that the camera route begins
  popping.
- Updated camera layout guards so future camera passes preserve the route-pop
  before controller-dispose order.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around Android brightness/exposure parity and
  native-camera result quality compared with the stock camera app.

### Camera/Receipt Pass 92: Native Exposure Baseline And Bracket Guardrails

Status: completed.

Goal:
- Keep receipt capture closer to the phone camera's native auto-exposure result
  while still allowing bounded rescue attempts when the live receipt signal says
  the image is too dark or too bright.

Completed:
- Stopped candidate capture retries from repeatedly forcing the native baseline
  exposure offset when no exposure correction is needed.
- Kept the first receipt photo candidate on the native auto-exposure baseline.
- Added an explicit bracketing gate so exposure nudges only happen on later
  candidates when live quality detects darkness or glare.
- Preserved bounded exposure nudges and post-capture baseline restoration for
  the rare cases where bracketing is justified.
- Updated camera guard tests so future passes cannot reintroduce always-on
  exposure fiddling during normal receipt capture.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around native capture quality, preview brightness,
  pinch-to-zoom, and the image-review-to-filled-receipt handoff.

### Camera/Receipt Pass 93: Pinch Zoom Queue Reliability

Status: completed.

Goal:
- Make receipt-camera pinch zoom behave like a normal phone camera control even
  while native `setZoomLevel` calls are still settling.

Completed:
- Split zoom gesture updates from native zoom pumping so pinch gestures can keep
  queuing the latest requested zoom level without awaiting the camera.
- Added a stale-controller guard so delayed zoom work cannot update a disposed
  or replaced camera controller.
- Added a final queued-update pump so a pinch update that lands at the end of an
  in-flight zoom call does not get stranded.
- Kept zoom finger-driven on the full preview instead of bringing back a visible
  zoom button.
- Updated camera layout guard coverage for the queued zoom pump and stale
  controller protection.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around live preview brightness, back navigation on
  physical devices, and the image-review-to-filled-receipt handoff.

### Camera/Receipt Pass 94: Filled Receipt Review Handoff Anchor

Status: completed.

Goal:
- Make the moment after accepting receipt photos feel like a clear next step:
  the app is reading the receipt, then opening the filled receipt review.

Completed:
- Added a receipt-read handoff anchor around the attachment/read-status area.
- When OCR starts after photo review, the expense form now scrolls to the
  receipt-read status instead of leaving the user at an unclear attachment area.
- When OCR/parser succeeds, the existing filled-review scroll remains the final
  destination.
- When OCR/parser fails or is skipped, the form scrolls back to the receipt
  handoff area so the failure/recovery message is visible.
- Reworded the reading status in plain user language: the app is reading the
  receipt now and the filled review opens below when readable.
- Updated assisted receipt flow guards for the new handoff anchor and scroll
  behavior.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around native preview brightness, physical-device
  back behavior, and receipt photo review layout density.

### Camera/Receipt Pass 95: Photo Quality Recovery Strip

Status: completed.

Goal:
- Make questionable receipt photos easier to understand after capture without
  blocking a user who can still read the receipt and wants to continue.

Completed:
- Added a compact single-photo quality recovery strip for photos that need
  review.
- The strip uses plain labels: Photo Needs Attention for critical issues and
  Check Photo Before Next for lighter warnings.
- The strip surfaces the quality guidance directly instead of burying the issue
  inside the main status sentence.
- Added direct Retake and Crop actions in the warning strip while keeping Next
  available for user judgment.
- Kept the strip out of normal good-photo review and multi-photo long-receipt
  mode so the main flow stays fast.
- Updated camera layout guards for the recovery strip, guidance source, and
  direct crop/retake actions.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera/photo review hardening around long-receipt multi-photo review
  clarity, saved proof size preview, and physical-device back behavior.

### Camera/Receipt Pass 96: Saved Proof Storage Clarity

Status: completed.

Goal:
- Make saved proof size settings understandable without making users think the
  app is reading OCR from the smaller backup image.

Completed:
- Renamed the details dialog from Photo Storage Details to Receipt Proof
  Storage.
- Added an explicit Receipt reading row that says OCR uses the clear photo
  first.
- Added an explicit Cloud backup copy row that identifies the saved proof tier.
- Kept the saved proof size language focused on storage and backup instead of
  developer compression jargon.
- Updated camera layout guards so future changes preserve the OCR-first and
  saved-proof-second wording.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue hardening around long-receipt multi-photo ordering/stitching clarity
  and physical-device back behavior.

### Camera/Receipt Pass 97: Filled Review Handoff Copy Cleanup

Status: complete.

What changed:
- Reworded post-capture and attachment status copy so `Next` clearly opens the
  filled receipt review instead of sounding like a hidden "read receipt" step.
- Kept OCR/readability language where it describes image quality, but removed
  vague camera-review handoff copy from the review tray, attachment list, exit
  dialog, and app-assisted receipt status.
- Updated long-receipt order/stitch fallback copy so the safe fallback says
  `Next reviews` or opens the filled review top to bottom.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue with native review/back behavior and camera handoff checks, then
  rerun the broader receipt-camera suite.

### Camera/Receipt Pass 98: Native Close Outcome Diagnostics

Status: complete.

What changed:
- Added a safe native `closeAction` diagnostic so QA and future Command Center
  health can distinguish Back/Done with no photos from Back/Done returning
  captured receipt sections.
- Preserved the current safety behavior: Back with captured sections returns
  them to review instead of silently discarding work.
- Carried the close-action bucket through staging and expense telemetry without
  receipt image/text/customer content.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue hardening physical-device close/reopen behavior and long-receipt
  review recovery, then rerun the broader receipt-camera suite.

### Camera/Receipt Pass 99: Native Close Result Double-Tap Guard

Status: complete.

What changed:
- Added a native close-result delivery guard so repeated Back/Done taps cannot
  fire duplicate cancel/capture callbacks from CameraX or AVFoundation.
- Kept the existing Back behavior: no photos cancels, captured sections return
  to review.
- Preserved safe diagnostics through staging and telemetry with
  `closeResultDeliveredCount`, still without receipt content.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue hardening interrupted/reopened native camera recovery and long-receipt
  photo review behavior.

### Camera/Receipt Pass 100: Interrupted Resume Context

Status: complete.

What changed:
- Added safe recovery-record labels for interrupted native captures:
  one-photo versus ordered long-receipt sections, plus the Back/Done close
  outcome.
- Updated the interrupted-capture banner so resuming explains that top-to-bottom
  section order is preserved.
- Kept the labels derived from diagnostics only; no receipt text, image content,
  customer names, addresses, or item details are exposed.

Validation:
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue hardening long-receipt review recovery and native camera reopen flows.

### Native Scanner Pass 101: Long-Receipt Stitch Diagnostics

Status: complete.

What changed:
- Added content-free long-receipt stitch diagnostics for manual overlap,
  repeated-text matching, zoom correction, straightening correction, and
  combined zoom/straighten correction.
- Exposed pair and diagnostic labels so review/Command Center can explain why a
  stitch succeeded or fell back without showing receipt text.

Validation:
- `flutter test test/receipt_stitching_test.dart`

### Native Scanner Pass 102: Android CameraX Brightness Assist

Status: complete.

What changed:
- Strengthened Android CameraX auto-exposure assistance for dark/glary receipt
  preview frames while keeping user manual brightness changes respected.
- Added safe diagnostics for brightness bucket, exposure decision, exposure
  index, and adjustment timing.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart`
