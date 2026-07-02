# Receipt Camera OCR Master Pass Plan Archive - Camera/Receipt Pass 71 of up to 150: Long-Receipt Review Language Cleanup

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Camera/Receipt Pass 71 of up to 150: Long-Receipt Review Language Cleanup

Status: completed.

Goal:
- Make the long-receipt photo review and stitch controls read like a
  professional receipt-scanner workflow instead of internal scanner terms.

Completed:
- Replaced visible "section" wording in the camera, help, settings, import,
  attachment summary, and stitch review paths with clearer "photo" language.
- Renamed stitch adjustment controls from overlap navigation to plain
  photo-pair navigation: "Previous Photos" and "Next Photos."
- Changed manual stitch guidance from "Manual overlap" to "Manual match" while
  preserving the actual overlap-based stitching behavior underneath.
- Clarified stitch status copy so the app explains when photos are safely
  stitched into one readable image versus when OCR will read the photos
  separately.
- Updated capability and attachment tests so future changes do not reintroduce
  confusing "photo sections" wording in the camera-facing flow.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart test/receipt_stitching_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_image_processor.dart lib/shared/widgets/receipt_capture/receipt_attachment_list.dart lib/shared/widgets/receipt_capture/receipt_camera_feedback.dart lib/shared/widgets/receipt_capture/receipt_camera_bars.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_camera_preview.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart`
- `rg -n "photo sections|receipt photo sections|Receipt sections|receipt sections|Use sections|Capture readable sections|Previous Overlap|Next Overlap|Add Receipt Section|Add Section|sections in order|read the sections|captured in sections" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart -S`

Next camera-only focus:
- Continue with camera review polish around stitched-image preview, safe
  fallback messaging, and direct app-assisted handoff into the receipt review
  screen.

### Camera/Receipt Pass 72 of up to 150: Stitch Preview Decision Polish

Status: completed.

Goal:
- Make the stitch preview screen explain the decision clearly: one readable
  receipt image when safe, or separate photo reading when not safe.

Completed:
- Added a clear stitched-preview success title: "Ready To Read One Receipt
  Image."
- Reworded stitch pair summaries from technical overlap/scale details to
  plain match language, including "manual match" and "repeated text found."
- Changed the stitched receipt detail from "OCR image" to "receipt image" so
  users are not exposed to internal OCR terminology during review.
- Clarified fallback guidance: if the repeated lines match, slide the match
  control; otherwise continue and the app reads each photo in order.
- Updated the long-receipt preview guide copy to use "match repeated receipt
  text" instead of overlap-centric wording.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_stitching_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_stitching_test.dart test/receipt_camera_help_flow_test.dart`

Next camera-only focus:
- Continue camera review polish around direct app-assisted handoff, action
  labels during save/read, and ensuring the review surface never feels like it
  dropped the user back to the previous form.

### Camera/Receipt Pass 73 of up to 150: Awaited App-Assisted Handoff

Status: completed.

Goal:
- Make the camera/photo review handoff wait for expense receipt parsing before
  the shared receipt panel reports that parsed lines are ready below.

Completed:
- Changed the shared receipt attachment `onImportedText` callback to support
  `FutureOr<void>` so the parent receipt screen can finish parsing before the
  shared panel clears its reading state.
- Updated OCR/photo import paths to `await` the app-assisted receipt callback
  before showing "review parsed lines below" status.
- Changed the expense receipt parser entrypoint from fire-and-forget to an
  awaited `Future<void>` flow.
- Preserved the existing nonblocking startup parse by explicitly wrapping that
  one call in `unawaited(...)`.
- Added/updated guard tests proving the app-assisted handoff is awaited before
  the "Receipt read" status copy is set.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_stitching_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue camera review polish around the final read/save button states,
  failed-read recovery, and making the post-photo receipt review impossible to
  miss.

### Camera/Receipt Pass 74 of up to 150: Failed-Read Recovery Panel

Status: completed.

Goal:
- Make failed receipt reading recoverable and understandable after a camera or
  photo review attempt.

Completed:
- Reworked the shared receipt read status panel from a single status sentence
  into a title, detail, and next-step hint.
- Added explicit failed-read guidance: review the photo, add another photo, or
  keep the proof and fill the receipt by hand.
- Added success/warning/reading titles so the panel communicates state at a
  glance.
- Preserved existing attachment actions while making the status panel more
  useful when OCR cannot read a photo.
- Added guard tests for the failed-read recovery copy.

