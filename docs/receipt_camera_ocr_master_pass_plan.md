# Receipt Camera OCR Master Pass Plan

This is the working execution plan for making Maintainiac's receipt capture, OCR, parsing, review, and expense intelligence state-of-the-art.

The plan is intentionally numbered. Every receipt-hardening pass should be reported as `Pass NN` after the state-of-art spec reset, so progress is easy to track and the work does not drift.

## Progress Rule

- Always name the current pass as `Pass NN` after this update. Existing original pass headings may still say `of 40`, `of 55`, or `of 150` until they are touched, but new progress reporting should use the 300-pass cap.
- Keep each pass shippable: format, analyze, and run focused tests before calling it done.
- Bundle related changes inside each pass, but do not mix unrelated domains.
- UI passes come first so the product flow can be judged on the S24 Ultra before deeper parser work.
- Do not push a phone build after every tiny tweak.
- For UI work, push to the S24 Ultra after a meaningful batch of roughly 3-4 UI passes, or sooner only when the user asks for device review.
- Backend/parser-only passes do not require a phone install unless the change affects visible workflow.
- Continue through receipt passes automatically until the receipt camera/OCR/parser flow is complete or a real product/blocking decision is required.
- Do not take phone screenshots, inspect the device UI, or push device builds unless the user explicitly asks for that action.

## Benchmark Responsibilities

- **Adobe Scan lane:** image enhancement, cleanup, crop, perspective, shadow reduction.
- **Microsoft Lens lane:** camera experience, fast capture, edge controls, no clutter.
- **Expensify lane:** OCR/parser intelligence for merchant, date, tax, total, lines, expense creation.
- **Scanner Pro lane:** polish, animation, consistency, premium feel.
- **Genius Scan lane:** long receipts, multi-photo capture, batch order, stitching/fallback.
- **Google Drive Scanner lane:** simplicity, no fifty-button clutter, obvious path.
- **CamScanner lane:** document scanning engine ideas, filters, batch scanning, automatic document help.
- **Maintainiac lane:** business/personal/mixed, simple/detailed modes, split tax, local-first storage, profiles, vehicles, inventory, diagnostics, privacy.

## Current Status

- **Pass 01 of 40: App-Assisted Handoff** is complete.
- **Pass 02 of 40: Camera Shell Layout** is complete.
- **Pass 03 of 40: Camera Interaction Basics** is complete.
- **Pass 04 of 40: First-Use Camera Setup** is complete.
- **Pass 05 of 40: Photo Review Default Surface** is complete.
- **Pass 06 of 40: Photo Review Tool Modes** is complete.
- **Pass 07 of 40: S24 UI Review Batch 1** is complete.
- **Pass 08 of 150: Live Guidance Copy And States** is complete.
- **Pass 09 of 150: Auto Capture Confidence** is complete.
- **Pass 10 of 150: Camera Capability Defaults** is complete.
- **Pass 11 of 150: Capture Diagnostics** is complete.
- **Pass 12 of 150: OCR Source Pipeline Audit** is complete.
- **Pass 13 of 150: Adobe-Style Enhancement Pass 1** is complete.
- **Pass 14 of 150: Adobe-Style Enhancement Pass 2** is complete.
- **Pass 15 of 150: Crop And Perspective Foundation** is complete.
- **Pass 16 of 150: Image Save-Space Preview** is complete.
- **Pass 17 of estimated 55: Long Receipt Capture Flow** is complete.
- **Pass 18 of estimated 55: Capability-Gated Edge Detection Overlay** is complete.
- **Pass 19 of estimated 55: Multi-Photo Review And Ordering** is complete.
- **Pass 20 of estimated 55: Automatic Stitching Core** is complete.
- **Pass 21 of estimated 55: Manual Stitch Adjustment** is complete.
- **Pass 22 of estimated 55: Receipt Reading Handoff After Stitch Review** is complete.
- **Pass 23 of estimated 55: Receipt Review Classification Landing** is complete.
- **Pass 24 of estimated 55: Receipt Tax And Split Allocation Review** is complete.
- **Pass 25 of estimated 55: Receipt Camera Device-Safe Limits** is complete.
- **Pass 26 of estimated 55: Receipt Photo Quality And Auto-Capture Tuning** is complete.
- **Pass 27 of estimated 55: Receipt Review Action Surface** is complete.
- **Pass 28 of estimated 55: Receipt Review Flow Routing** is complete.
- **Pass 29 of estimated 55: Long Receipt Section Guardrails** is complete.
- Next pass is **Pass 30 of estimated 55: Receipt Review Device UI Batch**.
- **Pass 30 of estimated 55: Receipt Review Device UI Batch** is deferred until the user explicitly asks for an S24 install.
- **Pass 31 of estimated 55: Separate OCR Fallback Guardrails** is complete.
- **Pass 32 of estimated 55: OCR Diagnostics Hardening** is complete.
- **Pass 33 of estimated 55: Parser Field Confidence Hardening** is complete.
- **Pass 34 of estimated 55: Parser Review Failure Reasons** is complete.
- **Pass 35 of estimated 55: Parser Review UI Guidance** is complete.
- **Pass 36 of estimated 55: Privacy-Safe Parser Health Metrics** is complete.
- **Pass 37 of estimated 55: Receipt Backup Image Pipeline Audit** is complete.
- **Pass 38 of estimated 55: Receipt Proof Storage And Backup Metadata** is complete.
- **Pass 39 of estimated 55: Receipt PDF OCR Safety Review** is complete.
- **Pass 40 of estimated 55: Receipt Import Failure Recovery** is complete.
- **Pass 41 of estimated 55: Receipt Review Classification Completion** is complete.
- **Pass 42 of estimated 55: Receipt Data Saver Preview Completion** is complete.
- **Pass 43 of estimated 55: Receipt Save Readiness Guardrails** is complete.
- **Pass 44 of estimated 55: Saved Receipt Detail And Calendar Recovery** is complete.
- **Pass 45 of estimated 55: Receipt Calendar Add/Edit/Delete Diagnostics** is complete.
- **Pass 46 of estimated 55: Receipt Export Proof Bundle Readiness** is complete.
- **Pass 47 of estimated 55: Synthetic End-To-End Receipt Regression Matrix** is complete.
- **Pass 48 of estimated 55: Receipt Stitching And OCR Handoff Stress Matrix** is complete.
- **Pass 49 of estimated 55: Receipt Camera Capability And Low-End Device Stress Review** is complete.
- **Pass 50 of estimated 55: Receipt Review Route And Classification Contract** is complete.
- **Pass 51 of estimated 55: Receipt Data Saver Preview And OCR Source Contract** is complete.
- **Pass 52 of estimated 55: Receipt Saved Proof Lifecycle And Cleanup Audit** is complete.
- **Pass 53 of estimated 55: Receipt Final Synthetic Stress And Coverage Review** is complete.
- **Pass 54 of estimated 55: Receipt Real-Device Readiness Checklist And Manual Test Script** is complete.
- **Pass 55 of estimated 55: Receipt Remaining Gaps And PDF/Invoice Bridge Decision** is complete.
- Next receipt step is controlled real-device validation using `docs/receipt_real_device_test_script.md`.
- **PDF Pass 56 of up to 200: Generated PDF Boundary Validation** is complete.
- **PDF Pass 57 of up to 200: Invoice PDF Send/Archive Lifecycle Audit** is complete.
- **PDF Pass 58 of up to 200: Incoming Invoice/Document PDF Routing** is complete.
- **PDF Pass 59 of up to 200: Generated PDF Preview And Share Failure Recovery** is complete.
- **PDF Pass 60 of up to 200: Invoice PDF Delivery Metadata And Audit Trail** is complete.
- **PDF Pass 61 of up to 200: Invoice PDF Firestore/Backup Shape Audit** is complete.
- **PDF Pass 62 of up to 200: Invoice PDF Form Action Wiring** is complete.
- **PDF Pass 63 of up to 200: Invoice PDF Preview Action Callback Seam** is complete.
- **PDF Pass 64 of up to 200: Invoice PDF Preview Surface Decision And Wiring** is complete.
- **PDF Pass 65 of up to 200: PDF Preparation Failure And Retry Audit** is complete.
- **PDF Pass 66 of up to 200: PDF Delivery Event Semantics Cleanup** is complete.
- Real-device receipt testing exposed receipt-flow blockers, so PDF work is paused until the camera/photo review path is stable again.
- **Receipt Camera Reopen Pass 89 of 150: Native Capture Boundary And Maintenance-Safe Entry Point** is complete.
- **Receipt Camera Reopen Pass 90 of 150: Review Surface Back/Next Behavior** is complete.
- **Receipt Camera Reopen Pass 91 of 150: Review Surface Control Density** is complete.
- **Receipt Camera Reopen Pass 92 of 150: Photo Quality Framing Tolerance** is complete.
- **Receipt Camera Reopen Pass 93 of 150: Attached Proof Clarity And Metadata Cleanup** is complete.
- **Receipt Camera Reopen Pass 94 of 150: Long-Receipt Photo Removal Safety** is complete.
- **Receipt Camera Reopen Pass 95 of 150: Photo Review Remove Confirmation** is complete.
- **Receipt Camera Reopen Pass 96 of 150: Edited Photo Preview Cleanup** is complete.
- **Receipt Camera Reopen Pass 97 of 150: Retake/Remove Preview Cache Cleanup** is complete.
- **Receipt Camera Reopen Pass 98 of 150: Production Native Camera Routing Guard** is complete.
- **Receipt Camera Reopen Pass 99 of 150: Newly Added Receipt Section Focus** is complete.
- **Receipt Camera Reopen Pass 100 of 150: App-Assisted Re-Read Line Replacement** is complete.
- **Receipt Camera Reopen Pass 101 of 150: Reviewed Photo Proof Read State** is complete.
- **Receipt Camera Reopen Pass 102 of 150: Stable Photo Proof IDs** is complete.
- **Receipt Camera Reopen Pass 103 of 150: Review Back Action And Next-Step Copy** is complete.
- **Receipt Camera Reopen Pass 104 of 150: Native Capture Regression Guard** is complete.
- **Receipt Camera Reopen Pass 105 of 150: Filled Review Handoff Copy** is complete.
- **Receipt Camera Reopen Pass 106 of 150: Empty Photo Review Recovery** is complete.
- **Receipt Camera Reopen Pass 107 of 150: Long Receipt Review Language Alignment** is complete.
- **Receipt Camera Reopen Pass 108 of 150: Stitch Result Review Metadata Alignment** is complete.
- **Receipt Camera Reopen Pass 109 of 150: Real-Device QA Contract Alignment** is complete.
- **Receipt Camera Reopen Pass 110 of 150: Photo Review Control Height Caps** is complete.
- **Receipt Camera Reopen Pass 111 of 150: Camera Exit Lifecycle Guard** is complete.
- **Receipt Camera Reopen Pass 112: Master Receipt System Spec Reset** is complete.
- **Receipt Camera Reopen Pass 113: Expense Receipt Review Detail Settings Contract** is complete.
- **Receipt Camera Reopen Pass 114: Native Capture And Long Receipt Overlay Decision** is complete.
- **Receipt Camera Reopen Pass 115: Camera Permission And Fallback UX** is complete.
- **Receipt Camera Reopen Pass 116: Capture Surface Edge Layout** is complete.
- **Receipt Camera Reopen Pass 117: Pinch Zoom And Tap Focus Contract** is complete.
- **Receipt Camera Reopen Pass 118: Brightness And Exposure Baseline** is complete.
- **Receipt Camera Reopen Pass 119: Manual Shutter Always Works** is complete.
- **Receipt Camera Reopen Pass 120: Live Guidance Tone And Timing** is complete.
- **Receipt Camera Reopen Pass 121: Capability-Based Camera Settings** is complete.
- **Receipt Camera Reopen Pass 122: First-Use Camera Setup** is complete.
- **Receipt Camera Reopen Pass 123: Camera UI Device Batch** is complete.
- **Receipt Camera Reopen Pass 124: Review Surface Real-Device Polish Batch** is complete.
- **Receipt Camera Reopen Pass 125: Review Surface Tool Affordance Batch** is complete.
- **Receipt Camera Reopen Pass 126: Review Tool Mode Height And Scroll Batch** is complete.
- **Receipt Camera Reopen Pass 127: Review Continue Button Persistence Batch** is complete.
- **Receipt Camera Reopen Pass 128: Receipt Review Mode Transition Polish Batch** is complete.
- Next receipt step is **Receipt Camera Reopen Pass 129: Crop Mode Readability And Edge Controls Batch**.

