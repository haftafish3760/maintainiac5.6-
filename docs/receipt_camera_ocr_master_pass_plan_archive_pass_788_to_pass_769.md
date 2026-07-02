# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Pass 788: Native Preview Exposure Policy Contract Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Pass 788: Native Preview Exposure Policy Contract Batch

Status: complete.

What changed:
- Added explicit native session policy names for receipt preview exposure,
  brightness guarding, shutter speed, tap-to-focus behavior, pinch-zoom
  behavior, and auto-capture behavior.
- Sent those policies through the Maintainiac native camera method-channel
  payload so CameraX/AVFoundation implementations get clear instructions:
  meter for receipt paper, avoid dark previews, keep manual capture available,
  and keep auto capture opt-in.
- Added the same policy tokens to privacy-safe capture diagnostics so Command
  One/debugging can see which camera behavior was requested without storing
  receipt content.
- Added regression coverage for capable phones, unsupported-control phones, and
  the native service payload/diagnostics handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is platform bridge parity: Android
  CameraX and iOS AVFoundation should consume these receipt exposure/brightness
  policy tokens instead of behaving like a generic camera or dimming the live
  preview.

### Receipt Camera Reopen Pass 781: Native Shell Receipt-Specific Control Copy Batch

Status: complete.

What changed:
- Tightened the native receipt camera shell so the capture surface reads like a
  Maintainiac receipt camera instead of a vague generic phone camera.
- Replaced the generic native-mode subtitle with the actual native engine
  contract shown to the user-facing shell: CameraX receipt controls on Android
  and AVFoundation receipt controls on iOS.
- Added a compact bottom next-step strip so users know what happens after the
  shutter: assisted mode sends them to receipt text/business-personal-mixed
  review, while manual mode keeps the photo attached for manual entry.
- Reworded the bottom mode pills from ambiguous capture/storage language to
  receipt-specific labels: Receipt assist / Next reviews text, Manual receipt /
  Save photo only, and Backup size instead of Proof size.
- Kept settings visible in the top bar and kept manual shutter capture available
  regardless of guidance state.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native shell preview/control geometry
  and review handoff speed so the receipt stays visually dominant, controls do
  not read as a hidden drawer, and accepted photos move cleanly toward the
  parsed receipt review.

### Receipt Camera Reopen Pass 782: Review Save-Space Action Copy Guard Batch

Status: complete.

What changed:
- Renamed the single-photo review action from `Proof Size` to `Save Space` so
  the post-capture review surface uses normal user language instead of
  developer/storage jargon.
- Kept the dedicated proof/data-saver mode intact; this pass only changed the
  compact single-photo action row that appears immediately after capture.
- Added a guard proving the preview action row contains `Save Space` and does
  not reintroduce `Proof Size` as that row label.
- Revalidated the native shell test because the capture screen and immediate
  review controls are the same user-facing camera flow.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing the capture-to-filled-review
  handoff status and any remaining copy that could make a user think the photo
  was accepted but the app returned them to the wrong screen.

### Receipt Camera Reopen Pass 783: Filled Review Opening State Copy Batch

Status: complete.

What changed:
- Reworded the persistent review continue button's saving state from
  `Opening Review` to `Opening Details`.
- Kept the tooltip and semantic label as `Opening filled receipt review`, so
  accessibility and diagnostics still say exactly which screen is opening.
- Added a guard proving the common review control still carries the explicit
  filled-review wording while the visible button avoids vague review language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking the async receipt-read
  status path and accepted-photo callbacks for any remaining path that can feel
  like the flow returned to the attachment/home surface instead of the filled
  receipt details.

### Receipt Camera Reopen Pass 784: Filled Review Handoff Button Clarity Batch

Status: complete.

What changed:
- Reworded the preparing-state button in the receipt read handoff panel from
  `Go To Review` to `Show Filled Review`.
- Kept the ready-state `Review Details` label intact for when OCR/parsing has
  already produced filled receipt details.
- Refreshed stale source guards around long-receipt guidance and photo-order
  copy so tests assert the current top-to-bottom receipt section behavior
  instead of old wording.
- Verified the accepted-photo path still announces app-assisted receipt fill
  handoff before OCR work finishes.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "reviewed receipt photos announce app fill handoff safely"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is camera review reliability around
  lifecycle/async callbacks so disposed review screens cannot call back into
  stale context while OCR/image preparation work is still running.

### Receipt Camera Reopen Pass 785: Remove-Photo Dialog Lifecycle Guard Batch

Status: complete.

What changed:
- Hardened `_confirmRemoveCurrentPhoto` so it refuses to open or return a
  positive remove decision when the receipt review screen is no longer active.
