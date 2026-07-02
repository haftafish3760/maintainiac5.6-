# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 846: Native Pre-Capture Exposure Dim Rescue V2

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 846: Native Pre-Capture Exposure Dim Rescue V2

Status: complete.

What changed:
- Separated the live preview exposure policy from the final pre-capture
  exposure policy in the shared Dart native camera service contract.
- Added `preCaptureExposurePolicy` to the Android CameraX and iOS AVFoundation
  launch arguments so each native layer receives the dim-rescue policy directly
  instead of accidentally reusing the preview policy.
- Strengthened the pre-capture dim rescue thresholds so receipts that still
  measure dark before shutter receive stronger exposure lift before the saved
  image is handed to review/OCR.
- Relaxed the auto-capture readable-light floor from 122 to 112 luma so the
  guidance does not over-block readable receipts, while manual shutter remains
  available.
- Added `previewExposurePolicy`, `preCaptureExposurePolicy`,
  `previewBrightnessGuardPolicy`, and `shutterSpeedPolicy` to safe native
  capture staging diagnostics so recovery/Command One can explain dark-photo
  behavior without recording receipt content.
- Updated bridge and contract tests so stale `92`/old-policy expectations do
  not mask another dark-preview/dark-capture regression.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`

Blocked validation:
- Native Gradle compile was not rerun in this pass because the previous pass
  already proved this environment has no Java runtime installed.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is runtime review-flow hardening around
  photo accept/back behavior and ensuring accepted photos can move straight to
  receipt-detail review without returning to the expense home screen.

### Receipt Camera Reopen Pass 847: Accepted Photo Receipt-Details Handoff Guard

Status: complete.

What changed:
- Hardened the reviewed-photo accept path so accepted receipt photos explicitly
  call the parent `onReceiptReadStarted` callback before OCR work begins.
- This makes the parent expense receipt screen enter the receipt-details review
  state immediately for accepted photos, instead of depending only on the
  attachment/status panel to imply that receipt reading has started.
- Kept the existing app-assisted flow intact: accepted photo review still
  publishes the photo review result, shows the "opening receipt details" status,
  reads prepared OCR source photos before saved proof copies, then marks the
  photo read state.
- Added source-level guards proving accepted native/shared receipt photos start
  receipt-details review before OCR completes and before any backup/import
  fallback path can run.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the photo review exit/back
  behavior so accidental back presses after capture do not silently discard the
  accepted image or strand the user without a clear Next/receipt-details route.

### Receipt Camera Reopen Pass 844: Zoom Diagnostics To Command One Batch

Status: complete.

What changed:
- Carried native pinch-zoom diagnostics from accepted receipt capture
  diagnostics into the privacy-safe OCR-start telemetry bundle.
- Added Command One health counters for zoom gesture starts, actual zoom
  changes, zoom-unavailable cases, and top zoom status buckets.
- Kept the diagnostics content-free: Command One can tell whether pinch never
  reached the camera surface, the camera was unavailable, zoom was locked, or
  zoom changed, without storing receipt text, images, prices, merchant names, or
  user content.
- Added regression coverage for telemetry sanitization, Command One summary
  aggregation, and the receipt-assisted review flow source checks.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture lifecycle/back-button
  hardening so disposed-preview crashes and trapped camera screens are diagnosed
  and prevented instead of tolerated.

### Receipt Camera Reopen Pass 845: Native Back And Lifecycle Hardening Batch

Status: complete.

What changed:
- Hardened Android native receipt-camera close handling by routing legacy back,
  hardware key back, Android 13 predictive back, and the visible top-left back
  button through the same `requestCloseCamera` path with a privacy-safe
  `lastBackDispatchPath` diagnostic.
- Added Android exposure-prep abort handling so an exposure-adjustment callback
  that returns after the camera surface is gone clears in-flight capture state
  instead of leaving the camera flow hanging.
- Added iOS `lastBackDispatchPath` diagnostics for the visible native back
  button.
- Preserved those diagnostics through native capture staging and surfaced them
  into expense telemetry/Command One as `backDispatchPathBuckets`,
  `preCaptureExposureAbortTotal`, and
  `preCaptureExposureAbortReasonBuckets`.
- Kept everything content-free: diagnostics report lifecycle/control state only,
  never receipt images, OCR text, merchant names, prices, addresses, or item
  descriptions.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Blocked validation:
- `./gradlew :app:compileDebugKotlin` could not run because this Mac currently
  reports no Java runtime. Native Kotlin syntax should still be verified once
  Java/Gradle is available.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reducing preview/capture brightness
  mismatch and capture latency diagnostics so the native receipt camera stops
  producing darker/slower photos than the platform camera under the same light.

### Receipt Camera Native Pass 841: Fast Document Shutter Contract Batch

Status: complete.

Timestamp: 2026-06-30 05:09:53 EDT.

What changed:
- Tightened the native Android CameraX capture path so the default and
  non-light-device still capture mode is `receipt_fast_document_shutter`.
- Removed the stale Android `receipt_quality_sharp` default and kept the
  capture mode on `CAPTURE_MODE_MINIMIZE_LATENCY` for receipt/document capture.
- Tightened the iOS AVFoundation capture path so native still capture uses
  `receipt_fast_document_shutter` with balanced quality prioritization instead
  of the slower quality-priority branch.
- Updated the shared native camera settings contract to report fast document
  shutter policies for manual and opt-in auto capture.
- Updated bridge/layout/contract tests so the app now guards against falling
  back to slow quality-priority still capture modes while preserving the OCR
  source-image contract separately from storage-saving copies.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_result_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native preview/capture parity:
  brightness diagnostics, tap-focus/exposure behavior, and review speed signals
  that explain why a custom receipt capture looks darker or softer than the
  phone stock camera without exposing receipt content.

### Receipt Camera Native Pass 842: Pinch Zoom Touch-Surface Diagnostics Batch

Status: complete.

Timestamp: 2026-06-30 05:09:53 EDT continuation.

What changed:
- Wired Android pinch/tap preview handling through the receipt frame overlay as
  well as the preview surface, so pinching on the visible receipt guide is no
  longer dependent on the underlying `PreviewView` receiving the gesture.
- Added native Android zoom diagnostics: gesture starts, unavailable zoom
  attempts, last zoom status, and last zoom ratio.
- Added matching iOS AVFoundation zoom diagnostics for gesture starts,
  unavailable zoom attempts, last zoom status, and last zoom ratio.
- Kept diagnostics privacy-safe: these counters describe camera controls only,
  not receipt text, merchant names, prices, locations, or image content.
- Updated native bridge source tests to guard the overlay touch route and the
  zoom diagnostic handoff.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is closing the remaining live-preview
  parity gaps: brightness/exposure behavior, saved-photo darkness evidence, and
  making sure the review path leads clearly to receipt details after accepted
  photos.

### Receipt Camera Native Pass 843: Accepted Photo To Receipt Details Handoff Batch

Status: complete.

Timestamp: 2026-06-30 05:09:53 EDT continuation.

What changed:
- Tightened the accepted-photo handoff language so the expense receipt screen
  says the app is reading receipt text before opening receipt details, instead
  of using a vague generic stage.
- When OCR completes from accepted photos, the expense screen now updates the
  handoff stage for both success and failure and scrolls back to the
  receipt-details review area.
- Tightened attached-proof OCR stages so the user sees reading proof, filling
  receipt details, or manual-review wording at the right point in the flow.
- Updated the assisted review guard test to lock in the intended user path:
  accepted photos lead to receipt details, not back to receipt capture.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another bundled native-camera polish
  pass around brightness parity and review latency evidence before moving into
  deeper OCR/parser accuracy.

### Receipt Camera Reopen Pass 839: Captured Review Exit Recovery Batch

Status: complete.

What changed:
- Added an explicit `ReceiptPhotoReviewResult.keptForLater` outcome for the
  photo review screen so backing out after capture no longer looks like a plain
  cancel or silent discard.
- Kept retained photos out of OCR handoff by disabling saved-proof fallback for
  kept-for-later review results; OCR still only starts after the user taps Next
  to review receipt details.
- Changed the review close path to pop a kept-for-later result with photo count,
  recovery-safe diagnostics, and no receipt content.
- Updated fresh native capture and recovered native capture flows to mark
  `review_closed_kept_for_later` / `recovery_review_closed_kept_for_later`
  stages and return clear resume-safe diagnostics.
- Added regression coverage for accepted handoff metadata, kept-for-later
  non-OCR handoff, shared flow recovery stages, and the photo review close path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is broad receipt-slice verification,
  then the next camera pass should tighten native preview/capture parity and
  manual-shutter/back responsiveness without touching PDF, Firebase, or
  inventory.

### Receipt Camera Reopen Pass 840: Native Capture Responsiveness Diagnostics Batch

Status: complete.

What changed:
- Added monotonic Android CameraX timing diagnostics for shutter-to-saved and
  shutter-to-review-ready latency.
- Added matching AVFoundation timing diagnostics on iOS for parity.
- Added a shared privacy-safe responsiveness policy token:
  `manual_shutter_to_review_should_feel_immediate`.
- Added Dart camera-health buckets for native capture latency so Command One can
  eventually show whether the camera is fast, watch-worthy, or slow without
  seeing any receipt content.
- Added regression tests for Android/iOS bridge parity and Dart health summaries
  for ready and slow capture latency.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Blocked validation:
- `./gradlew :app:compileDebugKotlin` could not run because this environment
  could not locate a Java runtime.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native source review for preview
  brightness/shutter behavior and any code-level fixes that keep manual capture
  responsive while preventing saved photos from coming out darker than the live
  preview.

### Receipt Camera Reopen Pass 837: Review Copy Guard Alignment Batch

Status: complete.

What changed:
- Updated the receipt photo review guard tests to match the current production
  language: the primary action is `Next: Review Receipt Details`.
- Kept the guard focused on the requirement that Next opens receipt details
  with item prices, totals, and business/personal use rather than returning the
  user to the receipt attachment area.
- Updated the quality-score copy guard to match the current semicolon label
  used by the post-capture quality summary.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native bridge lifecycle and control
  parity around back/close, tap-focus, pinch-zoom, exposure/reset, and settings
  diagnostics.

### Receipt Camera Reopen Pass 838: Native Control Readiness Diagnostics Batch

Status: complete.

What changed:
- Added Android CameraX control-readiness diagnostics for back, settings,
  manual shutter, tap focus, pinch zoom, brightness slider, and brightness
  reset.
- Added matching iOS AVFoundation control-readiness diagnostics so both native
  camera bridges report the same privacy-safe health shape.
- Added Dart-side health buckets that separate expected control visibility from
  actual control readiness, including specific buckets for missing/disabled
  pinch zoom, tap focus, manual shutter, settings, back, and exposure controls.
- Kept diagnostics content-free: they report control status and counts only,
  never receipt text, merchant names, prices, addresses, or line content.
- Updated guard coverage so native bridge tests require the readiness fields
  and receipt result tests prove Command One-style health can distinguish
  missing control contracts from actual native-control failures.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "native camera"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "native bridge source rejects stock camera controllers"`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the accepted-photo review
  flow harder to accidentally abandon by preserving captured sections and
  making every close/back path either return sections or clearly cancel with no
  photo.