### Receipt Camera Reopen Pass 128: Receipt Review Mode Transition Polish Batch

Status: completed.

Goal:
- Keep receipt-review mode switches predictable by preventing stale scroll
  positions from carrying between Review, Crop, Order, Match, and Save Space.

Completed:
- Added a mode-transition scroll reset so each tool mode starts at the top of
  its controls.
- Guarded the scroll reset so it only touches the controller when attached.
- Routed crop top-bar close through the shared review-mode switch.
- Routed crop cancel through the shared review-mode switch.
- Added source guards proving mode changes reset the tool scroll position and
  crop exits use the shared transition path.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 127: Review Continue Button Persistence Batch

Status: completed.

Goal:
- Keep the `Next` / receipt-review handoff action visible in tool modes even
  when the crop/order/match/save-space details need to scroll.

Completed:
- Passed the receipt-review tool scroll controller into the bottom-controls
  widget instead of wrapping the whole tray from the screen.
- Moved the visible scrollbar and scroll view inside the non-preview tool
  content area only.
- Added a persistent continue button below the scrollable tool details so the
  user does not have to hunt for `Next`.
- Preserved the waiting-for-stitch disable behavior and the saving spinner/copy
  on the persistent action.
- Added source guards proving the scrollbar appears before the persistent
  continue button and that the screen wires the scroll controller into the
  controls.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 126: Review Tool Mode Height And Scroll Batch

Status: completed.

Goal:
- Make capped tool trays usable on phone screens when crop/order/match/save-space
  controls are taller than the available review tray height.

Completed:
- Added a dedicated scroll controller for receipt-review tool controls.
- Wrapped non-preview review tool trays in a visible `Scrollbar` so scrollable
  controls are discoverable instead of silently clipped.
- Kept preview mode unwrapped so the primary review tray remains direct and
  compact.
- Disposed the tool-control scroll controller with the review screen lifecycle.
- Added source guards for the controller, disposal, and visible scrollbar
  contract.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 125: Review Surface Tool Affordance Batch

Status: completed.

Goal:
- Make secondary receipt-review tools understandable on a phone without relying
  on tooltip-only icon buttons.

Completed:
- Reworked the non-preview tool context row into a compact labeled action card.
- Replaced the icon-only Add/Retake/Remove controls in tool modes with labeled
  mini action buttons.
- The Add action now says Add Next Photo when multiple receipt sections exist
  and Add Another Photo for a single receipt section.
- Kept the action strip horizontally scrollable and compact so crop/order/match
  tools remain usable without taking over the receipt preview.
- Added guards that the tool-mode action row uses visible labels instead of
  tooltip-only icons.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

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

### Pass 05 of 40: Photo Review Default Surface

Status: complete.

Goal:
- Make post-capture review look like a professional document/photo review surface.

Scope:
- Receipt image gets 75-80 percent of the screen when possible.
- Controls are compact and edge/bottom anchored.
- Primary action is obvious: `Read Receipt`.
- Secondary tools: crop, stitch, save space, retake, remove, add photo.
- No scroll-trap control panel.

Done:
- User can see the full receipt and continue without hunting for a button.
- Single photo does not use multi-photo wording.
- Default review now uses a compact action rail with `Read Receipt` as the primary action.
- Default preview reserves more room for the receipt image and removes the old two-row status pill/tool-chip layout.

### Pass 06 of 40: Photo Review Tool Modes

Status: complete.

Goal:
- Keep advanced tools available without cluttering default review.

Scope:
- Crop mode.
- Stitch mode.
- Save-space preview mode.
- Photo order mode for multi-photo receipts.
- Clear exit/back behavior between modes.

Done:
- Each tool has one job.
- User can return to preview without losing work.
- Tool mode controls never hide the area they are supposed to edit.
- Multi-photo receipts now have an explicit Order mode with thumbnails and Move Up / Move Down controls.
- Tool modes now have clear headers and a direct Preview return action.
- Single-photo receipts are guarded from entering Order or Stitch modes.

### Pass 07 of 40: S24 UI Review Batch 1

Status: complete.

Goal:
- Install the UI batch to the S24 Ultra for real visual inspection.

Scope:
- Build debug app.
- Install to S24 only unless user asks otherwise.
- User reviews live camera, first-use setup, and photo review.

Done:
- User has a real-device build for the first UI batch.
- Any obvious UI regressions are listed before moving deeper.
- S24 Ultra target `192.168.1.117:38847` resolved `com.maintainiac/.MainActivity`.
- Installed app package shows `lastUpdateTime=2026-06-26 17:19:11`, `versionName=1.0.0`, `versionCode=1`.
- App was brought to foreground and confirmed focused as `com.maintainiac/.MainActivity`.
- Crash log buffer was empty after launch.
- Real-device screenshot captured at `/tmp/maintainiac_s24_pass07_second.png`.
- First automated screenshot was black because the device was on the lock/notification surface and focused on ChatGPT; this was not treated as an app UI pass.
- Remaining review note: user still needs to visually walk through live camera, first-use setup, and photo review on the S24 before the camera UI is considered accepted.

## Camera Guidance And Image Capture Track

### Pass 08 of 150: Live Guidance Copy And States

Status: complete.

Goal:
- Make live guidance useful, short, and not annoying.

Scope:
- Guidance for move closer/farther.
- Guidance for glare/shadow.
- Guidance for long receipts.
- Guidance for unreadable/small text.
- No fake promise if the app is not actually detecting something.

Done:
- Guidance explains what the user should do next.
- Guidance never blocks manual capture.
- Live guidance now uses plain action wording for light, glare, focus, framing, small text, long receipts, and possible cut-off sections.
- Guidance no longer claims the app can see receipt edges when the current signal is only a best-effort framing/readability estimate.
- Manual shutter copy stays explicit: capture is allowed even when guidance is unsure.

### Pass 09 of 150: Auto Capture Confidence

Status: complete.

Goal:
- Make auto capture excellent enough to trust, but never overconfident.

Scope:
- Stability threshold.
- Focus/readability threshold.
- Brightness/contrast threshold.
- Minimum hold time before capture.
- Manual shutter remains available.

Done:
- Auto capture does not fire while user is still aligning.
- Auto capture can be turned off.
- Auto capture now uses a stricter policy than manual capture, including minimum focus, contrast, text-band, framing, hold-time, and stable-frame thresholds.
- Auto capture readiness badge now uses the same stricter gate as the actual auto-capture trigger.
- Manual shutter remains available even when the strict auto-capture gate is not ready.

### Pass 10 of 150: Camera Capability Defaults

Status: complete.

Goal:
- Use device capability in the background to choose sensible defaults.

Scope:
- Device tier.
- Camera capability.
- Low-storage state.
- OCR/parser workload limits.
- Keep device details out of normal UI.

Done:
- S9-class phones get safer defaults.
- S24/S25-class phones can do more local work.
- User sees simple modes, not creepy hardware details.
- Camera controller resolution fallbacks are driven by the background capability tier.
- Capability tests cover light, medium, and heavyweight capture defaults.
- Settings tests guard against exposing raw model/RAM/CPU/SDK details in normal receipt camera UI.

### Pass 11 of 150: Capture Diagnostics

Status: complete.

Goal:
- Record privacy-safe camera/capture health.

Scope:
- Capture started/completed/abandoned.
- Manual vs auto capture.
- Focus/readability score buckets.
- Retake count.
- Camera errors.
- No private image content.

Done:
- Command One can eventually show capture failure rates without seeing receipts.
- Privacy-safe receipt events now include capture started/completed/abandoned/failed event types.
- Capture diagnostics store only mode/outcome, capability tier, focus/readability buckets, section count, retake count, duration, and safe error kind.
- Receipt privacy health snapshots now expose capture success/failure/abandonment rates and bucket counts for Command One.

## Image Cleanup Track

### Pass 12 of 150: OCR Source Pipeline Audit

Status: complete.

Goal:
- Guarantee OCR reads the best prepared image before save-space copies.

Scope:
- Original capture.
- Prepared OCR source.
- Enhanced grayscale/contrast source.
- Saved backup proof.
- Cleanup of temporary files.

Done:
- Tests prove OCR source comes before backup optimization.
- Photo review prepares OCR source images before save-space copies.
- Saved backup copies are optimized from prepared images, but OCR still receives the prepared/stitch source paths.
- Cleanup now explicitly preserves every final OCR source path until the caller reads it and performs temporary OCR cleanup.

### Pass 13 of 150: Adobe-Style Enhancement Pass 1