- Added a post-dialog `_reviewWorkActive` check before the remove result is
  honored, matching the stronger continue/exit dialog lifecycle pattern.
- Strengthened the async lifecycle guard test so remove-photo confirmation is
  covered alongside post-frame preview work, generated edit cleanup, and
  save/continue close guards.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is image-prep failure recovery: timeout,
  failed cleanup, and partially prepared photos should leave the review usable
  and should not strand the user without recoverable receipt proof.

### Receipt Camera Reopen Pass 786: Failed Prep Artifact Cleanup Batch

Status: complete.

What changed:
- Tracked app-generated OCR/backup prep artifacts during receipt review save.
- On timeout, generic prep failure, or lifecycle interruption before the review
  result is returned, the app now best-effort deletes generated prep artifacts
  while leaving the original staged receipt photos untouched.
- Added source guards proving generated prep artifacts are tracked, cleaned on
  failed prep paths, and skipped when they are still one of the active review
  photos.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the native fallback
  boundary so stock/phone-camera backup remains explicitly labeled as fallback
  and cannot silently replace Maintainiac's receipt camera path.

### Receipt Camera Reopen Pass 787: Explicit Backup Camera Method Boundary Batch

Status: complete.

What changed:
- Added `ReceiptImagePicker.takeBackupReceiptPhotoSet()` so the phone/stock
  camera path is named as a backup-only capture surface in code.
- Moved the initial receipt import fallback and review add-photo fallback paths
  to the explicit backup method.
- Kept `takeReceiptPhotoSet()` as a wrapper for compatibility, but source guards
  now require active receipt fallback flows to call the explicit backup method.
- Revalidated both native-first source guards: initial receipt import and review
  add-photo still try Maintainiac native receipt camera before any backup camera
  surface.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_image_picker.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_image_picker.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt import uses Maintainiac native camera before any fallback"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "review add-photo flow also uses native capture before fallback"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is capture device-capability/settings
  handoff: make sure native camera sessions carry the settings needed for
  exposure, tap focus, zoom, long receipt guidance, and older-device safety.

### Receipt Camera Reopen Pass 762: Post-Capture Review Copy Alignment Batch

Status: complete.

What changed:
- Renamed post-capture add-photo actions to `Add Another Photo` in the review
  controls and overflow menu so a user understands they are continuing the same
  receipt, not starting a different receipt flow.
- Renamed the review-side save-space control to `Proof Size` and the mode header
  to `Saved Receipt Proof` so the screen describes the saved receipt proof
  instead of sounding like OCR is being run on a compressed image.
- Kept the explicit `Next: Attach + Review Details` handoff intact: accepted
  photos still point the user toward the filled receipt review with store, date,
  total, tax, item prices, and business/personal/mixed decisions.
- Left broader section-label/save-action language alone for a later flow-wide
  copy pass instead of sweeping unrelated receipt-entry paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the remaining add-photo
  language in section labels/save actions and checking whether any review-copy
  path still implies the user returns to the expense home screen instead of
  opening the filled receipt review.

### Receipt Camera Reopen Pass 763: Long-Receipt Continuation Copy Batch

Status: complete.

What changed:
- Updated post-capture review, section guidance, quality warnings, OCR recovery
  copy, and help text to say `Add Another Photo` when the user is continuing an
  existing receipt or adding the next long-receipt section.
- Kept the original `Add Receipt Photo` wording only where it still means the
  initial receipt-form action or retrying that initial camera entry point.
- Preserved the `Add Next Receipt Photo` wording for explicit top-to-bottom
  long-receipt sequencing prompts.
- Strengthened the handoff language so accepted photos keep pointing to the
  filled receipt review instead of sounding like a return to the expense form.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking native capture/preview
  latency and lifecycle wording/tests around interrupted captures so the user
  never loses a captured photo or gets trapped in the review surface.

### Receipt Camera Reopen Pass 764: Review Close Async-Gap Hardening Batch

Status: complete.

What changed:
- Moved the receipt-review `Navigator.of(context)` lookup out of the top of
  `_continue()` and down to the final guarded close moment after async storage,
  OCR-source preparation, and stitch handoff work finishes.
- Added an explicit `mounted`, disposed, and closing guard immediately before
  popping the review screen so accepted photos do not try to close through a
  stale context after lifecycle changes.
- Kept the existing close-state cleanup intact: stitch debounce cancellation,
  preview/key in-flight clearing, saving/opening/crop state reset, and safe
  close flagging still happen before the result is returned.
- Added regression coverage proving the final navigator lookup is guarded and
  lifecycle cleanup remains present.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native-camera/review bridge
  latency path: identify any expensive synchronous work between shutter return,
  review open, and first preview paint, then make sure the user gets an instant
  review surface while heavier OCR/proof work stays deferred.

