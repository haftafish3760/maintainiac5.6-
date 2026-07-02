# Receipt Camera OCR Master Pass Plan Archive - Native Scanner Pass 103: iOS AVFoundation Brightness Assist

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Native Scanner Pass 103: iOS AVFoundation Brightness Assist

Status: complete.

What changed:
- Added AVFoundation parity for the receipt brightness assist path.
- Preserved safe diagnostics for brightness bucket, exposure decision, exposure
  bias, and adjustment timing without storing preview frames.

Validation:
- `flutter test test/receipt_native_ios_bridge_test.dart`

### Native Scanner Pass 104: Focus And Exposure Lock

Status: complete.

What changed:
- Wired focus/exposure mode settings through CameraX and AVFoundation.
- Added diagnostics for focus lock attempts, focus lock success, exposure lock
  success, and last focus status so capture health can be explained without
  receipt content.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

### Native Scanner Pass 105: White-Balance Lock

Status: complete.

What changed:
- Wired white-balance mode through the native camera bridge.
- Android records CameraX support limits as safe diagnostics; iOS locks white
  balance on supported devices and reports attempts/success/status.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

### Native Scanner Pass 106: OCR Prep Scanner Decision Codes

Status: complete.

What changed:
- Added exact, content-free scanner decision codes to OCR source preparation.
- Crop, orientation, straighten, cleanup, and OCR-source selection now report
  why they applied or skipped work, such as bounds too small, quality guard,
  no straighten benefit, cleanup applied for dark/glare/faded/soft text, or
  original source preserved for quality.
- Kept OCR prep privacy-safe: diagnostics do not include receipt text, merchant,
  address, line items, notes, source file path, or customer content.

Validation:
- `flutter test test/receipt_image_data_saver_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_stitching_test.dart`

### Native Scanner Pass 107: Review Result Scanner Summary

Status: complete.

What changed:
- Added receipt review result helpers that summarize scanner decision codes and
  counts from the accepted OCR-prep diagnostics.
- Added safe flags for enhanced OCR source use, original-source quality guard,
  and operator-review-needed scanner concerns.
- This gives future UI/Command Center work a direct summary API instead of
  forcing every caller to parse raw diagnostic maps.