Status: complete.

Goal:
- Improve receipt readability before OCR.

Scope:
- Grayscale.
- Contrast normalization.
- Brightness correction.
- Basic shadow handling.
- Paper tint reduction.

Done:
- Good receipt photos become cleaner without destroying text.
- OCR prep now evaluates multiple enhancement candidates and keeps the best readability score instead of applying one blunt filter.
- Baseline enhancement performs grayscale, brightness correction, normalization, and measured contrast strengthening.

### Pass 14 of 150: Adobe-Style Enhancement Pass 2

Status: complete.

Goal:
- Improve hard photos.

Scope:
- Wrinkled/faded receipts.
- Low contrast receipts.
- Thermal paper.
- Mild blur handling.
- Overexposed/underexposed areas.

Done:
- Enhancement helps OCR without making normal images worse.
- Added faded, thermal, shadow-balanced, and mild text-sharpen enhancement candidates.
- Synthetic faded/thermal/shadowed receipt tests guard that hard-photo prep does not lower review score or text-band detection.

### Pass 15 of 150: Crop And Perspective Foundation

Status: complete.

Goal:
- Improve automatic crop and perspective correction without relying on a required Google Play add-on.

Scope:
- Existing crop helpers audit.
- Safe automatic crop.
- Manual crop polish.
- Perspective correction when confidence is acceptable.
- Never block saving if crop confidence is low.

Done:
- Crop helps when safe and gets out of the way when unsure.
- Auto-crop now rejects tiny, off-center, or extreme-aspect candidate bounds before cropping.
- Crop guard tests prove suspicious off-center receipt-like patches do not get blindly cropped.

### Pass 16 of 150: Image Save-Space Preview

Status: complete.

Goal:
- Let the user understand backup size choices by seeing the result.

Scope:
- Save-space preview.
- Plain-language labels.
- Black-and-white default where appropriate.
- Keep OCR source separate from saved proof.

Done:
- User can choose storage tradeoff without developer terms.
- Saved-copy preview quality is now measured from the actual optimized saved-copy image, not the original full-quality source.
- Preview tests prove estimated saved copy quality matches the optimized image that would be kept.

## Long Receipt And Stitching Track

### Pass 17 of estimated 55: Long Receipt Capture Flow

Status: complete.

Goal:
- Make long receipt capture first-class.

Scope:
- Prompt user to add another photo.
- Explain not to squeeze tiny text into one photo.
- Keep photos ordered.
- Make top/middle/bottom sections obvious.

Done:
- A long Walmart/CVS-style receipt can be captured section by section.
- When adding the next receipt section, the camera shows a translucent bottom slice from the previous section as a nonblocking alignment guide.
- Additional-section capture keeps long-receipt guidance enabled instead of dropping to an unguided plain camera.
- Prepared OCR images now preserve original-quality source bytes when cleanup decides the original is safest, while still bounding oversized sources.
- Stitching and image-prep regression tests cover ghost guide wiring, manual overlap, scale differences, unsafe overlap fallback, hard-photo enhancement, crop safety, and OCR-before-save-copy behavior.

### Pass 18 of estimated 55: Capability-Gated Edge Detection Overlay

Status: complete.

Goal:
- Show a real receipt-edge frame only when the app has enough local signal to draw it honestly and safely.

Scope:
- Device/capability gating.
- Live edge estimate from camera frame analysis.
- Nonblocking overlay frame.
- No required Google Play add-on.
- Fallback to guidance-only mode on low tier/low confidence.

Done:
- Live camera analysis now estimates a normalized receipt/document frame from local image signal.
- The camera only draws the live edge frame when the device capability policy allows it and confidence is usable.
- Light-tier devices skip the live edge overlay and stay on guidance-only mode to avoid overloading older phones.
- The overlay is nonblocking, so tap focus and pinch zoom still work.
- Tests prove the overlay is capability-gated, signal-based, and not a fake always-on rectangle.

### Pass 19 of estimated 55: Multi-Photo Review And Ordering

Status: complete.

Goal:
- Make photo order obvious and correctable.

Scope:
- Ordered photo list.
- Move up/down.
- Retake one section.
- Remove one section.
- Add missing section.

Done:
- User can fix a bad middle photo without restarting.
- Multi-photo review now labels receipt sections as Top Photo, Middle Photo, and Bottom Photo.
- Order controls use plain receipt wording like Move Toward Top and Move Toward Bottom instead of vague page/order terms.
- The selected-photo status explains what that photo should contain, so a user can catch out-of-order sections before OCR.
- Focused analyzer and receipt review/stitching tests pass.

### Pass 20 of estimated 55: Automatic Stitching Core

Status: complete.

Goal:
- Stitch receipt sections when overlap confidence is safe.

Scope:
- Overlap detection.
- Duplicate line avoidance.
- Scale differences between photos.
- Slight rotation differences.
- Memory limits for older devices.

Done:
- Safe overlaps produce one stitched OCR source.
- Stitch matching now tolerates scale differences and slight handheld rotation between receipt sections.
- Candidate overlap matching now runs on bounded comparison images and only applies the winning correction to the full OCR image.
- Fallback results include the failed pair confidence metadata so Command Center/future diagnostics can show what failed.
- Oversized stitched receipts still fall back to separate OCR photos instead of risking memory pressure on older phones.
- Focused analyzer and stitching tests pass.

### Pass 21 of estimated 55: Manual Stitch Adjustment

Status: complete.

Goal:
- Let user correct stitching when automatic overlap is unsure.

Scope:
- Manual overlap slider.
- Pair-by-pair preview.
- Fallback warning.
- Preserve readability.

Done:
- User can rescue a stitch instead of being stuck.
- Stitch results now use receipt-photo language instead of generic page language.
- Manual overlap controls explain that the user is lining up repeated receipt text between photos.
- Fallback wording tells the user that separate OCR reading is safe when stitching confidence is too low.
- Focused analyzer, stitching tests, and camera help-flow guards pass.

### Pass 22 of estimated 55: Receipt Reading Handoff After Stitch Review

Status: complete.

Goal:
- After photo review, app-assisted receipt capture should move directly into OCR reading and receipt classification/review.

Scope:
- Verify `Read Receipt` / `Read Stitched Receipt` routes through OCR.
- Avoid returning the user to the receipt attachment area as a dead end.
- Preserve manual receipt flow when app assistance is off.
- Show clear reading/failure/success status.
- Keep OCR using source-quality photos before saved-copy compression.

Done:
- User accepts receipt photos and lands in a real review/classification workflow.
- Shared receipt photo handoff now reports whether OCR read a stitched receipt image, separate long-receipt photos, or one receipt photo.
- App-assisted disabled mode still skips OCR and leaves the user in manual/proof-only flow.
- OCR source photos are still read before temporary OCR artifacts are deleted.
- Focused analyzer, camera help-flow, and expense assisted-review tests pass.

### Pass 23 of estimated 55: Receipt Review Classification Landing

Status: complete.

Goal:
- Make the post-OCR receipt review feel like the actual next screen of the flow: classify the whole receipt, then only classify lines when mixed.

Scope:
- Whole receipt business/personal/mixed decision.
- Simple mode remains amount/classification focused.
- Detailed mode remains available.
- Mixed receipt line controls are clear.
- Totals/tax allocation stay visible.

Done:
- User can understand what to do immediately after OCR fills the receipt review.
- Receipt recap now keeps line-level Business/Personal/Split controls hidden until the receipt is mixed or split.
- Whole-receipt classification stays the primary action before line-by-line review.
- Mixed receipt totals explain that business/personal totals include line shares plus allocated tax or adjustment.
- Focused analyzer and assisted receipt review tests pass.

### Pass 24 of estimated 55: Receipt Tax And Split Allocation Review

Status: complete.

Goal:
- Make subtotal, tax, receipt total, business total, and personal total trustworthy for mixed receipts.

Scope:
- Show tax/adjustment allocation clearly.
- Guard negative lines/returns.
- Avoid double counting receipt totals.
- Make split percentages plain.
- Keep simple receipt mode fast.

Done:
- Mixed receipts make financial sense before save/export.
- Business/personal tax and receipt adjustment allocation now uses positive purchase shares instead of raw net subtotal.
- Negative lines/returns still reduce the side they belong to but do not receive extra tax allocation.
- Mixed receipt recap explains the allocation behavior in plain language.
- Focused analyzer and assisted receipt review tests pass.

### Pass 25 of estimated 55: Receipt Camera Device-Safe Limits

Status: complete.

Goal:
- Keep camera, stitching, OCR prep, and storage behavior safe across S9-class, mid-tier, and flagship devices.

Scope:
- Capability tier gates.
- Stitch/image max dimensions by tier.
- OCR source limits by tier.
- Auto-capture and live-edge limits by tier.
- Low-storage behavior.

Done:
- Older phones get safe defaults without blocking flagship-quality capture.
- Receipt stitch preview and final OCR stitching now use capability-tier max pixels and height.
- Light devices use smaller stitch bounds, medium devices use balanced bounds, and heavyweight devices can keep larger stitched OCR sources.
- Capability and camera help-flow tests guard the tiered behavior.

### Pass 26 of estimated 55: Receipt Photo Quality And Auto-Capture Tuning

Status: complete.

Goal:
- Make automatic capture helpful without trapping the user or refusing good photos.

Scope:
- Manual shutter always works.
- Auto capture needs stable readable frames.
- Quality score copy is plain-language.
- Tap-to-focus copy matches real behavior.
- Best-photo candidate selection does not confuse single-photo flow.

Done:
- Camera helps the user get a clear photo but does not fight them.
- Tapping the shutter now always uses the manual capture path, even when assisted or auto capture is active.
- Auto capture remains available only after stable readable frames meet the stricter auto policy.
- Focused analyzer and camera layout/quality tests guard the behavior.

### Pass 27 of estimated 55: Receipt Review Action Surface

Status: complete.

Goal:
- Make the after-photo review screen feel like a professional receipt scanner, not a hidden scroll panel.

Scope:
- Single-photo review should say `Review Receipt Photo`, not `Choose the best receipt photo`.
- The primary action should be visible as `Read Receipt` or `Use Photo`.
- Compact controls should not bury the continue action.
- Multi-photo controls should explain adding another photo and reading the full receipt.
- Saved-copy wording should be plain-language and not sound like a final save.