Verification:
- `flutter test test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue with camera action polish around final read/save labels, no-text OCR
  recovery, and receipt review visibility after app-assisted reading.

### Camera/Receipt Pass 75 of up to 150: App-Assisted Read Action Clarity

Status: completed.

Goal:
- Make the photo review handoff clearly say that the app is reading the receipt
  into the expense form, using the clear prepared OCR image before the saved
  proof copy is reduced for backup/storage.

Completed:
- Reworded final camera review actions from generic scanner language to direct
  expense-flow language such as "Read Into Expense Form," "Check Stitch First,"
  "Read One Receipt Image," and "Read Photos In Order."
- Replaced the stitch wait warning with a plain instruction to wait for the
  photo match check before choosing how the receipt should be read.
- Clarified the reading status so it states that OCR uses the clear receipt
  image before the saved proof copy is made smaller.
- Changed successful photo-read messages to point the user to the parsed
  expense fields instead of vague parsed-line language.
- Strengthened failed-read recovery copy for blurry/no-text photos and long
  receipts.
- Updated receipt-camera guard tests for the new action labels and recovery
  wording.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue camera review polish around the bottom tray footprint, clearer
  primary/secondary action hierarchy, and long-receipt photo order/stitch
  guidance.

### Camera/Receipt Pass 76 of up to 150: Compact Review Tray Footprint

Status: completed.

Goal:
- Make the receipt photo remain the dominant surface after capture by reducing
  the bottom review tray footprint and making the primary read action clearer
  than the secondary tools.

Completed:
- Reduced the reserved preview bottom space from 124px to 98px so more of the
  receipt image remains visible during normal review.
- Trimmed the order, stitch, and saved-proof preview bottom reservations while
  still leaving room for their tools.
- Reduced compact tray padding and primary button height.
- Reduced mini tool button size from 39px to 35px.
- Removed the extra trailing helper text in the compact preview tray so the
  tray behaves like a control bar instead of a large instruction panel.
- Kept the top status sentence and primary "Read Into Expense Form" action
  visible so the user still knows the next step.
- Added/updated guard tests for the compact layout constants and button sizes.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera review polish around long-receipt ordering/stitch guidance,
  including clearer handling when multiple photos are taken and one needs to be
  retaken or moved.

### Camera/Receipt Pass 77 of up to 150: Long-Receipt Order And Retake Clarity

Status: completed.

Goal:
- Make multi-photo receipt review safer when a user retakes a blurry top,
  middle, or bottom photo, without adding another large instruction panel.

Completed:
- Clarified order hints so the selected long-receipt photo explains whether it
  should show the top, bottom, or the next downward section.
- Added plain labels for adding the next photo versus filling a missing photo
  slot.
- Added plain retake labels for top, middle, and bottom photos so retake
  clearly preserves the selected receipt position.
- Reused the existing count label helper in the order header instead of leaving
  unused label code behind.
- Added guard tests for the new order/retake label helpers.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera-side hardening around live capture controls and automatic
  capture behavior so manual shutter always works and auto capture never blocks
  a clear user-taken photo.

### Camera/Receipt Pass 78 of up to 150: Manual Shutter Overrides Auto Capture

Status: completed.

Goal:
- Ensure assisted/auto capture helps the user without blocking or overriding a
  manual shutter tap.

Completed:
- Made the manual shutter clear any queued auto-capture before taking the
  photo.
- Made the delayed auto-capture callback verify that it is still queued before
  it fires.
- Cleared the queue immediately before launching assisted capture so stale
  capture requests cannot stack.
- Changed the assisted camera badge from "Auto ready" to "Tap anytime" so users
  know they can take the photo themselves.
- Added guard tests proving questionable manual photos are not blocked and
  queued auto-capture is cancelable.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_bars.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue live camera polish around visible guidance, edge overlay behavior,
  and keeping help unobtrusive while preserving tap focus and pinch zoom.

### Camera/Receipt Pass 79 of up to 150: Confident Edge Overlay Only

Status: completed.

Goal:
- Keep the live camera clean unless the app has a confident receipt frame to
  show, so the edge overlay does not feel like decoration or clutter.

Completed:
- Added a device-tier-aware live edge confidence threshold to the camera capture
  policy.
- Kept live edge overlay disabled for light-tier devices.
- Added a single `_liveFrameForOverlay()` gate so the overlay only appears in
  assisted mode, only when the frame is usable, and only when confidence meets
  the device policy threshold.
- Preserved tap focus, pinch zoom, camera top controls, and nonblocking long
  receipt hints.
- Added guard tests for assisted-mode overlay gating and edge confidence policy.

Verification:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera capture polish around post-capture review routing and the
  bridge from live capture into photo review so one-photo and multi-photo
  receipts land in the expected review state.

### Camera/Receipt Pass 80 of up to 150: Multi-Photo Review Starts In Order Mode

Status: completed.

Goal:
- Make the post-capture/photo-review handoff land in the right state for
  one-photo versus multi-photo receipts.

Completed:
- Added an initial review-mode selector for the receipt photo review screen.
- Kept single-photo and best-shot candidate flows in the normal review mode.
- Started ordinary multi-photo receipt review in the order-check mode so users
  immediately verify top-to-bottom photo order before stitching or reading.
- Added guard tests so multi-photo review does not silently regress to the
  single-photo preview state.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera flow polish around photo review completion, especially how
  the app communicates that the next step is receipt parsing/review and not a
  return to a generic attachment screen.

### Camera/Receipt Pass 81 of up to 150: Receipt Proof Summary Explains App Assistance

Status: completed.

Goal:
- Make the attachment summary after photo review feel like a receipt-processing
  checkpoint instead of a generic file attachment list.

Completed:
- Passed the app-assisted receipt setting into the receipt proof summary.
- Reworded photo proof summary details to say "Saved proof" instead of only
  "Data saver."
- Added clear summary copy that app assistance reads the clear photo first when
  assisted receipt filling is enabled.
- Preserved proof-only wording when app assistance is disabled.
- Kept multi-photo summaries explicit that photos are kept in receipt order.
- Updated widget tests for the new long-receipt summary copy.

Verification:
- `flutter test test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_list.dart test/receipt_attachment_panel_actions_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera/review polishing around completing photo review and ensuring
  the parsed receipt review remains the clear destination after OCR finishes.