Validation:
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test test/receipt_image_data_saver_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze` now reports only the unrelated generated inventory warning
  at `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66`.

### Native Scanner Pass 108: Exact Crop Safety Buckets

Status: complete.

What changed:
- Replaced the generic crop safety rejection with exact, content-free reason
  codes for bounds too narrow, too short, aspect too wide/tall, off-center X,
  and off-center Y.
- Kept the original safe behavior: unsafe crop suggestions still preserve the
  original OCR source instead of cutting off receipt information.
- Updated review-result scanner concern detection so meaningful crop-skip
  reasons are flagged for operator review, while user-disabled crop cleanup is
  not treated as a camera problem.

Validation:
- `flutter test test/receipt_image_data_saver_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test --concurrency=1 test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_stitching_test.dart`
- `flutter analyze` still reports only the unrelated generated inventory warning
  at `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66`.

### Native Scanner Pass 109: Perspective Readiness Diagnostics

Status: complete.

What changed:
- Added a separate content-free perspective-readiness check during OCR source
  preparation instead of treating perspective correction as a vague straighten
  setting.
- The scanner now reports whether perspective work was ready, disabled, missing
  bounds, too small, off-center, aspect-unsafe, or too weak to trust.
- Review-result scanner concern detection now flags meaningful perspective-skip
  reasons for review while ignoring the normal user-disabled setting state.
- This does not store receipt text, merchant, address, customer content, line
  items, notes, or source file paths.

Validation:
- `flutter test test/receipt_image_data_saver_test.dart test/receipt_camera_result_test.dart`
- `flutter test --concurrency=1 test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_stitching_test.dart`
- `flutter analyze` still reports only the unrelated generated inventory warning
  at `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66`.

Next camera-only focus:
- Continue with scanner-quality hardening around crop/perspective confidence,
  image clarity parity with native camera behavior, and physical-device review
  flow checks before parser/PDF/Firebase work resumes.

### Native Scanner Pass 110: Native Perspective Telemetry Handoff

Status: complete.

What changed:
- Carried `latestPerspectiveReadiness` from the Android CameraX and iOS
  AVFoundation camera bridges through native capture staging, recovery
  manifests, and the Hive recovery index.
- Aggregated perspective readiness into expense receipt telemetry as
  `perspectiveReadinessBuckets` so Command 1 can later show why scanner cleanup
  was ready, skipped, or blocked without exposing receipt content.
- Kept the telemetry path privacy-safe: the allowlist accepts only reason-code
  buckets, not receipt text, merchant names, addresses, line items, notes,
  image content, or file paths.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with native review/back behavior, preview brightness parity, and
  physical-device capture quality checks before parser/PDF/Firebase work
  resumes.

### Native Scanner Pass 111: Back During Save Guard

Status: complete.

What changed:
- Hardened Android CameraX and iOS AVFoundation close behavior when Back is
  pressed while a receipt photo is still saving.
- The camera now marks a pending close, disables repeat capture/finish actions,
  shows "Finishing this receipt photo before closing.", waits for the save
  callback, then returns the captured section instead of silently cancelling or
  throwing away the photo.
- Added a privacy-safe `pendingCloseAfterCapture` diagnostic through native
  staging, recovery manifests, Hive recovery index, and expense telemetry as
  `pendingCloseAfterCaptureCount`.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with preview/capture brightness parity and captured-image quality
  diagnostics before parser/PDF/Firebase work resumes.

### Native Scanner Pass 112: Receipt-Targeted Exposure Assist

Status: complete.

What changed:
- Prevented Android CameraX and iOS AVFoundation auto-brightness assist from
  adjusting exposure against the entire camera frame before a receipt-like
  target is found.
- Auto exposure now waits for receipt framing and records
  `waiting_for_receipt_target` instead of darkening or brightening random
  background frames while the user is lining up the receipt.
- Added privacy-safe auto-exposure decision buckets through staging and expense
  telemetry so Command 1 can later distinguish brightness decisions such as
  waiting for target, brightening, dimming, manual override, or unsupported
  device behavior.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with captured-image quality parity, review-screen clarity, and
  physical-device handoff behavior before parser/PDF/Firebase work resumes.

### Native Scanner Pass 113: Exposure Stability Gate

Status: complete.

What changed:
- Added a two-frame stability gate before CameraX or AVFoundation auto exposure
  assist brightens or dims a receipt.
- The app now records `stabilizing_brighten` or `stabilizing_dim` while it waits
  for repeated receipt-target evidence, reducing one-frame exposure jumps that
  can make the preview look darker or stranger than the stock camera.
- Added privacy-safe diagnostics for `lastAutoExposureCandidate` and
  `autoExposureCandidateFrameCount`, then summarized them into expense
  telemetry as `autoExposureCandidateBuckets` and
  `autoExposureCandidateFrameTotal`.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with captured-image quality parity, review-screen clarity, and
  physical-device handoff behavior before parser/PDF/Firebase work resumes.

### Native Scanner Pass 114: Captured Image Quality Buckets

Status: complete.

What changed:
- Added native captured-photo quality diagnostics after each saved receipt photo
  on Android CameraX and iOS AVFoundation.
- Android now reads JPEG bounds with `BitmapFactory` and iOS reads image
  dimensions with `UIImage(data:)` after capture.
- Recorded content-free quality fields:
  `latestCapturedPhotoWidth`, `latestCapturedPhotoHeight`,
  `latestCapturedMegapixelBucket`, `latestCapturedByteBucket`, and
  `photoByteSizeBucket`.
- Threaded those diagnostics through native staging, recovery manifests, Hive
  recovery index, and expense telemetry as aggregate buckets/max dimensions.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with review-screen clarity and physical-device handoff behavior
  before parser/PDF/Firebase work resumes.

### Native Scanner Pass 115: Review Screen Clarity And Next Action Copy

Status: complete.

What changed:
- Tightened the post-capture receipt review tray so the primary action now says
  `Next: Review Details` instead of a vague or internal-sounding receipt action.
- Reworded single-photo and long-receipt review guidance so users understand
  that they can add another photo for a long receipt or tap Next to review what
  Maintainiac read.
- Renamed unclear review copy such as `Add Receipt Section` and saved-proof
  language to plain receipt-user language: `Add Another Photo`, backup image
  size, and receipt details.
- Updated the unsaved-photo exit dialog to explain that Next reviews what
  Maintainiac read instead of sending the user back to the generic expense form.

Validation:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with physical-device review behavior, capture quality parity, and
  next-screen handoff hardening before parser/PDF/Firebase work resumes.

### Native Scanner Pass 116: Receipt Details Handoff Copy And Backup Image Language

Status: complete.

What changed:
- Hardened the accepted-photo handoff language after `Next` so the app says it
  is preparing receipt details and reviewing what Maintainiac read, instead of
  sounding like it is returning to a generic expense screen.
- Replaced remaining `saved proof copy`/`receipt proof saved` wording in the
  active receipt capture/review path with plain `backup image` language.
- Clarified the app-assisted read status for combined, top-to-bottom, and
  single receipt photos so the user sees that Maintainiac read the receipt and
  that the next work is checking what was filled in.
- Kept OCR source behavior unchanged: receipt reading still uses the clearest
  source before the smaller backup image is used for storage.

Validation:
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_image_data_saver_test.dart`
- `flutter analyze` still reports only the unrelated generated fencing warning:
  `lib/screens/work_supplies/data/catalog/fencing/generated_fencing_detail_catalog.dart:66:26 unused_local_variable`

Next camera-only focus:
- Continue with physical-device capture quality parity and native camera review
  behavior before parser/PDF/Firebase work resumes.

### Native Scanner Pass 117: Captured Photo Brightness And Sharpness Diagnostics

Status: complete.

