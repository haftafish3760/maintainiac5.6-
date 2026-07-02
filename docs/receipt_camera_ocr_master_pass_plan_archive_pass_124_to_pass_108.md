# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 124: Review Surface Real-Device Polish Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 124: Review Surface Real-Device Polish Batch

Status: completed.

Goal:
- Keep the receipt photo itself dominant and fully reviewable on real phone
  screens by preventing the bottom control tray from covering the bottom of the
  receipt image.

Completed:
- Replaced the separate hard-coded review-image bottom padding values with a
  single padding calculation tied to the actual capped bottom controls height.
- The photo preview surface now reserves the same height as the visible controls
  plus a small gutter.
- The crop surface now uses the same controls-aware bottom padding, so crop
  handles and receipt edges are less likely to be hidden behind the tray.
- Added source guards proving the review surface padding is derived from
  `_reviewBottomControlsMaxHeight(context)` instead of a stale fixed value.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 123: Camera UI Device Batch

Status: completed.

Goal:
- Tighten the first photo-review decision surface so the next step is obvious
  on a phone-sized screen without relying on tiny icons or vague scan wording.

Completed:
- Changed the single-photo review prompt to explicitly say to tap Add Another
  Photo when the receipt continues, otherwise tap Next.
- Changed the multi-photo prompt to explicitly say Add Next Photo for long
  receipts, otherwise Next moves into the filled receipt review.
- Changed the multi-photo add action label from Add Photo to Add Next Photo so
  it matches the long-receipt workflow instead of sounding like a generic
  gallery action.
- Changed the retake action to Retake Clearer Photo when the selected quality
  check indicates the photo needs review.
- Added source guards to keep the explicit Add Another Photo/Add Next Photo
  language from regressing back to vague review wording.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

### Receipt Camera Reopen Pass 122: First-Use Camera Setup

Status: completed.

Goal:
- Give users a short first-use explanation of receipt photo capture without
  turning the camera flow into a long setup wizard.

Completed:
- Replaced the silent `cameraSetupComplete` flip with a compact first-use
  receipt camera intro.
- The intro appears only before the first receipt photo capture.
- The user can continue directly to the camera or open Receipt Settings first.
- The intro covers clear photo first, long receipt sections, app-assisted
  review, saved proof size, and privacy/storage behavior.
- The intro shows the effective camera runtime summary without raw device model,
  RAM, CPU, or SDK details.
- Added source guards for first-use gating, settings handoff, intro actions,
  and privacy-safe copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 121: Capability-Based Camera Settings

Status: completed.

Goal:
- Make receipt camera settings resolve to safe runtime behavior based on device
  capability, not raw phone model names or user toggles alone.

Completed:
- Added `ReceiptCameraRuntimeProfile` as the effective camera behavior contract.
- Added `ReceiptDeviceCapability.cameraRuntimeProfileFor(...)` so guidance,
  assisted start, auto capture, long receipt tips, resolution tier, shot count,
  timing, and saved-proof size are derived from capability.
- Older/light devices keep live guidance but are forced manual-first for camera
  responsiveness, even if a heavier setting was requested.
- Medium devices can use guided manual capture but hold back auto capture.
- Heavyweight devices can use guided auto capture when requested.
- Added `effectiveCameraRuntimeProfile` to receipt capture settings.
- Added a plain receipt scanner settings summary that explains effective camera
  behavior without showing raw model, RAM, CPU, or Android SDK details.
- Added tests for older-phone gating, heavyweight auto capture, settings store
  exposure, and privacy-safe settings copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 120: Live Guidance Tone And Timing

Status: completed.

Goal:
- Make live receipt guidance short, plain, and useful without developer-status
  wording or messages that imply capture is blocked.

Completed:
- Replaced auto-capture status labels like `Waiting:` and `Check:` with direct
  action labels.
- Kept guidance focused on what the user should do next: add light, reduce
  glare, tap receipt text, show the full receipt, move closer, or hold steady.
- Changed capture guidance copy to say capture still works instead of sounding
  like the app is blocking the shutter.
- Tightened assisted-capture labels such as `Receipt Assist`, `Check Focus`,
  and `Final Shot`.
- Added tests that reject `Waiting:`/`Check:` auto-capture labels and guard the
  plain-language replacements.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_live_analysis.dart lib/shared/widgets/receipt_capture/receipt_camera_assist.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 119: Manual Shutter Always Works