### Receipt Camera Reopen Pass 830: Photo Review Async Lifecycle Hardening Batch

Status: complete.

What changed:
- Hardened crop-image loading so decoded bytes cannot update review state after
  the user leaves crop mode, changes photos, or closes the review screen.
- Added a post-dialog mounted/closing guard to the leave-review path so back or
  close cannot continue through a stale review state after an async confirmation.
- Kept the fix focused on the receipt photo review crash class reported from
  `buildPreview`/disposed review state behavior.
- Expanded the lifecycle regression guard so the crop-mode async check is
  enforced alongside the existing save/close cleanup checks.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another lifecycle/responsiveness pass
  around camera reopen, add-photo, retake, and review-exit paths so captured
  receipt photos are not easy to lose and stale async camera work cannot update
  disposed review UI.

### Receipt Camera Reopen Pass 831: Stale Stitch Preview Release Batch

Status: complete.

What changed:
- Hardened long-receipt stitch preview work so a stale async stitch result
  cannot leave `_stitchPreviewInFlight` stuck after receipt photos, order, or
  review generation changes.
- Deletes stale generated stitch previews before returning.
- Releases the stale in-flight stitch state and schedules a fresh stitch preview
  when the review screen is still active.
- Added source coverage so stale stitch paths must call the release helper and
  reset the in-flight state.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is camera reopen/add-photo/retake
  responsiveness and making sure native camera results cannot be confused with
  stale review actions.