What changed:
- Added native, content-free diagnostics for the actual saved receipt photo on
  Android CameraX and iOS AVFoundation, instead of judging only the live camera
  preview.
- Android and iOS now sample the accepted image after capture and bucket its
  brightness, sharpness, overall quality signal, and preview-versus-capture
  exposure mismatch.
- Threaded the new safe diagnostic fields through receipt capture staging,
  recovery metadata, and expense telemetry so Command 1 can later show whether
  receipt failures are tied to dark captures, soft captures, glare risk, or
  live/captured exposure mismatch without storing receipt content.
- Kept OCR and parser behavior unchanged in this pass; this pass only adds the
  measurement layer needed to prove why a captured photo looks worse than the
  stock camera image.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`

Next camera-only focus:
- Continue with physical-device review behavior, back-navigation hardening, and
  capture-quality parity before parser/PDF/Firebase work resumes.

### Native Scanner Pass 118: Android System Back Hardening

Status: complete.

What changed:
- Added Android 13+ `OnBackInvokedCallback` handling to the native CameraX
  receipt camera so system back, gesture back, and the on-screen back button all
  use the same `requestCloseCamera()` path.
- Kept the older `onBackPressed()` fallback for older Android versions.
- Registered the system-back handler when the native receipt camera opens and
  unregisters it during destroy so the callback cannot leak after the camera is
  closed.
- Preserved the existing captured-photo safety behavior: if a receipt photo is
  already saved, back returns the captured sections; if capture is in flight,
  back waits for the in-flight photo to finish; if no photo exists, back cancels.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`

Next camera-only focus:
- Continue with physical-device review behavior, capture-quality parity, and
  accepted-photo handoff into receipt detail review before parser/PDF/Firebase
  work resumes.

### Native Scanner Pass 119: Failed Read Still Opens Receipt Review

Status: complete.

What changed:
- Added an explicit `_receiptReadAttemptedWithoutText` state so accepting a
  receipt photo can still open a receipt-review recovery area even when OCR
  cannot produce usable text.
- Changed the no-text read handoff to scroll into the receipt review/recovery
  area instead of returning the user to the attachment area and making it feel
  like nothing happened.
- Updated the no-line recovery copy so it says Maintainiac could not read
  usable receipt text from that photo when no text came through, instead of
  claiming receipt text was read.
- Confirmed the photo-quality helper and receipt privacy feature getter are
  syntactically clean while tracing this path.

Validation:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_native_android_bridge_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_native_android_bridge_test.dart`

Next camera-only focus:
- Continue with iOS native compile sanity, capture-quality parity, and review
  screen layout polish before parser/PDF/Firebase work resumes.

### Native Scanner Pass 120: Single Photo Review Action Clarity

Status: complete.

What changed:
- Renamed the primary single-photo review action from `Next: Review Details` to
  `Next: Review Receipt` so the user understands the next screen is the
  app-filled receipt review, not a vague detail page.
- Renamed the single-photo backup-size tool from `Proof Size` to `Backup Size`
  in the active review tray.
- Kept the receipt image dominant in the post-capture review screen while
  leaving the compact bottom tray available for add another photo, retake,
  adjust, backup size, and Next.
- Rechecked the review controls file after noisy terminal output made it look
  duplicated; the active file analyzes cleanly.

Validation:
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with broader analyzer cleanup, iOS native compile sanity, and
  capture-quality parity before parser/PDF/Firebase work resumes.

### Native Scanner Pass 121: iOS Native Camera Build Sanity

Status: complete.

What changed:
- Verified the iOS AVFoundation receipt camera changes compile inside the full
  iOS Runner workspace.
- Confirmed the captured-photo brightness/sharpness diagnostics and native
  receipt camera bridge do not break the simulator build.
- No camera behavior changed in this pass; this was a native build gate after
  Android CameraX had already compiled.

Validation:
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`
- Result: `BUILD SUCCEEDED`.
- Notes: Xcode emitted stale-file warnings under `build/ios/Debug-iphonesimulator`,
  but no Swift/AVFoundation compile failure.

Next camera-only focus:
- Continue with physical-device capture-quality parity, review-screen polish,
  and native camera interaction hardening before parser/PDF/Firebase work
  resumes.

### Native Scanner Pass 122: Saved Photo Quality Warning In Review

Status: complete.

What changed:
- Threaded the selected photo's native CameraX/AVFoundation capture diagnostics
  into the post-capture receipt review tray.
- Added plain-language review warnings for saved photos that came out darker
  than the live camera preview, dimmer than expected, soft/blurry, or at glare
  risk.
- Kept the warning content privacy-safe by using only bucketed native diagnostic
  keys such as captured brightness, captured sharpness, quality signal, and
  preview-versus-capture exposure mismatch.
- Preserved the existing flow: users can retake, add another photo, crop, or tap
  Next to review what Maintainiac read.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with physical-device capture-quality parity, especially native
  preview/capture brightness behavior and post-capture review clarity before
  parser/PDF/Firebase work resumes.
