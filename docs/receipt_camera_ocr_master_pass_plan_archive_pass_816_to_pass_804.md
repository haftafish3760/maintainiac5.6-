# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 816: Native Dim-Receipt Exposure Rescue Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 816: Native Dim-Receipt Exposure Rescue Batch

Status: complete.

What changed:
- Tightened CameraX pre-capture exposure prep so dim receipt frames in the
  `93-138` brightness zone get a gentle brightness lift before capture instead
  of being left at native auto exposure.
- Added the same gentle dim-zone lift to the AVFoundation receipt camera bridge.
- Kept bright/glare handling conservative: the native camera baseline is still
  kept for bright receipts, and manual shutter remains available immediately.
- Extended native bridge guards so Android and iOS both keep the new dim-zone
  pre-capture rescue policy.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the native capture diagnostics
  explain when pre-capture brightness was lifted and whether the saved image
  still came out darker than the live preview.

### Receipt Camera Reopen Pass 817: Native Exposure Outcome Diagnostics Batch

Status: complete.

What changed:
- Added a platform-matched pre-capture exposure outcome diagnostic to CameraX
  and AVFoundation receipt capture.
- The new diagnostic reports plain outcome buckets such as
  `lifted_for_dim_receipt`, `kept_native_auto`, `manual_brightness_used`,
  `assist_off`, and `adjustment_not_confirmed`.
- Kept the diagnostic privacy-safe: it describes camera/exposure behavior only,
  not receipt text, merchant data, prices, or user content.
- Extended native bridge contract tests so Android and iOS both expose the same
  outcome key.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing the exposure outcome in
  Flutter-side native saved-photo warning models so the review screen can say
  exactly whether Maintainiac brightened, kept native auto, or still needs a
  retake for a dark saved photo.

### Receipt Camera Reopen Pass 818: Flutter Exposure Outcome Warning Batch

Status: complete.

What changed:
- Added `preCaptureExposureOutcome` to the shared receipt capture diagnostic
  keys.
- Taught `ReceiptNativeSavedPhotoReviewWarning` to use the native exposure
  outcome when deciding whether a saved photo stayed dim after brightness
  assist.
- Kept the warning user-facing and specific: if the camera lifted brightness
  but the saved receipt still looks dim, the review warning points at checking
  text, adding light, or retaking.
- Updated the receipt camera layout guard to verify the new diagnostic key and
  outcome value are part of the model contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review surfaces native saved-photo quality warnings"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking native review-state speed
  and labels after capture so the user sees a fast, clear review instead of a
  confusing pause or generic camera-app handoff.

### Receipt Camera Reopen Pass 819: Native Post-Capture Next Copy Batch

Status: complete.

What changed:
- Tightened Android and iOS native post-capture guidance after a receipt
  section is saved.
- Replaced vague "add the next section, or tap Next to review the receipt" copy
  with explicit "Add Another Photo if the receipt continues, or tap Next:
  Review Receipt Details."
- Kept the top and bottom native Next controls in place so captured-photo review
  is reachable immediately after capture.
- Updated native bridge guards for both CameraX and AVFoundation.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening review-loading/status
  copy on the Flutter review screen so "Opening/Preparing" always names receipt
  details, not a vague receipt review.

### Receipt Camera Reopen Pass 820: Flutter Receipt-Details Handoff Copy Batch

Status: complete.

What changed:
- Replaced Flutter review loading semantics from "Opening filled receipt
  review" to "Opening receipt details."
- Changed the compact primary review button loading text from "Opening" to
  "Opening Details."
- Changed the persistent stacked Next button from "Next / Review Receipt" to
  "Next / Receipt Details."
- Replaced the inline status "Preparing receipt details..." with "Opening
  receipt details..." so the handoff reads like an actual next screen.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening receipt review mode titles
  and help copy where "review receipt" could still mean image review instead of
  parsed receipt details.

### Receipt Camera Pass 807: Native Guidance And Control Contract Cleanup Batch

Status: complete.

What changed:
- Softened native live guidance on Android and iOS so the camera tells the user
  what to improve without blocking a readable manual photo.
- Restored native-specific pinch-zoom policy defaults:
  CameraX zoom-ratio clamping on Android and AVFoundation video-zoom clamping on
  iOS.
- Kept diagnostics configurable by wiring `pinchZoomPolicy` through the session
  zoom policy instead of hard-coding a single literal in the capture result.