Done:
- User can take one photo and immediately see how to continue.
- User can add another receipt section for a long receipt without confusing it with saving the expense.
- Focused review tests cover the single-photo and multi-photo wording.
- Single-photo review now says `Review receipt photo` and `Review receipt photo, then read it.`
- Multi-photo review now says `receipt sections` and makes order/read intent clearer.
- `Saved copy` / `Save Space` UI copy is replaced with `Backup image` / `Backup Size`.
- Focused analyzer and review/help/assisted-flow tests pass.

### Pass 28 of estimated 55: Receipt Review Flow Routing

Status: complete.

Goal:
- After photo review, app-assisted receipts should continue into parsed receipt review instead of dumping the user back into an attachment-only state.

Scope:
- Confirm photo-review result returns OCR source paths, saved proof paths, stitch metadata, and quality metadata.
- Confirm expense receipt import reads reviewed photos immediately when app-assisted fill is on.
- Confirm success copy tells the user to review parsed lines, not simply that a photo attached.
- Confirm manual/no-assist mode can still attach proof photos without forcing OCR.
- Keep the route scoped to expenses and shared receipt capture, avoiding maintenance-specific flows.

Done:
- Assisted expense receipt photo flow reads the receipt and lands the user in review/classification.
- Manual proof-only flow still works.
- Focused tests cover both routes.
- Reviewed photos now report that parsed lines should be reviewed below after OCR finishes.
- Tests guard app-assisted opt-out, missing imported-text callback, empty OCR sources, and OCR-before-cleanup ordering.

### Pass 29 of estimated 55: Long Receipt Section Guardrails

Status: complete.

Goal:
- Help users capture long receipts in readable top-to-bottom sections without mixing up order or squeezing tiny text into one blurry photo.

Scope:
- Keep previous-section ghost guide when adding/retaking later sections.
- Make single-photo and multi-photo review copy explain sections plainly.
- Keep ordering controls available only when needed.
- Keep stitching optional with safe fallback to reading ordered photos separately.
- Avoid blocking receipt save when stitch confidence is low.

Done:
- Long receipt users can add sections, check order, review stitch, and still continue if stitching is not confident.
- Focused tests guard the section flow and fallback wording.
- Adding or retaking into multiple receipt sections now opens the photo-order review step automatically.
- Previous-section guide handoff remains wired into add/retake camera launches.
- Focused analyzer and camera/stitching tests pass.

### Pass 30 of estimated 55: Receipt Review Device UI Batch

Status: deferred until user asks for device install.

Goal:
- Put the current camera/review UI batch on the S24 Ultra only after the bundled review changes are worth inspecting.

Scope:
- Build/install debug app only if the S24 is available and user wants the UI batch.
- Do not uninstall unrelated Maintainiac builds.
- Verify the app launches.
- Let user inspect live camera, after-photo review, add-section order flow, and read-receipt handoff.

Done:
- S24 Ultra has the latest meaningful UI batch for review.
- Any device-only defects are listed as the next UI pass.

### Pass 31 of estimated 55: Separate OCR Fallback Guardrails

Status: complete.

Goal:
- Make ordered separate-photo OCR safer for long receipts when stitching is unavailable, low-confidence, or intentionally skipped.

Scope:
- Suppress true section-boundary overlap.
- Do not remove legitimate duplicate item lines inside the same section.
- Do not remove legitimate duplicate item lines that appear later in a different section when they are not overlap.
- Warn when neighboring receipt sections have no repeated text and may be missing a middle section.
- Keep raw text intact for proof/review while parser text is cleaned for app-assisted fill.

Done:
- OCR overlap suppression is boundary-aware instead of global.
- Missing section gaps now create a review warning without changing text.
- Legitimate duplicate item lines are preserved.
- Focused analyzer and OCR long-receipt tests pass.

### Pass 32 of estimated 55: OCR Diagnostics Hardening

Status: complete.

Goal:
- Make OCR outcomes explainable without exposing private receipt content.

Scope:
- Confirmed warning kinds for duplicate overlap, possible section gap, photo quality, skipped proof-only sources, PDF safety, PDF too large, unreadable files, plugin unavailable, and no readable text.
- Diagnostics should summarize severity, counts, source type, and review needs without storing receipt text.
- Command One-safe health data should remain content-free.

Done:
- OCR diagnostics clearly say what failed or needs review and why.
- Focused diagnostics tests cover warning kinds and severity.
- OCR diagnostics now expose privacy-safe warning-kind counts.
- Expense OCR review records persist warning-kind counts through draft, ledger, and Firestore-shaped receipt backups.
- Section-gap OCR warnings map to `possible_missing_receipt_section` instead of a vague or duplicate-text cause.
- Focused analyzer and OCR diagnostics/storage tests pass.

### Pass 33 of estimated 55: Parser Field Confidence Hardening

Status: complete.

Goal:
- Improve receipt parser confidence for merchant, date, subtotal, tax, total, payment, and receipt identifiers without trusting bad OCR too quickly.

Scope:
- Merchant/date/total confidence labels.
- Explicit subtotal/tax/total reconciliation.
- Fuel, retail, and trade-supply receipt field patterns.
- Negative/return lines should be understood as adjustments, not confidence penalties by themselves.
- Parser warnings should remain content-safe for diagnostics.

Done:
- Parser field extraction has clearer confidence and review reasons.
- Focused parser tests cover core field extraction and suspicious math.
- Parse results and diagnostics now expose field confidence for merchant, date, time, subtotal, tax, total, line items, and receipt math.
- Known merchant profiles, OCR dates, explicit totals, inferred totals, fallback dates, and line/math reconciliation now get distinct review reasons.
- Focused analyzer and parser torture tests pass.

### Pass 34 of estimated 55: Parser Review Failure Reasons

Status: complete.

Goal:
- Make parser failures and review states explain exact root causes in plain language for receipt review and future Command One metrics.

Scope:
- Normalize parser warning kinds without storing receipt content.
- Distinguish missing fields, inferred fields, line mismatch, subtotal/tax/total mismatch, too many low-confidence lines, and catalog/material review.
- Keep negative coupon/discount/return lines from lowering confidence when they reconcile.
- Make tests prove the failure reason points at the exact failing parser stage.

Done:
- Receipt parser review reasons are specific enough to route UI help and diagnostics.
- Focused parser tests cover missing, mismatched, inferred, and low-confidence receipt states.
- Parser diagnostics now distinguish inferred subtotal/tax/total and fallback receipt dates from generic low confidence.
- Parser failure evidence includes content-free field review labels for Command One summaries.
- Focused analyzer, parser diagnostics, parser, and expense telemetry tests pass.

### Pass 35 of estimated 55: Parser Review UI Guidance

Status: complete.

Goal:
- Surface parser field confidence and exact review causes in the assisted receipt review UI using plain language.

Scope:
- Show user-facing parser guidance without raw diagnostic jargon.
- Prioritize merchant/date/total/math/line review warnings.
- Keep private receipt content out of telemetry and diagnostics.
- Avoid changing maintenance-specific receipt behavior.

Done:
- Assisted receipt review explains what needs checking and why.
- Focused UI or widget tests cover the guidance surface.
- Receipt entry now stores the latest parser field confidences and clears stale confidence state when loading drafts or saved receipts.
- Receipt Fill Review now shows a compact `Fields to check` summary with plain-language merchant/date/total/math/line guidance.
- Focused analyzer and assisted review/parser tests pass.

### Pass 36 of estimated 55: Privacy-Safe Parser Health Metrics

Status: complete.

Goal:
- Feed parser field confidence and review causes into local telemetry summaries without storing receipt text or private item details.

Scope:
- Add content-free parser field review counts where telemetry already tracks parser outcomes.
- Include exact parser cause buckets for inferred totals, fallback dates, receipt math, line mismatch, and line review.
- Keep raw receipt text, merchant names, addresses, notes, and item descriptions out of telemetry.

Done:
- Expense telemetry can summarize parser health by field/cause.
- Focused privacy tests prove no private receipt content is stored.
- Privacy-safe receipt parse events now include parser review cause and field review keys.
- Command Center health snapshots now count parser review causes and field review keys without merchant names, receipt text, item names, or amounts.
- Existing app-assisted parse flow already queues these privacy-safe parse events.
- Focused analyzer, receipt privacy, parser diagnostics, and expense telemetry tests pass.

### Pass 37 of estimated 55: Receipt Backup Image Pipeline Audit

Status: complete.

Goal:
- Confirm the receipt image pipeline reads OCR from the best available image first, then creates space-saving backup copies without making OCR worse.

Scope:
- Audit original/captured image, enhanced image, stitched image, backup-size preview, and saved proof path.
- Ensure OCR is not forced to read only from heavily compressed backup copies.
- Keep backup/storage wording user-friendly: save space, backup image, phone/cloud storage.
- Add tests around OCR-before-backup-copy behavior where practical.

Done:
- Receipt photo proof storage remains lean without sacrificing OCR input quality.
- Focused tests document the order of operations.
- `ReceiptImageProcessor.prepareForOcrAndBackup` now makes the clean OCR source and smaller backup copy explicit outputs.
- Photo review save uses the clean OCR source for reading and the backup copy for stored proof.
- Focused analyzer and image/camera review tests pass.

### Pass 38 of estimated 55: Receipt Proof Storage And Backup Metadata

Status: complete.

Goal:
- Make saved receipt proof metadata clear enough for local storage, export, cloud backup, and Command One cost/health reporting.

Scope:
- Audit saved proof records for data saver level, byte size, source type, staged/permanent path handling, and cloud-safe fields.
- Confirm optimized receipt proof paths are kept out of Firestore backup documents.
- Confirm local proof files remain recoverable for drafts and saved receipts.
- Avoid changing maintenance-specific receipt behavior.

Done:
- Receipt proof records preserve storage-size metadata without syncing private local paths.
- Focused storage and Firestore document tests pass.
- Firestore receipt proof pointers now include backup byte size and a safe backup size bucket for cost/storage health reporting.
- Local proof paths, raw OCR, imported proof text, and raw line OCR remain excluded from backup documents.
- Focused analyzer, Firestore backup, and proof storage lifecycle tests pass.

### Pass 39 of estimated 55: Receipt PDF OCR Safety Review

Status: complete.

Goal:
- Harden receipt PDF input so readable PDFs work, unsafe PDFs stay proof-only, and older phones avoid expensive PDF work.

Scope:
- Audit PDF inspection, page limits, timeout behavior, and OCR warning mapping.
- Confirm PDF proof storage remains read-only and cloud backup metadata stays lean.
- Confirm unreadable or unsafe PDFs never block saving the receipt proof.
- Keep invoice PDF generation separate from receipt PDF import unless a shared utility is clearly appropriate.