### Camera/Receipt Pass 82 of up to 150: Parsed Expense Review Destination Copy

Status: completed.

Goal:
- Align the expense receipt OCR success message with the camera handoff so the
  user knows the next destination is parsed expense review, not a generic
  attachment area.

Completed:
- Updated the expense-side OCR success copy to say the receipt was read and the
  parsed expense fields below should be reviewed before saving.
- Kept the existing parsed receipt scroll behavior intact.
- Added a guard test so the expense OCR path keeps pointing users to the parsed
  expense review destination.

Verification:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera hardening around quality review thresholds and the language
  shown for questionable photos so clear manual captures are accepted but weak
  photos still receive useful next-step guidance.

### Camera/Receipt Pass 83 of up to 150: Quality Review Warnings Without False Blocking

Status: completed.

Goal:
- Make photo-quality feedback help the user inspect or retake a photo without
  treating every imperfect manual capture like a failed scan.

Completed:
- Split receipt photo quality into critical retake issues versus review-level
  warnings.
- Added plain-language quality titles and guidance for dark, glare-heavy,
  blurry, soft, low-resolution, low-contrast, poorly framed, and weak-text
  photos.
- Reworded post-capture warnings so soft photos can continue with review while
  critical issues still recommend retaking the image.
- Updated the receipt review tray to show specific next-step guidance instead
  of vague "check readability" text.
- Updated the saved-proof preview to explain that OCR uses the clear photo
  first and the data-saving setting only controls the smaller proof copy.
- Added tests proving soft photos warn without becoming retake blockers.

Verification:
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue camera/review polishing around the single-photo review screen layout
  and the post-photo continuation path so the user always has an obvious next
  action after choosing a receipt photo.

### Camera/Receipt Pass 84 of up to 150: Single-Photo Review Handoff Clarity

Status: completed.

Goal:
- Make the one-photo review screen and OCR handoff tell the user exactly what
  happens next after accepting a receipt photo.

Completed:
- Reworded the one-photo review tray to explain that users should add another
  photo if the receipt continues, otherwise read the current photo into the
  expense form.
- Allowed the preview tray status to use two short lines so the instruction is
  not hidden behind ellipses.
- Preserved the same long-receipt instruction in the regular preview status
  path and the compact preview tray.
- Changed the OCR handoff status to keep the actual per-source success message
  instead of replacing it with generic wording.
- Updated assisted receipt tests so the persistent OCR status remains tied to
  the actual source that was read.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera review hardening around long-receipt ordering and the
  stitch/read decision so multi-photo receipts cannot accidentally feel like a
  single generic attachment.

### Camera/Receipt Pass 85 of up to 150: Multi-Photo Stitch Decision Clarity

Status: completed.

Goal:
- Make the long-receipt stitching controls explain photo pairs and fallback
  behavior without confusing the user about what will be read.

Completed:
- Fixed stitch pair navigation copy from a confusing photo-count phrase to
  "Pair X of Y."
- Added explicit readiness labels for safe stitched reads versus top-to-bottom
  separate-photo reads.
- Reworded stitch readiness detail so a failed/unsafe stitch tells the user the
  app will read each receipt photo in order instead of hiding that fallback
  behind technical language.
- Added source guards for the pair-count wording and safe-stitch label.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera-only focus:
- Continue camera review polish around saved-proof/data-saving preview and
  making sure saved proof choices remain visible without blocking the receipt.