- Replaced remaining user-facing "backup copy" wording in native settings with
  saved-proof language while preserving true cloud-backup wording where it
  refers to cloud backup.
- Updated native bridge tests to verify exact shutter block reasons, including
  busy capture, closing camera, inactive camera surface, and no camera.
- Updated native bridge tests to match the current receipt-paper metering
  exposure policy instead of stale dim-receipt policy wording.

Validation:
- `dart format test/receipt_native_ios_bridge_test.dart test/receipt_native_android_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the native settings copy
  and saved-proof/data-saving controls so they stay user-readable, receipt-first,
  and consistent across Android, iOS, and the Flutter review screens.

### Receipt Camera Pass 808: Native Saved-Proof Settings Language Batch

Status: complete.

What changed:
- Replaced native camera status-strip "backup" wording with "saved proof" so
  the live camera UI does not confuse saved proof size with cloud backup or the
  fallback phone camera path.
- Renamed Android saved-proof choices from "Normal backup" and "Tiny backup" to
  "Normal proof" and "Tiny proof".
- Renamed iOS saved-proof labels from "Normal backup" and "Tiny backup" to
  "Normal proof" and "Tiny proof".
- Kept true cloud-backup wording where the copy is explicitly about cloud
  backup storage.
- Updated native bridge contract tests so Android and iOS protect the same
  user-facing vocabulary.

Validation:
- `dart format test/receipt_native_ios_bridge_test.dart test/receipt_native_android_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the Flutter review proof
  controls where any remaining backup/compression-style wording leaks into the
  user-facing receipt review UI.

### Receipt Camera Pass 809: Flutter Review Saved-Proof Copy Cleanup Batch

Status: complete.

What changed:
- Cleaned the receipt photo review proof controls so visible copy says saved
  proof instead of backup/compression language.
- Changed the smallest proof option from "Smallest backup" to "Smallest proof".
- Changed the full-source cleanup explanation from "backup compression" to
  "saved-proof shrinking".
- Changed the black-and-white cleanup explanation so it says the saved proof
  stays smaller without changing the OCR source.
- Updated current camera/OCR product and state-of-art docs so they state the
  same source-first rule: never OCR the smaller saved proof when a cleaner
  prepared source exists.
- Updated the real-device test script wording so tester judgment stays focused
  on OCR source quality, not saved-proof size.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`
- `flutter test test/receipt_camera_help_flow_test.dart --name "reviewed camera photos read OCR sources before saved copies"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is finding remaining user-facing receipt
  review wording that could still make the phone-camera fallback, cloud backup,
  and saved-proof image sound like the same thing.

### Receipt Camera Pass 810: Phone Camera Fallback Wording Batch

Status: complete.

What changed:
- Reworded visible fallback-camera copy from "backup camera option" to "phone
  camera fallback" so the user can tell Maintainiac's native receipt camera is
  still the primary scanner.
- Reworded import and long-receipt add-photo fallback messages from "opening
  your phone camera as a backup" to "opening your phone camera as a fallback".
- Reworded document-scanner fallback notices so they say Maintainiac may use the
  phone camera as a fallback if needed.
- Updated fallback diagnostics user-facing labels to "Phone camera fallback".
- Updated tests that protect native-first/fallback-only camera behavior.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "review add-photo flow also uses native capture before fallback"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "ocr source handoff helpers stay aligned across receipt paths"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt import uses Maintainiac native camera before any fallback"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is improving the receipt review screen's
  single-photo path so it keeps a clear Next/Add Photo/Proof progression without
  hiding critical actions in a cramped tray.

### Receipt Camera Pass 811: Single-Photo Review Clarity Batch

Status: complete.

What changed:
- Changed the single-photo review badge from a fake ordinal state like "Photo 1
  of 1" to "Receipt Photo".
- Kept multi-photo/long-receipt badges as "Photo X of Y" so section order is
  still clear when more than one receipt photo exists.
- Tightened single-photo section guidance to say add another photo only if the
  receipt continues; otherwise tap Next.
- Updated layout tests so the single-photo and multi-photo labels stay
  distinct.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the saved-proof preview
  controls so the "Space" action tells the user they can inspect actual saved
  proof size without suggesting OCR quality is based on that smaller image.

### Receipt Camera Pass 812: Saved-Proof Preview Action Label Batch

Status: complete.

What changed:
- Changed the compact single-photo review action from "Space" to "Proof" so the
  button points at the saved proof preview instead of a vague storage concept.