Done:
- PDF receipt import behavior is predictable, bounded, and explainable.
- Focused PDF OCR/proof tests pass.
- OCR service now tracks planned PDF page work before reading instead of assuming every PDF read used the maximum page cap.
- Device-specific PDF page-limit warnings explain when only the front pages will be read while the full PDF remains saved as read-only proof.
- Focused analyzer plus OCR/PDF/share/proof torture tests pass.

### Pass 40 of estimated 55: Receipt Import Failure Recovery

Status: complete.

Goal:
- Make failed receipt import/reading states recoverable without losing proof attachments or trapping the user in the wrong screen.

Scope:
- Audit photo/PDF/imported-text failure branches after app-assisted reading.
- Confirm failed OCR does not discard attachments, staged proof records, or user-entered receipt info.
- Confirm retry/manual-entry messaging uses plain receipt language and avoids developer terms.
- Keep maintenance-specific receipt flows untouched.

Done:
- Failed receipt reading leaves the user with proof saved, clear recovery choices, and no duplicate staged attachments.
- The attachment panel now has separate reading, success, warning, and failed visual states.
- Receipt-reading failures now keep clear plain-language recovery copy: keep proof, try another photo, retake, or continue manually.
- The add-more action after proof exists now says `Add More Proof` instead of implying a new receipt.
- Focused analyzer plus attachment/OCR/PDF import tests pass.

### Pass 41 of estimated 55: Receipt Review Classification Completion

Status: complete.

Goal:
- Finish the app-assisted receipt review handoff so a read receipt naturally lands on business/personal/mixed classification with line-level review instead of feeling like a plain attachment return.

Scope:
- Audit the expense receipt review panel for whole-receipt classification, mixed receipt line controls, and split tax/total recap.
- Make sure simple mode and detailed mode wording is plain and receipt-specific.
- Confirm OCR success routes to review and failure routes to recover/manual entry.
- Keep the separate detailed item editor route; do not rebuild it inline.

Done:
- After receipt reading succeeds, the user can classify the receipt and its lines without guessing what screen they are on.
- Assisted review order now starts with `What Maintainiac Found`, then whole-receipt classification, then parser line evidence, then the totals recap.
- The review copy now tells the user to check store, date, totals, and line confidence before saving.
- Focused analyzer, assisted review, parser, and parser diagnostic tests pass.

### Pass 42 of estimated 55: Receipt Data Saver Preview Completion

Status: complete.

Goal:
- Make receipt save-space choices understandable and previewable without making users learn image-compression terms.

Scope:
- Audit data saver wording, preview sizes, backup image labels, and review controls.
- Confirm OCR uses the best available source before backup-size reduction.
- Confirm users can understand what is stored locally/cloud-backed versus what is used temporarily for reading.
- Keep the data saver settings out of the way of receipt crop/review.

Done:
- Users can pick a storage-saving receipt proof level with clear language and without hurting OCR accuracy.
- Data saver copy now uses `saved proof` language instead of making users think about compression.
- Photo review and settings now explain that OCR uses the clear photo first, then the smaller proof copy is kept.
- The saved-proof preview panel now labels the actual kept image and storage details clearly.
- Focused analyzer plus camera help, data-saver image, and camera layout tests pass.

### Pass 43 of estimated 55: Receipt Save Readiness Guardrails

Status: complete.

Goal:
- Prevent users from saving confusing assisted receipts without clear line, classification, proof, and review state.

Scope:
- Audit save validation for parsed lines, missing proof, unreviewed parser lines, mixed receipt allocations, and subtotal/tax/total math.
- Keep warnings plain-language and actionable.
- Confirm save guardrails do not block simple manual expense entry unnecessarily.
- Keep maintenance-specific save behavior untouched.

Done:
- Expense receipt save gives clear reasons when the receipt needs another review step before saving.
- Save readiness now runs before duplicate detection, proof persistence, and ledger save.
- The readiness dialog explains unreviewed app-filled lines, OCR no-text/blocking/partial/review warnings, and receipt subtotal versus line subtotal mismatches.
- The user can review the receipt or save anyway after verification; simple manual entry is still only hard-blocked when no lines exist.
- Abandoned readiness review records privacy-safe telemetry with confirmed issue kinds, not receipt content.
- Focused analyzer plus assisted review, telemetry, and duplicate-save tests pass.

### Pass 44 of estimated 55: Saved Receipt Detail And Calendar Recovery

Status: complete.

Goal:
- Make saved receipt review from calendar/detail screens preserve the same proof, OCR review, classification, totals, and edit context the user just created.

Scope:
- Audit saved expense receipt detail and calendar entry routes.
- Confirm proof thumbnails/PDF pointers open without losing receipt context.
- Confirm business/personal/split totals and receipt OCR review metadata are visible in plain language.
- Confirm edit routes reuse the receipt flow instead of creating a disconnected duplicate path.
- Keep maintenance-specific receipt handling untouched.

Done:
- A saved receipt can be found later, reviewed, understood, and edited without losing app-assisted receipt context.
- Calendar day entries and home ledger rows now open saved receipt detail first instead of immediately dropping into edit mode.
- Saved receipt detail now shows a receipt breakdown with business total, personal total, split-line count, proof count, and OCR/read status.
- Saved receipt line totals use the receipt's allocated total so tax/adjustment context is preserved during later review.
- Saved receipt photos are tappable and open a pinch-zoom proof viewer; saved PDFs still open the PDF proof viewer.
- Focused analyzer plus saved receipt detail, assisted review, and telemetry tests pass.

### Pass 45 of estimated 55: Receipt Calendar Add/Edit/Delete Diagnostics

Status: complete.

Goal:
- Make calendar-side receipt actions explain exactly what failed and keep Command One-ready diagnostics privacy-safe.

Scope:
- Audit add-line, edit-line, copy-line, delete-line, full-receipt edit, and delete-receipt paths from saved receipt detail/calendar.
- Confirm each action records success/failure where appropriate without private receipt content.
- Confirm failures show plain recovery messages instead of silent no-ops.
- Confirm calendar entries stay chronological by receipt date/time after edits.
- Keep maintenance-specific receipt behavior untouched.

Done:
- Calendar-side receipt edits are observable, recoverable, and do not silently fail.
- Calendar receipt delete, line edit, line copy, and line delete failures have distinct confirmed-cause diagnostics for future Command One health views.
- Calendar-side recovery copy is source-guarded so failures remain plain-language instead of silent.
- The telemetry aggregation test now covers all four calendar receipt action failure causes.
- Focused analyzer plus saved receipt detail, assisted review, and telemetry tests pass.

### Pass 46 of estimated 55: Receipt Export Proof Bundle Readiness

Status: complete.

Goal:
- Make exported receipt records preserve proof status, OCR review status, business/personal totals, and line details without bloating user data.

Scope:
- Audit expense export models and file writer for receipt proof metadata.
- Confirm exports can include proof references/counts without embedding giant private images by default.
- Confirm business, personal, split, tax, and total fields match saved receipt detail.
- Confirm export events distinguish completed, blocked, and failed outcomes.
- Keep invoice/maintenance PDF export behavior untouched.

Done:
- Expense receipt export data is complete enough for recordkeeping while staying storage-conscious.
- Receipt CSV now includes proof count, proof types, saved proof byte total, OCR review status, OCR warning count, parser line count, and requested PDF pages.
- Export manifests now summarize proof count, proof bytes, missing-proof receipts, OCR-reviewed receipts, and receipts needing OCR review.
- Export privacy notes state that raw OCR text and receipt images are not embedded by default.
- Existing line export keeps tax-adjusted totals, business amounts, personal amounts, and split percentages.
- Focused analyzer plus export and telemetry tests pass.

### Pass 47 of estimated 55: Synthetic End-To-End Receipt Regression Matrix

Status: complete.

Goal:
- Prove the receipt pipeline against repeatable synthetic receipt cases before relying on real-world phone testing.

Scope:
- Audit existing synthetic Lowe's, Home Depot, Walmart, CVS, fuel, return, wrinkled/noisy, and long receipt tests.
- Add missing end-to-end expectations for OCR text normalization, parser results, review flags, business/personal/mixed classification, proof metadata, and export readiness.
- Keep synthetic images/text privacy-safe and deterministic.
- Keep maintenance-specific receipt setup untouched.

Done:
- The receipt system has a repeatable regression matrix showing what is covered and what still requires real-device testing.
- Added an end-to-end synthetic matrix that parses all fixture packs into real `ExpenseReceiptRecord` objects, checks saved proof/OCR metadata, verifies business plus personal totals reconcile, and exports the records.
- The matrix proves export readiness includes proof metadata and OCR review metadata while keeping raw OCR text out of the receipt CSV.
- Existing regression report still covers 14 fixtures across core, materials, noisy OCR, damaged, and trade supply packs with 14/14 ready fixtures.
- Focused analyzer plus end-to-end matrix, regression report, long retail torture, and export tests pass.

### Pass 48 of estimated 55: Receipt Stitching And OCR Handoff Stress Matrix

Status: complete.

Goal:
- Prove stitched, multi-photo, duplicate-overlap, and missing-section receipt inputs hand off safely to OCR/parser review.

Scope:
- Audit existing receipt stitching and combined OCR text stress tests.
- Add matrix expectations for overlap suppression, section ordering, missing middle section warnings, and fallback-to-separate OCR behavior.
- Confirm long receipt handoff does not trust low-confidence or incomplete stitched output.
- Confirm older-device limits remain bounded and do not require all images in memory forever.

Done:
- Multi-photo receipt capture has repeatable stress coverage before real-device long-receipt testing.
- Added a section handoff matrix that drives multi-section receipt text through OCR app-fill and the expense parser.
- The matrix covers ordered overlap suppression, missing middle sections, out-of-order sections, and similar-but-different overlap lines that must not be deleted.
- Missing and out-of-order sections now have regression coverage proving they stay reviewable and are not treated as trusted math.
- Focused analyzer plus stitching, combined OCR, and long-retail torture tests pass.

### Pass 49 of estimated 55: Receipt Camera Capability And Low-End Device Stress Review

Status: complete.

Goal:
- Prove receipt capture, stitching, OCR limits, and saved proof behavior stay bounded on older and lower-capability devices.

Scope:
- Audit receipt device capability detection, camera capture policy, PDF/OCR limits, stitching output limits, data saver defaults, and low-storage behavior.
- Add or tighten tests for light, medium, and heavyweight capability tiers.
- Confirm manual capture always works even when automatic capture is not confident.
- Confirm long-receipt stitching falls back cleanly when output size exceeds a device tier.
- Confirm user-facing labels do not expose creepy device details, while diagnostics keep privacy-safe capability context.