Status: completed.

Goal:
- Make manual shutter taps feel immediate and independent from auto-capture
  guidance.

Completed:
- Audited the manual and assisted capture paths.
- Kept manual shutter free from mode/guidance gating.
- Split camera settle timing into a short manual delay and a longer assisted
  delay.
- Manual shutter now primes focus/exposure briefly, then starts capture without
  waiting on the full guided steadying delay.
- Assisted capture keeps the longer settle delay because that mode is explicitly
  trying to choose the best frame.
- Added source guards proving manual and assisted capture use separate settle
  delays and that manual capture still calls `_capturePhoto()` directly.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 118: Brightness And Exposure Baseline

Status: completed.

Goal:
- Stop the in-app receipt camera from making hidden exposure assumptions that
  can diverge from the phone's native camera behavior.

Completed:
- Audited the in-app camera exposure setup.
- Kept focus mode and exposure mode on native auto behavior.
- Removed the forced positive exposure-compensation tier defaults.
- Kept tap-to-exposure best effort, so the user can still tap receipt text to
  guide the camera when the device supports it.
- Added source guards proving exposure compensation stays neutral and does not
  reintroduce S9/S24/S25-style tier offsets.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 117: Pinch Zoom And Tap Focus Contract

Status: completed.

Goal:
- Make the in-app receipt camera's pinch zoom and tap focus/exposure behavior
  match what the user sees on the cover-cropped camera preview.

Completed:
- Audited the live camera gesture layer.
- Kept pinch-to-zoom on the full preview tap layer with queued zoom updates.
- Kept tap-to-focus/tap-to-exposure best effort and nonblocking.
- Corrected tap-focus coordinate mapping so focus/exposure points account for
  the same cover-cropped preview size used by the visible camera image.
- Added source guards proving tap focus uses `controller.value.previewSize`,
  rendered preview scale, and crop offset instead of raw screen-only
  coordinates.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 116: Capture Surface Edge Layout

Status: completed.

Goal:
- Keep visible capture/review controls anchored to expected screen edges and
  avoid a floating cluster over the receipt image.

Completed:
- Audited the active camera and post-capture review surfaces.
- Kept the live camera top bar edge anchored with back on the left and settings
  plus torch on the right.
- Reworked the photo review top bar so the back action stays left, the title is
  a constrained left-aligned chip, and hide/menu actions stay right.
- Removed spacer-centered review-title behavior that could make controls feel
  like they were sitting in the middle of the receipt.
- Added a source guard that proves the review top controls stay ordered
  left-title-right and do not reintroduce `Spacer` centering.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 115: Camera Permission And Fallback UX

Status: completed.

Goal:
- Make camera permission, scanner fallback, canceled camera, and unavailable
  camera/plugin states understandable and recoverable without developer jargon.

Completed:
- Improved scanner fallback messaging so users know the phone camera opens next
  and receipt capture can continue.
- Added plain camera permission handling for both first receipt photo and
  add-another-photo flows.
- Added canceled-camera messaging that confirms no receipt photo was added.
- Added practical recovery copy: try the camera again or choose an existing
  receipt image.
- Added tests that guard the permission, cancel, scanner fallback, and recovery
  wording.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 114: Native Capture And Long Receipt Overlay Decision

Status: completed.

Goal:
- Resolve the conflict between native phone-camera image quality and
  Maintainiac's desire for a long-receipt ghost alignment overlay.

Completed:
- Kept production add-photo capture on the native phone camera path for image
  quality and exposure trust.
- Added a pre-camera long receipt alignment guide that shows the bottom of the
  previous receipt section before opening the external camera.
- Explained to the user that Maintainiac cannot draw over the phone camera
  screen, so the preview is the alignment reference.
- Kept post-capture order review, stitching, manual overlap, and ordered OCR
  fallback as the Maintainiac-controlled part of the long receipt workflow.
- Added tests proving the alignment guide, native-camera note, and `Open
  Camera` action exist.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 113: Expense Receipt Review Detail Settings Contract

Status: completed.

Goal:
- Put the expense receipt simple-vs-detailed review choice where users expect it
  during receipt photo setup, while reusing the existing expense setting that
  already drives the receipt review screen.