### Receipt Camera Reopen Pass 832: Anchored Review Photo Action Batch

Status: complete.

What changed:
- Hardened Add Photo so new long-receipt sections insert after the original
  guide photo instead of whatever index happens to be selected after the native
  camera returns.
- Hardened Retake so the returned camera photo replaces the original target
  receipt section, and safely no-ops if that section was removed while async
  camera work was in progress.
- Hardened Remove so the confirmation sheet deletes the photo that opened the
  sheet, not a later-selected photo.
- Added source coverage for guide-photo anchoring, retake target anchoring, and
  remove target anchoring.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review save/continue resilience and
  making sure accepted camera photos always move toward receipt details without
  losing staged images or running stale OCR prep.

### Receipt Camera Reopen Pass 833: Stitched OCR Exact Order Guard Batch

Status: complete.

What changed:
- Hardened the final stitched-OCR handoff so an existing stitch preview is
  reused only when the exact saved receipt-photo order still matches.
- Removed the older length-only trust check that could allow a stale stitch
  preview to be reused after photo reorder/retake/add-photo changes.
- Manual overlap settings are now reused only when the current photo order
  matches the saved snapshot; otherwise the final OCR stitch rebuilds from the
  saved OCR source photos.
- Added source coverage for exact order matching and for preventing the stale
  length-only check from returning.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-save failure recovery and
  clearer separation between OCR source photos and saved proof copies.