Done:
- Low-end device behavior is covered before broader camera UI/device testing resumes.
- Stitch output limits now live in the shared receipt capability policy instead of private review-screen UI code.
- Photo review uses `ReceiptDeviceCapability.stitchLimits`, so older, medium, and heavyweight devices share the same tested limits everywhere.
- Capability tests now cover stitch output ceilings, low-end camera defaults, large-photo review on older phones, and no raw hardware detail leakage in setup/settings surfaces.
- Focused analyzer plus assistance policy, OCR service, stitching, and combined OCR handoff tests pass.

### Pass 50 of estimated 55: Receipt Review Route And Classification Contract

Status: complete.

Goal:
- Prove the app-assisted receipt flow routes to receipt review/classification after photo OCR instead of dropping the user back into a plain attachment screen.

Scope:
- Audit receipt attachment import actions, expense receipt entry routing, app-assisted mode handling, and classification landing tests.
- Add or tighten source/behavior tests proving `Read Receipt` leads to parsed review rows.
- Confirm business, personal, and mixed classification choices remain available after OCR.
- Confirm quick classify and detailed item modes are user-facing choices with plain wording, not developer jargon.
- Keep maintenance-specific receipt setup out of scope.

Done:
- App-assisted receipt capture has a tested route contract from accepted photos to review/classification.
- The assisted receipt review source-contract test now covers the reviewed-photo import path.
- The test proves attachment state is published, reviewed OCR photos are read for app-assisted review, and temporary OCR copies are cleaned up after handoff.
- The test covers stitched, separate-photo fallback, multi-photo, and single-photo success messages that direct the user to parsed receipt lines below.
- Focused analyzer plus assisted review, saved receipt detail, and expense telemetry tests pass.

### Pass 51 of estimated 55: Receipt Data Saver Preview And OCR Source Contract

Status: complete.

Goal:
- Prove OCR reads the best prepared receipt source before saved-copy shrinking, while the user can still choose a smaller cloud/local proof copy after review.

Scope:
- Audit image preparation, OCR source photo paths, data saver preview, saved proof copies, and attachment metadata.
- Add or tighten tests proving OCR source paths are separate from saved proof copies when needed.
- Confirm data saver language remains user-friendly and not developer/compression jargon.
- Confirm grayscale/space-saving copies are for saved proof/storage, not the first OCR read.
- Confirm selected saved-copy level persists without changing raw OCR diagnostic text.

Done:
- Receipt photo reading and receipt proof storage are contractually separated.
- Added prepared saved-proof preview helpers so the preview estimates and preview image use the same OCR-prepared source as the final saved proof copy.
- Photo review now uses `previewPreparedBackupFile` and `optimizePreparedBackupFile`, preventing the UI from previewing an unprepared camera image while saving a prepared receipt proof.
- Data saver tests now prove OCR source and saved proof are separate, prove final backup quality/size matches the prepared preview pipeline, and tolerate only tiny JPEG score variance.
- Source-contract tests now cover prepared preview helpers, OCR-before-backup order, and reviewed-photo handoff cleanup.
- Focused analyzer plus data saver, camera help, assisted review, and OCR service tests pass.

### Pass 52 of estimated 55: Receipt Saved Proof Lifecycle And Cleanup Audit

Status: complete.

Goal:
- Prove temporary receipt OCR artifacts, data-saver previews, stitch previews, best-shot extras, and saved proof files are kept or deleted at the right time.

Scope:
- Audit generated file cleanup in camera review, attachment import, proof storage, drafts, and saved expense records.
- Add or tighten tests proving saved proof files are preserved while temporary OCR/stitch/preview artifacts are cleaned after handoff.
- Confirm cleanup never deletes the saved receipt proof path or user-selected source still needed by the receipt.
- Confirm cleanup is best-effort and cannot crash the receipt workflow.

Done:
- Receipt file lifecycle has explicit regression coverage before real-device long receipt testing.
- Prepared backup preview helpers now await cleanup of temporary OCR-prepared source files instead of leaving cleanup fire-and-forget.
- Added a direct cleanup test proving prepared backup preview/optimization leaves the saved optimized proof and does not leak temporary enhanced OCR artifacts.
- Source-contract coverage now checks review-screen cleanup hooks, best-shot cleanup, stitch/data-saver preview cleanup, and imported OCR source cleanup that skips saved receipt photo paths.
- Existing proof storage lifecycle tests still prove staged proof promotion, rollback, orphan cleanup, draft retention, and staged-copy deletion behavior.
- Focused analyzer plus data saver, camera help, proof storage lifecycle, and draft storage lifecycle tests pass.

### Pass 53 of estimated 55: Receipt Final Synthetic Stress And Coverage Review

Status: complete.

Goal:
- Run the broadest practical synthetic receipt/camera/OCR/parser/export regression set and identify any remaining hardening passes before moving to real-device receipt tests or PDF/invoice hardening.

Scope:
- Run focused receipt camera/OCR/parser/export/telemetry tests together.
- Review the pass plan for remaining gaps versus the receipt camera/OCR/product standard.
- Fix small discovered gaps where safe; otherwise add explicit next-pass items.
- Do not push a device build unless the user asks.

Done:
- The receipt capture/OCR/parser foundation has a current synthetic QA snapshot and a short remaining-work list.
- Focused analyzer passed for shared receipt capture, expense entry, export models, and the receipt/camera/OCR/export/telemetry/storage tests used in this pass.
- Camera/settings tests passed: data saver, camera help, quality guidance, capture layout, assistance policy, and settings store.
- OCR/stitch/parser tests passed: stitching, combined OCR handoff, OCR service, end-to-end regression matrix, regression report, and long retail torture.
- Expense/export/storage tests passed: assisted receipt review, saved receipt OCR detail, export, telemetry, proof lifecycle, and draft lifecycle.
- Synthetic regression report stayed at 14/14 ready fixtures, 100.0% pass, 95.6% quality, 98.8% readiness, and 0 issue buckets.

### Pass 54 of estimated 55: Receipt Real-Device Readiness Checklist And Manual Test Script

Status: complete.

Goal:
- Convert the synthetic receipt evidence into a practical S24/S9/iPhone manual test checklist so real-device testing is deliberate instead of random.

Scope:
- Define exact phone test flows for single-photo receipts, long multi-photo receipts, add-photo order changes, manual capture, auto guidance, save-space preview, app-assisted review, manual/no-assist mode, PDF import, and proof recovery.
- Keep the checklist privacy-safe and written in plain language.
- Identify the small number of device builds worth pushing instead of reinstalling after every tweak.
- List remaining pass candidates before moving into heavier PDF/invoice hardening.

Done:
- User has a concise receipt-device test script that says what to tap, what should happen, what must never happen, and what evidence to report back.
- Added `docs/receipt_real_device_test_script.md` covering single-photo receipts, long multi-photo receipts, save-space preview, app-assisted review, manual/no-assist mode, PDF receipt import, interruption recovery, and failure reporting.
- The script names the expected behavior and "must never happen" checks for each flow so S24/S9/iPhone testing is useful instead of vague.

### Pass 55 of estimated 55: Receipt Remaining Gaps And PDF/Invoice Bridge Decision

Status: complete.

Goal:
- Decide whether the receipt camera/OCR foundation is ready for real-device validation, or whether one more code-hardening pass is needed before moving into PDF/invoice hardening.

Scope:
- Review remaining product-standard gaps against the synthetic evidence and real-device script.
- Identify the smallest safe next code pass if there is a known gap.
- Separate receipt-camera/OCR work from invoice PDF generation/send/receive hardening.
- Do not touch maintenance-specific receipt paths.

Done:
- The next work lane is explicit: either device validation, a named receipt gap fix, or the next PDF/invoice hardening pass.
- Decision: receipt camera/OCR foundation is ready for controlled real-device validation, not random stress testing.
- Fixed a remaining user-facing wording gap: saved receipt detail and OCR summaries now say receipt lines are ready for review instead of showing developer-facing parser/raw-line language.
- Kept raw/parser line counts in storage, exports, privacy-safe diagnostics, and Command One-ready telemetry where they are useful for debugging and health reporting.
- Focused analyzer and OCR/detail tests pass after the wording fix.

## PDF And Invoice Hardening Track

### PDF Pass 56 of up to 200: Generated PDF Boundary Validation

Status: complete.

Goal:
- Make every app-generated PDF prove it is a safe, complete PDF before Maintainiac writes, previews, archives, prints, shares, or stores it as invoice/document proof.

Scope:
- Add shared generated-PDF validation for empty bytes, missing PDF header, missing EOF marker, over-large files, and unsupported active PDF features.
- Sanitize generated PDF filenames through one shared helper.
- Apply validation to temporary generated PDF writes, printing, sharing, and permanent generated-document archive.
- Share the already prepared preview file instead of silently generating another temporary PDF from the share button.
- Keep invoice PDF bytes generated from structured invoice data; do not store invoice PDFs inside invoice ledger records.

Done:
- `AppGeneratedPdfDocument` exposes validation and sendable status.
- `AppGeneratedPdfService` refuses invalid generated PDFs before temporary write, print, or share.
- `AppGeneratedPdfArchiveService` refuses invalid generated PDFs before permanent document archive.
- `AppGeneratedPdfPreviewScreen` shares the already prepared preview file.
- Focused analyzer passed for generated PDF services, invoice renderer/factory, and related tests.
- Focused tests passed for generated PDF service and invoice template PDF factory.

### PDF Pass 57 of up to 200: Invoice PDF Send/Archive Lifecycle Audit

Status: complete.

Goal:
- Prove invoice and estimate PDFs can be generated, previewed, shared/sent, printed, archived, and later recovered without duplicate temp buildup, incomplete files, or private-data backup mistakes.

Scope:
- Audit invoice PDF preview entry points and record-specific PDF generation.
- Confirm permanent archive links generated invoice PDFs to invoice records without storing PDF bytes in the invoice ledger.
- Add lifecycle tests for record-specific invoice/estimate PDFs, archive duplicate handling, and file hash/byte-size metadata.
- Keep customer contact/payment data as structured invoice data; generated PDFs remain derived artifacts.
- Do not touch maintenance-specific PDF flows unless a shared generated-PDF utility requires it.