### Receipt Camera Reopen Pass 765: Review First-Paint Latency Guard Batch

Status: complete.

What changed:
- Moved saved-proof/data-saver preview generation behind a post-frame scheduler
  instead of starting it directly from `build()` when proof-size mode is open.
- Added `_scheduleDataSaverPreviewWork()` so the proof preview only starts after
  the first frame and only if the user is still on the same review photo and
  still in proof-size mode.
- Kept quality checks and regular storage preview work deferred, preserving the
  instant review-surface goal after native shutter return.
- Added regression coverage for the data-saver post-frame scheduler, mode guard,
  and deferred proof-preview handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture shell controls and
  settings parity: verify visible settings/help/flash/back controls stay
  app-owned and that tap-focus, pinch zoom, exposure reset, and fallback
  messaging remain covered without returning to the stock phone camera UI.

### Receipt Camera Reopen Pass 766: Native Shell Proof-Size Wording Batch

Status: complete.

What changed:
- Updated the app-owned native receipt camera shell fallback storage pill from
  generic `Save space` to `Proof size` so capture UI matches the review-side
  saved-proof language.
- Added widget coverage proving the shell still keeps the receipt preview
  primary, keeps Settings/back/light controls in the app-owned top bar, supports
  tap focus, pinch zoom, brightness reset, and shows the long-receipt ghost
  guide.
- Added coverage proving the shell no longer displays the generic `Save space`
  label when no custom quality label is provided.
- Re-ran native Android/iOS bridge guards to keep CameraX/AVFoundation settings,
  tap-focus, pinch-zoom, exposure, and stock-camera rejection contracts intact.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_shell_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is capture-source diagnostics and
  user-facing failure recovery: make sure unavailable native camera, permission
  blocked, fallback camera, and interrupted capture paths all tell the user what
  happened without implying the app silently deleted their receipt photo.

### Receipt Camera Reopen Pass 767: Review Add-Photo Recovery Copy Batch

Status: complete.

What changed:
- Updated the already-open review add-photo failure path to tell the user to
  try `Add Another Photo` again instead of sending them back mentally to the
  initial `Add Receipt Photo` entry action.
- Updated review-side permission-blocked and native-camera-could-not-open
  recovery copy to use the same `Add Another Photo` wording.
- Left the initial receipt-entry path alone where `Take Receipt Photo` and
  `Add Receipt Photo` still describe starting the receipt capture flow.
- Revalidated interrupted-capture, native-shell, and review-flow tests so the
  recovery language remains consistent with the app-owned camera and review
  handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "review add-photo flow also uses native capture before fallback"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_shell_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is source-file hygiene around receipt
  camera modules: identify overlarge camera/review files and split only where
  it reduces risk without changing behavior.

### Receipt Camera Reopen Pass 768: Native Shell Bottom-Control Split Batch

Status: complete.

What changed:
- Split the native receipt camera shell bottom-control helpers into
  `receipt_native_camera_shell_bottom_controls.dart` as a `part` file.
- Kept `ReceiptNativeCameraShell` behavior unchanged while reducing the main
  shell file from 878 lines to 657 lines; the new bottom-controls part is 224
  lines.
- Preserved the app-owned shell controls: Settings/back/light top bar, receipt
  shutter, proof-size pill, bottom mode pills, and the lighter vignette overlay.
- Revalidated shell and native bridge tests after the split so CameraX,
  AVFoundation, tap-focus, pinch-zoom, exposure, and stock-camera rejection
  contracts stayed intact.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart test/receipt_native_camera_shell_test.dart`
- `wc -l lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is splitting the remaining native shell
  guidance/preview helpers or moving on to the larger review-control split,
  whichever is safer after checking dependencies.

### Receipt Camera Reopen Pass 769: Native Shell Guidance Split Batch

Status: complete.

What changed:
- Split native receipt-camera guidance chips and the long-receipt ghost overlay
  into `receipt_native_camera_shell_guidance.dart` as a `part` file.
- Brought the main `receipt_native_camera_shell.dart` under the local 500-line
  target: 457 lines after the split.
- Kept the shell behavior unchanged: app-owned top controls, preview tap-focus,
  pinch zoom, brightness/exposure control, long-receipt ghost guide, bottom
  receipt shutter, and proof-size pill remain wired through the same public
  `ReceiptNativeCameraShell` API.
- Revalidated native shell and bridge tests to keep CameraX/AVFoundation parity
  intact.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_shell_test.dart`
- `wc -l lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the larger post-capture review
  controls file: identify a safe self-contained split before adding more review
  behavior.