Completed:
- Added optional `ExpenseSettingsScope.maybeOf` access so shared receipt widgets
  can use expense settings without crashing outside the expense area.
- Added `Expense Receipt Review Detail` to Expense Receipt Settings.
- Added plain choices for `Show Prices Only` and `Show Full Item Details`.
- Kept the setting backed by `ExpenseReceiptReviewStyle` so the receipt entry
  screen and receipt photo settings share one source of truth.
- Added tests for the settings wording and persisted review-style default.

Verification:
- `dart format lib/shared/state/expense_settings_store.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart test/expense_settings_store_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_settings_store_test.dart`
- `flutter analyze lib/shared/state/expense_settings_store.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart test/expense_settings_store_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 112: Master Receipt System Spec Reset

Status: completed.

Goal:
- Create a single state-of-art receipt system spec that maps the remaining work
  against Adobe Scan, Microsoft Lens, Expensify, Genius Scan, Scanner Pro,
  CamScanner, and Maintainiac-specific requirements.

Completed:
- Added `docs/receipt_camera_ocr_state_of_art_spec.md`.
- Raised new receipt work tracking to a 300-pass cap while reporting passes as Pass NN.
- Mapped remaining work across camera, image cleanup, long receipts, OCR,
  parsing, classification, PDF/text extraction, diagnostics, storage, and QA.

Verification:
- Spec file exists and is linked from this master plan.

### Receipt Camera Reopen Pass 111 of 150: Camera Exit Lifecycle Guard

Status: completed.

Goal:
- Reduce the risk of the legacy camera surface throwing a disposed-preview
  crash when the user backs out or finishes capture.

Completed:
- Changed the camera close path so the route is popped before the detached
  camera controller is disposed.
- Changed the camera result path so successful capture also pops before
  disposing the detached controller.
- Added source guards proving both close and result paths pop before controller
  disposal.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 110 of 150: Photo Review Control Height Caps

Status: completed.

Goal:
- Keep the post-capture receipt preview dominant on tall phones by capping the
  bottom control tray height by mode.

Completed:
- Replaced the purely proportional bottom-control max height with mode-specific
  caps.
- Kept single-photo preview smallest, gave multi-photo preview room for
  thumbnails, and bounded crop, order, stitch, and data-saver modes.
- Added source guards proving the preview, crop, order, stitch, and data-saver
  caps stay in place.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 109 of 150: Real-Device QA Contract Alignment

Status: completed.

Goal:
- Make the real-device checklist and product standard match the current
  app-assisted camera workflow so S24/S9/iPhone testing judges the right
  behavior.

Completed:
- Updated the real-device script goal from `let Maintainiac read it` to
  filling a receipt review the user classifies and saves.
- Updated single-photo expected behavior so the primary action is `Next` to
  fill the receipt review.
- Updated long-receipt fallback wording to top-to-bottom photo review instead
  of separate-photo reading.
- Renamed the app-assisted manual test flow to `App-Assisted Filled Receipt
  Review`.
- Updated the product standard so the default user-facing next step is filling
  the receipt review.
- Added test guards that read both the product standard and real-device script
  so stale `read receipt` wording does not drift back into QA instructions.

Verification:
- `dart format test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.

### Receipt Camera Reopen Pass 108 of 150: Stitch Result Review Metadata Alignment

Status: completed.

Goal:
- Make the underlying stitch result labels and fallback warnings match the
  visible long-receipt review workflow, while proving fallback preserves ordered
  OCR source paths.

Completed:
- Updated `ReceiptStitchResult.summaryLabel` to use receipt review language
  instead of app-assisted reading language.
- Updated `ReceiptStitchResult.detailLabel` to describe photos prepared for
  receipt review.
- Updated oversized/exception stitch fallback warnings so they say `Next` will
  review photos separately.
- Added a stitching test assertion proving fallback OCR source paths stay in
  top-to-bottom input order.
- Kept PDF-specific app-assisted reading copy untouched because PDF work is
  paused until camera/photo review is stable.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_image_processor.dart test/receipt_stitching_test.dart`
- `flutter test test/receipt_stitching_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_image_processor.dart test/receipt_stitching_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera-only focus:
- Gather device QA evidence for remaining camera/review gaps, then keep
  hardening the receipt review path before moving to PDF or maintenance parsing.