- Updated the action tooltip from "Preview saved receipt size" to "Preview
  saved proof size".
- Kept the label intentionally short so the compact receipt tray stays small.
- Updated layout tests so the old "Space" label does not come back.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the saved-proof preview
  panel itself so the user can see original size, saved-proof size, and cloud
  backup impact without any OCR-quality confusion.

### Receipt Camera Reopen Pass 801: Compact Single-Photo Review Action Labels Batch

Status: complete.

What changed:
- Tightened the single-photo receipt review action rail so the bottom controls
  are less likely to crowd the visible receipt preview.
- Shortened the compact rail labels from `Add Another Photo` to `Add Photo` and
  from `Save Space` to `Space`, while preserving tooltips that explain the full
  meaning for accessibility and clarity.
- Kept longer `Add Another Photo` language in multi-photo/long-receipt contexts
  where the extra words are useful and the layout is less cramped.
- Updated source guards from the old `Attach + Review` wording to the current
  `Next: Review Receipt Details`/`Next opens...` flow so tests protect the
  assisted-review path the user expects.
- Updated the help-flow guard to protect the Maintainiac native camera first,
  phone-camera backup fallback contract instead of the retired direct picker
  entry point.

Validation:
- `dart format test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reducing the review tray footprint
  and making the primary `Next` path harder to miss without hiding receipt
  content or damaging long-receipt controls.

### Receipt Camera Reopen Pass 802: Receipt-First Review Tray Height Batch

Status: complete.

What changed:
- Tightened the receipt-photo review bottom tray budget so the receipt preview
  owns more of the screen during review, crop, ordering, stitching, and saved
  proof-size preview.
- Updated the proportional caps from the older 16/15/12 percent budget to a
  stricter 14/13/10 percent budget, with absolute caps reduced for every mode.
- Reduced single-photo preview controls from 108px to 96px and multi-photo
  preview controls from 126px to 112px.
- Reduced deeper tool caps: crop 78px, order 94px, stitch 106px, and data saver
  118px.
- Updated guard tests so future UI work cannot casually grow the controls back
  over the receipt preview.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the post-capture review path
  clearer: accepted photos should always flow forward to receipt details, while
  add-photo/recover/leave actions remain explicit and hard to hit by accident.

### Receipt Camera Reopen Pass 803: Forward-Handoff Exit Copy Batch

Status: complete.

What changed:
- Reworded the receipt-photo review exit dialog away from the old attachment
  mental model.
- Changed the dialog titles to `Use this receipt photo before leaving?` and
  `Use these receipt photos before leaving?`.
- Clarified that saved local recovery photos are not deleted, but have not been
  read into the expense yet.
- Clarified that `Next: Review Receipt Details` opens the filled receipt
  details, while `Keep Photo(s) Saved For Later` keeps recoverable local copies
  without reading them into the expense.
- Updated guard tests and verified no stale `Attach + Review`, `Next attaches`,
  or attach-before-leaving copy remains in the checked receipt-capture paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt photo back protects captured images from silent discard"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening review recovery and
  post-capture progress states so a user always knows whether Maintainiac is
  preparing OCR, waiting for stitch confirmation, or ready to review details.

### Receipt Camera Reopen Pass 804: Saved-Proof Vocabulary Cleanup Batch

Status: complete.

What changed:
- Replaced confusing photo-review `backup image` wording with `saved proof`
  wording in the visible receipt-photo review flow.
- Updated the data-saving preview panel to say `Preparing Saved Proof Preview`,
  `Saved Proof`, and `saved proof image` while keeping the clear OCR source
  separate in the explanation.
- Updated the review context row to show `Saved proof: ... OCR uses the clear
  photo first`.
- Renamed the proof-size tool label from `Receipt Details And Backup Image` to
  `Receipt Details And Saved Proof`.
- Updated settings copy so users are told where to preview the saved proof size
  after taking a photo.
- Updated OCR/import fallback messages from `Receipt backup image saved` to
  `Receipt proof saved`.
- Renamed the smallest data-saving tier from `Tiny Backup` to `Tiny Proof` and
  rewrote proof-size descriptions to use `saved proof image`.
- Kept truly cloud-backup wording unchanged where it refers to cloud backup, not
  the local receipt proof image.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the proof-size/settings
  surface so the user can understand data saving choices without seeing
  developer-style compression language.