Done:
- Invoice PDF send/archive lifecycle has focused regression coverage and a short remaining gap list before incoming invoice/document PDF work.
- Record-specific invoice PDFs are now tested as sendable, safe-named, archived permanent document proof linked to the invoice record, and excluded from invoice ledger maps.
- Record-specific estimate PDFs are tested as generated estimate documents archived as invoice document proof.
- Focused analyzer passed for invoice PDF factory/renderer, generated PDF services, archive service, and tests.
- Focused tests passed for generated PDF service, invoice template PDF factory, and invoice ledger store.

### PDF Pass 58 of up to 200: Incoming Invoice/Document PDF Routing

Status: complete.

Goal:
- Make incoming/shared invoice, estimate, proposal, job, and contractor PDFs route to document/invoice proof handling instead of being mistaken for ordinary expense receipts.

Scope:
- Audit incoming shared PDF classification and destination UI.
- Strengthen invoice/estimate/job-document keyword handling without reading or storing private content in diagnostics.
- Add tests for incoming invoice PDFs, estimate PDFs, manual PDFs, and regular receipts.
- Keep maintenance receipt routing untouched.

Done:
- Shared invoice/estimate PDFs are suggested as job/invoice documents and can be saved as read-only proof without forcing the expense receipt flow.
- Invoice, estimate, proposal, work order, scope of work, bill-to, amount-due, balance-due, and payment-terms signals now weigh strongly toward job/contractor document routing.
- The job/contractor document suggestion copy now uses user-facing language and explains read-only proof instead of saying an internal feature is not wired.
- Incoming invoice and estimate PDF widget tests prove those PDFs are not mistaken for ordinary expense receipts.
- Existing generic receipt PDF, other document PDF, and PDF torture routing tests still pass.

### PDF Pass 59 of up to 200: Generated PDF Preview And Share Failure Recovery

Status: complete.

Goal:
- Make generated invoice/estimate PDF preview, share, print, and failure states clear and recoverable before deeper invoice-delivery work.

Scope:
- Audit `AppGeneratedPdfPreviewScreen` for validation errors, missing temp files, incomplete prepared files, and share/print dismissals.
- Add tests for preview error wording and share-file failure handling without needing a real platform share sheet.
- Confirm the user sees plain language and can regenerate instead of being stuck.
- Keep this pass focused on generated invoice/estimate PDFs, not maintenance PDFs.

Done:
- Generated PDF UI and service failure states are covered by tests and use user-safe recovery copy.
- Preview generation failures now show a plain-language error plus a `Try Again` action.
- Share and print platform failures now show friendly recovery messages instead of only handling generated-PDF validation errors.
- Preview sharing continues to use the already prepared generated file.
- Widget tests cover retry after preparation failure, friendly share failure, and friendly print failure.
- Focused analyzer and generated PDF preview/service tests pass.

### PDF Pass 60 of up to 200: Invoice PDF Delivery Metadata And Audit Trail

Status: complete.

Goal:
- Track invoice/estimate PDF generation and delivery attempts as structured, privacy-safe invoice events without storing PDF bytes or private document text in the invoice ledger.

Scope:
- Audit invoice audit events and delivery-related status transitions.
- Add structured helpers for PDF generated, previewed, shared/sent, printed, archived, and failed delivery attempts where feasible.
- Preserve local-first invoice records and keep generated PDFs as derived artifacts.
- Add tests proving delivery metadata is useful without embedding PDF bytes or customer/private document text.

Done:
- Added structured `InvoicePdfDeliveryEvent` records for generated, previewed, archived, shared, sent, printed, and failed PDF actions.
- `InvoiceRecord` now preserves `pdfEvents` through copy, map serialization, and reload.
- Added record helpers for generated, previewed, archived, shared, printed, and failed PDF delivery events.
- PDF event metadata stores action type, timestamp, safe filename, byte size, hash, source id, and reason code without storing PDF bytes, PDF paths, customer names, addresses, emails, notes, share text, or document body text.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 61 of up to 200: Invoice PDF Firestore/Backup Shape Audit

Status: complete.

Goal:
- Make sure invoice PDF metadata and delivery events have a cost-safe, privacy-safe backup shape for future Firestore mirroring.

Scope:
- Audit invoice daily backup batches and generated PDF document attachment metadata.
- Ensure invoice PDF events stay small enough to live in structured ledger records without storing PDF bytes or local-only paths.
- Add tests for Firestore-like map payload shape, event count bounds, and privacy-safe document metadata.

Done:
- Added a bounded invoice PDF delivery history limit so one invoice cannot grow an unlimited delivery log.
- Invoice record PDF event helpers keep only the newest bounded delivery events.
- Added tests proving invoice daily backup batches include PDF metadata, exclude PDF bytes and local paths, and keep event history bounded.
- Documented invoice/estimate Firestore backup scope, derived PDF artifact handling, and forbidden PDF event content.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 62 of up to 200: Invoice PDF Form Action Wiring

Status: complete.

Goal:
- Make invoice form preview/share/print/save actions update the invoice record PDF delivery trail where feasible.

Scope:
- Audit current invoice form PDF preview, archive, share, and error paths.
- Wire generated, archived, shared/printed/failed metadata into saved invoice records without changing user-facing workflow unless necessary.
- Keep generated PDFs as derived artifacts and avoid storing file paths or PDF bytes in invoice records.
- Add focused tests around record updates if the existing UI/service seams allow it safely.

Done:
- Invoice final save now records generated and archived PDF delivery events before saving the permanent proof hash.
- Invoice preview now records generated and previewed PDF events after the temporary PDF is prepared.
- Invoice preview/archive failures now record structured failure reason codes where the invoice form owns the failing action.
- The visible invoice workflow stays unchanged.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 63 of up to 200: Invoice PDF Preview Action Callback Seam

Status: complete.

Goal:
- Let preview/share/print surfaces report PDF actions back to the owning record without coupling generic PDF widgets directly to invoice storage.

Scope:
- Audit current generated PDF preview and receipt PDF viewer seams.
- Add an optional callback/action-result object where generic preview widgets can report share/print/open failures.
- Keep callbacks privacy-safe: event type and reason code only, no PDF text or local paths.
- Add focused widget/service tests if the preview seams support it safely.

Done:
- Added `AppGeneratedPdfPreviewAction` and `AppGeneratedPdfPreviewActionEvent`.
- `AppGeneratedPdfPreviewScreen` now has an optional `onAction` callback for preview opened, share completed/dismissed/failed, and print opened/dismissed/failed.
- Failure callbacks use reason codes only and do not expose PDF text, share text, file paths, or customer content.
- Added widget tests for share failure callback, print failure callback, and successful share/print action reporting.
- Focused analyzer and generated PDF preview/service tests pass.

### PDF Pass 64 of up to 200: Invoice PDF Preview Surface Decision And Wiring

Status: complete.

Goal:
- Decide and implement the clean invoice preview surface so invoice-generated PDFs can report share/print/open activity without duplicate PDF writes or confusing navigation.

Scope:
- Compare the current invoice form preview path against `AppGeneratedPdfPreviewScreen`.
- Avoid duplicate temporary writes where possible.
- If the shared generated-PDF preview becomes the invoice surface, wire action callbacks into `InvoiceRecord` PDF delivery events.
- If invoice stays on the lightweight PDF viewer, document why and keep share/print tracking limited to the generated-PDF preview surface.

Done:
- Invoice form preview now uses `AppGeneratedPdfPreviewScreen` instead of separately writing a temporary PDF and pushing the plain PDF viewer.
- The shared generated-PDF preview reports prepared and preparation-failed events in addition to preview/share/print results.
- Invoice preview actions translate generic preview callbacks into invoice PDF delivery events for generated, shared, printed, and failed actions.
- Added a narrow invoice form testing seam for PDF preview factory/service injection without changing production defaults.
- Fixed invoice form draft creation so ledger notifications do not fire during dependency building.
- Added widget coverage proving invoice preview records generated, shared, and printed PDF events with only one temporary PDF preparation.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 65 of up to 200: PDF Preparation Failure And Retry Audit

Status: complete.

Goal:
- Make retry behavior and preparation failures produce useful, bounded, privacy-safe diagnostics without duplicate or misleading invoice history.

Scope:
- Verify generated-PDF preview retry behavior after preparation failure.
- Ensure invoice records can distinguish preparation failure from share/print failure.
- Keep repeated retries bounded by the existing PDF event history cap.
- Add tests for preparation failure followed by successful retry where feasible.

Done:
- Generated-PDF preview retry tests now assert preparation failure and later prepared events.
- Invoice preview widget coverage proves a preparation failure records a failed invoice PDF event and successful retry records a generated PDF event.
- Repeated retry history remains bounded by the existing invoice PDF event cap.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 66 of up to 200: PDF Delivery Event Semantics Cleanup

Status: complete.

Goal:
- Make PDF delivery event names and semantics precise enough for future Command One/support views.

Scope:
- Review whether dismissed share/print flows should be tracked as completed actions, cancelled actions, or no-ops.
- Add event types if needed so histories do not confuse a closed share sheet with a successful send.
- Preserve privacy-safe event maps and backward compatibility for existing events.
- Add focused tests for dismissed share/print behavior.

Done:
- Added `InvoicePdfDeliveryEventType.cancelled`.
- Added `InvoicePdfDeliveryEvent.cancelled` and `InvoiceRecord.recordPdfDeliveryCancelled`.
- Invoice preview now maps dismissed share sheets to `cancelled/share_sheet_dismissed` and closed print flows to `cancelled/print_flow_dismissed`.
- Added generated-PDF preview tests for dismissed share/print action callbacks.
- Added invoice preview tests proving dismissed share/print actions are not stored as successful shared/printed events.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 67 of up to 200: Invoice PDF Final Save Event Completeness

Status: pending.

Goal:
- Make final save/archive history as complete and truthful as preview history.

Scope:
- Verify final save records generated, archived, hash, and failure reason codes.
- Add focused tests around successful permanent PDF proof save and archive failures if feasible.
- Keep final save from storing PDF bytes, local paths, or private rendered PDF text.

Done:
- Saving an invoice or estimate with permanent PDF proof leaves the same quality of structured history as preview/share/print paths.

### Pass 21 of 40: Separate OCR Fallback

Status: pending.

Goal:
- Make fallback to separate photos reliable.

Scope:
- Ordered OCR per photo.
- Duplicate overlap text suppression.
- Missing middle section detection where possible.
- User-safe warnings.

Done:
- Bad stitching does not ruin the receipt read.

### Pass 22 of 40: S24 UI Review Batch 2

Status: pending.

Goal:
- Install UI/image/long-receipt batch to S24 Ultra.

Scope:
- Live capture.
- Photo review.
- Long receipt section capture.
- Stitch/fallback review.

Done:
- User can test real long receipt behavior on S24.

## OCR And Parser Intelligence Track

### Pass 23 of 40: OCR Reliability Audit

Status: pending.

Goal:
- Audit shared OCR service for photo, PDF, imported text, and stitched sources.

Scope:
- Timeouts.
- Page limits.
- Duplicate/overlap handling.
- Warnings.
- Older-phone workload limits.

Done:
- OCR service has clear behavior for every receipt source.

### Pass 24 of 40: OCR Diagnostics Hardening

Status: pending.

Goal:
- Make OCR failures explainable without exposing receipt content.

Scope:
- No text found.
- Blurry/unreadable.
- Too long/too large.
- Plugin unavailable.
- Timeout.
- Duplicate/overlap suppressed.

Done:
- Each OCR failure has confirmed cause or clear missing evidence.

### Pass 25 of 40: Expensify-Style Parser Fields

Status: pending.

Goal:
- Improve extraction for merchant, date, subtotal, tax, total, payment, receipt number.

Scope:
- Lowe's/Home Depot.
- Walmart/Target/general retail.
- Fuel receipts.
- Returns/negative lines.
- Regional convenience stores.

Done:
- Core receipt fields are extracted and confidence-scored.

### Pass 26 of 40: Parser Line Items

Status: pending.

Goal:
- Improve line item extraction.

Scope:
- Item description.
- Amount.
- Quantity.
- Unit/pack where available.
- Returns/discounts/negative lines.
- Taxable vs non-taxable signals where possible.

Done:
- Parsed lines match the receipt better and mark uncertainty clearly.

### Pass 27 of 40: Vendor Profiles

Status: pending.

Goal:
- Add maintainable vendor parsing profiles.

Scope:
- Vendor aliases.
- Receipt layout hints.
- Total/tax/date patterns.
- Fuel-specific profiles.
- Regional store hooks.

Done:
- Vendor matching is explainable and updateable.

### Pass 28 of 40: Correction Learning

Status: pending.

Goal:
- Use local corrections to improve future receipt parsing.

Scope:
- Original OCR text.
- Corrected field.
- Corrected category/item.
- Merchant context.
- Local-first storage.
- Future Firebase contribution remains opt-in.

Done:
- User corrections make future parsing better locally.

## Expense Review And Maintainiac Intelligence Track

### Pass 29 of 40: Receipt Review Screen Polish

Status: pending.

Goal:
- Make the parsed receipt review screen professional and fast.

Scope:
- Merchant/date/total summary.
- Line list.
- Confidence and review reasons.
- Edit/confirm/remove actions.
- No developer jargon.

Done:
- User knows what the app found and what needs review.

### Pass 30 of 40: Business Personal Mixed Whole Receipt

Status: pending.

Goal:
- Make whole-receipt classification fast.

Scope:
- All business.
- All personal.
- Mixed receipt.
- Keep selected state unmistakable.
- Update totals immediately.

Done:
- User can classify a simple receipt in seconds.

### Pass 31 of 40: Mixed Receipt Line Classification

Status: pending.

Goal:
- Make mixed receipt line-by-line classification fast.

Scope:
- Business/personal/split per line.
- Bulk actions.
- Keyboard/accessibility friendly.
- Clear line totals.

Done:
- Mixed receipts are manageable without frustration.

### Pass 32 of 40: Split Percent And Tax Allocation

Status: pending.

Goal:
- Make split math correct.

Scope:
- Business percentage.
- Personal percentage.
- Tax allocation.
- Receipt total reconciliation.
- Rounding rules.

Done:
- Business/personal totals are defensible and understandable.

### Pass 33 of 40: Simple Mode Detailed Mode

Status: pending.

Goal:
- Make simple and detailed receipt modes clear.

Scope:
- Simple mode: amounts and classification.
- Detailed mode: descriptions, quantity, unit, category, inventory fields.
- First-use explanation.
- Per-area settings.

Done:
- User understands the difference and can switch without confusion.

### Pass 34 of 40: Vehicle And Mixed-Use Expense Intelligence

Status: pending.

Goal:
- Use vehicle/profile context in receipt expenses.

Scope:
- Vehicle selected.
- Business/personal mileage share.
- Fuel/maintenance/repair/insurance/registration allocation.
- Odometer edge-case coordination.

Done:
- Shared-use vehicle expenses allocate correctly.

### Pass 35 of 40: Materials Inventory Bridge

Status: pending.

Goal:
- Keep expense receipts and inventory updates correctly separated.

Scope:
- Expense-origin materials stay expense-first.
- Ask whether to prepare inventory.
- Stage inventory changes.
- Confirm before inventory update.

Done:
- Inventory never changes behind the user's back.

## Storage, Sync, Privacy, Diagnostics, And QA Track

### Pass 36 of 40: Storage And Backup Policy

Status: pending.

Goal:
- Make receipt proof storage lean and understandable.

Scope:
- Local original temporary handling.
- Saved proof size.
- Cloud backup size.
- Low-storage behavior.
- Export implications.

Done:
- User storage and Firebase costs stay controlled.

### Pass 37 of 40: Firestore Sync Shape For Receipts

Status: pending.

Goal:
- Ensure receipt backup does not explode reads/writes/cost.

Scope:
- Local-first Hive source of truth.
- Firestore mirror documents.
- Bundled/summarized sync where feasible.
- Receipt image storage references.
- No private raw OCR text in telemetry.

Done:
- Receipt data can sync without runaway Firebase cost.

### Pass 38 of 40: Command One Diagnostics Feed

Status: pending.

Goal:
- Feed Command One with privacy-safe receipt health.

Scope:
- Capture success/failure.
- OCR success/failure.
- Parser success/failure.
- Review correction rate.
- Abandonment rate.
- Device tier and app version context.

Done:
- Command One can show what failed, where it failed, and why without private receipt content.

### Pass 39 of 40: Synthetic Torture Test Suite

Status: pending.

Goal:
- Build repeatable receipt tests before relying only on real receipts.

Scope:
- Lowe's/Home Depot.
- Walmart/Target.
- Fuel.
- Returns.
- Long receipts.
- Faded/wrinkled/noisy.
- Multi-photo overlap.

Done:
- Parser and OCR changes are regression-tested.

### Pass 40 of 40: Real Device And Real Receipt QA

Status: pending.

Goal:
- Prove the receipt flow on actual devices and actual ugly receipts.

Scope:
- S9 Plus class.
- S24/S25 class.
- iPhone class.
- Photo capture.
- Multi-photo stitching.
- OCR/parser review.
- Save and later calendar/detail review.

Done:
- The receipt system can be called ready for broader app testing.

## Camera-Only Continuation After PDF Freeze

The user paused PDF work until the receipt camera/capture/review flow is
professional and complete. The active lane resumes camera, OCR handoff,
stitching, and expense receipt review only.

### Camera/Receipt Pass 68 of up to 150: Review Tray And OCR Handoff Cleanup

Status: completed.

Goal:
- Make the receipt photo review path feel like a professional camera workflow,
  especially for one-photo receipts and long receipts.

Completed:
- Reserved more vertical room for the receipt image in preview, order, stitch,
  and saved-proof preview modes so the bottom controls do not cover the
  receipt being reviewed or cropped.
- Reworked the single-photo review tray so the primary action is clearly
  "Read Receipt" and the tool actions are secondary.
- Changed multi-photo wording from vague "sections" to plain "receipt photos,"
  with clear top-to-bottom ordering guidance.
- Renamed the review tool action to "Saved Proof Size" where the user previews
  the smaller backup image, while preserving that OCR reads the clear source
  first.
- Stopped the expense receipt screen from immediately kicking off a duplicate
  OCR scan after the shared receipt panel already reads the reviewed photo.
- Added visible parsing state and confirmed failure telemetry for the imported
  OCR text handoff into the expense parser.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue receipt photo review polish around crop ergonomics, stitch preview
  confidence, and the direct OCR-to-business/personal/mixed review landing.

### Camera/Receipt Pass 69 of up to 150: Crop Preview Crash And Crop Ergonomics

Status: completed.

Goal:
- Fix the receipt preview failure reported during camera/photo review and make
  receipt cropping behave more like a professional document/photo editor.

Completed:
- Moved cropper display-rect and initial-crop callbacks out of layout/build and
  into safe post-frame callbacks.
- Added mounted/context guards so crop callbacks do not update the review screen
  after the cropper has been disposed or after the user leaves crop mode.
- Added corner crop handles in addition to edge handles, so users can adjust a
  receipt crop from the corners instead of fighting one edge at a time.
- Wired the saved-proof preview card into the active Saved Proof Size mode so
  the user sees a plain-language storage preview instead of a dead/unused
  widget.
- Removed the unused photo-strip part and stale review-control widgets that
  were guarded by `unused_element` ignores.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart`
- `rg -n "unused_element|_ReceiptPhotoOrderCheckPanel|_ReceiptPreviewActions|_BestPhotoReviewNotice|_CompactPhotoActionButton|receipt_photo_review_strip|build preview|disposed" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart -S`

Next camera-only focus:
- Continue camera flow polish around the direct post-photo review landing,
  multi-photo stitch confidence, and making crop/stitch/data-saver modes feel
  like one coherent receipt-scanner workflow.

### Camera/Receipt Pass 70 of up to 150: Post-Photo Review Landing

Status: completed.

Goal:
- Make the app land on visible receipt review after the user accepts and reads a
  receipt photo, even when OCR/parser finds only header/totals and not line
  items.

Completed:
- Moved the receipt-review scroll target so it wraps the full parsed review
  block instead of only the line-item review panel.
- Kept whole-receipt business/personal/mixed controls and line review inside
  that same landing area when line items are available.
- Preserved the classification, OCR diagnostics, field confidence, and
  maintenance hint display as the first review surface after app-assisted photo
  reading.
- Verified the deleted legacy photo strip and stale review widgets are no
  longer referenced.

Verification:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_photo_section_labels_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_photo_review_strip.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart docs/receipt_camera_ocr_master_pass_plan.md`
- `rg -n "unused_element|_ReceiptPhotoOrderCheckPanel|_ReceiptPreviewActions|_BestPhotoReviewNotice|_CompactPhotoActionButton|receipt_photo_review_strip|build preview|disposed" lib/shared/widgets/receipt_capture test/receipt_camera_help_flow_test.dart test/receipt_photo_section_labels_test.dart -S`

Next camera-only focus:
- Continue with camera/stitch polish only: stitch confidence language, review
  action flow, and safer multi-photo long-receipt handling.

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
