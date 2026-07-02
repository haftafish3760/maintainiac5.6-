# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Pass 684: Manual Shutter Policy Diagnostics Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Pass 684: Manual Shutter Policy Diagnostics Batch

Status: complete.

What changed:
- Added a shared `manualCapturePolicy` diagnostic:
  `guidance_advisory_manual_shutter_always_allowed`.
- Sent that policy from the Flutter native-camera service into each native
  camera session.
- Returned that policy from both CameraX and AVFoundation capture diagnostics
  with every saved photo.
- Added the key to the privacy-safe native recovery diagnostic allow-list so
  interrupted receipt captures keep the same proof without storing receipt
  text or customer content.
- Strengthened service, Android bridge, iOS bridge, and recovery staging tests
  around the manual-capture guarantee.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is camera-preview brightness and
  exposure evidence: keep native preview readable, avoid heavy dimming, and
  expose enough diagnostics to explain dark/bright capture mismatches.

### Receipt Camera Pass 685: Lighter Live Preview Overlay Batch

Status: complete.

What changed:
- Reduced the Flutter receipt camera shell's bottom gradient opacity so the
  live camera view is less dark behind the shutter controls.
- Reduced the guidance panel opacity so it still reads clearly without making
  the camera preview look artificially dim.
- Lightened the full-screen vignette from the previous darker values to keep
  the receipt preview closer to the native camera brightness.
- Updated the layout guard so the older darker overlay values cannot silently
  return.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native exposure diagnostics parity:
  make sure Android and iOS both explain live brightness versus captured
  brightness so dark-bottom or dim-capture complaints are actionable.

### Receipt Camera Pass 686: Native Captured Lighting Evidence Parity Batch

Status: complete.

What changed:
- Added `capturedLightingEvidence` on Android CameraX and iOS AVFoundation
  capture diagnostics.
- Normalized lighting evidence into simple buckets:
  `capture_too_dark`, `capture_dim_review_needed`, `bottom_lighting_risk`,
  `capture_glare_risk`, `lighting_readable`, and `unknown`.
- Fed the same key into the shared receipt capture model so fallback camera
  result metadata has the same diagnostic shape.
- Taught saved-photo warning logic to use the summary key before falling back
  to lower-level brightness, vertical-quality, and exposure-mismatch fields.
- Added the key to privacy-safe recovery diagnostics so interrupted native
  captures keep actionable lighting evidence without storing receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is post-capture quality decisions:
  make dim, glare, bottom-dark, and blur warnings drive clearer retake/add-photo
  choices without blocking a readable receipt.

### Receipt Camera Pass 663: Native Preview Lifecycle Guard Batch

Status: complete.

What changed:
- Hardened Android CameraX callback flow so provider startup, live analysis,
  exposure-prep listeners, and capture callbacks stop touching camera UI after
  the Activity is finishing, destroyed, or has already delivered a result.
- Hardened iOS AVFoundation callback flow so session startup, setup callbacks,
  photo callbacks, and sample-buffer analysis stop updating overlays/labels once
  the camera view is closing or dismissed.
- Added iOS delegate cleanup on deinit so live analysis cannot keep delivering
  frames into a dead view controller.
- Added regression coverage for the Android and iOS lifecycle gates.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart`
- `git diff --check`
- `flutter build apk --debug`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the remaining photo review workflow:
  accepted photo must flow into filled receipt detail review, while add-photo,
  crop, stitch, and data-saver controls stay visible without covering the
  receipt.

### Receipt Camera Pass 664: Photo Review Tray Overflow Fix

Status: complete.

What changed:
- Fixed the single-photo receipt review tray cap that was too short for the
  primary Next row plus the add/retake/crop/save-space action row.
- Raised preview mode from the old undersized 82px single-photo cap to 108px
  and raised multi-photo preview to 126px, while keeping the receipt image as
  the dominant part of the screen.
- Updated layout regression coverage so the broken cap does not come back.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review bottom controls stay capped by mode"`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the post-photo review actions
  and filled-detail handoff impossible to misunderstand while keeping crop,
  stitch, and data-saver controls out of the receipt image.

### Receipt Camera Pass 665: Live Exposure Dimming Restraint Batch

Status: complete.

What changed:
- Reduced live auto-exposure dimming on Android CameraX so Maintainiac no
  longer starts dimming at ordinary bright-receipt levels.
- Reduced live auto-exposure dimming on iOS AVFoundation with the same policy.
- Dimming now waits for severe over-bright/glare readings and one extra stable
  frame before touching exposure, leaving native auto exposure alone more often.
- Kept brightening assistance for genuinely dark receipts.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check`
- `flutter build apk --debug`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the post-photo review action clarity
  and filled-detail handoff.

### Receipt Camera Pass 666: Native Bottom Review Button Batch

Status: complete.

What changed:
- Added an always-visible bottom Review Photo button to the Android CameraX
  capture screen. It enables after the first captured receipt section.
- Added the matching bottom Review Photo button to the iOS AVFoundation capture
  screen.
- Kept the top Review Photo button for long-receipt mode, but no longer makes
  the user rely on discovering a top-bar button after capture.
- Added bridge coverage so both native camera implementations keep the bottom
  review affordance wired to the captured-photo review flow.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check`
- `flutter build apk --debug`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making review/crop/stitch/data-saver
  choices clearer after the native camera returns photos.

### Receipt Camera Pass 667: Post-Photo Review Wording Clarity Batch

Status: complete.

What changed:
- Tightened the single-photo review message so it plainly says Next opens the
  filled receipt review and Add Receipt Photo is only for receipts that continue.
- Tightened the multi-photo message so it says receipt sections are ready and
  Next opens item prices, totals, and business/personal use.
- Reworded the exit dialog away from "reading" language to "Leave Without
  Attaching" so users understand the photo is not attached to the expense yet.
- Updated the camera help flow guard tests to protect the current capped
  review tray height and clearer post-photo labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is rechecking the receipt result caller
  so accepted photos route into the filled receipt review instead of feeling
  like they returned to the blank receipt entry surface.

### Receipt Camera Pass 668: Filled Receipt Review Handoff Copy Batch

Status: complete.

What changed:
- Rechecked the accepted-photo caller path: receipt review acceptance already
  marks the flow started, records proof/OCR-source counts, applies parsed
  receipt fields, and scrolls to the assisted receipt review section.
- Reworded the in-between state from "Reading receipt" / "Waiting For Receipt
  Reader" to "Preparing Filled Receipt Review" so the user sees a clear next
  screen target after accepting photos.
- Reworded the handoff panel metric from "Receipt Reader" to "Clear OCR Source"
  and kept OCR-source-before-backup behavior visible without making the flow
  sound like a separate dead-end screen.
- Updated assisted-flow guard coverage for the clearer handoff language.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing the native-camera UI
  surface for any remaining stock-camera fallback confusion and making sure
  fallback messaging clearly says it is a backup, not the primary Maintainiac
  receipt camera.

### Receipt Camera Pass 669: Phone-Camera Backup Clarity Batch

Status: complete.

What changed:
- Added a visible "Phone camera backup" prefix in the receipt photo review tray
  when the stock phone camera fallback path is used.
- Added privacy-safe fallback diagnostics for phone-camera backup captures so
  Command One and tests can distinguish fallback capture from the primary
  Maintainiac native receipt camera.
- Kept the primary flow native-first; the backup path remains only for native
  camera unavailable/backup capture cases.
- Added focused guard coverage for the backup label and native-before-fallback
  ordering.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "review add-photo flow also uses native capture before fallback"`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is full camera-flow regression across
  native bridge guards, review tray layout, and filled-review handoff after the
  recent wording/routing batches.

### Receipt Camera Reopen Pass 659: Native Pre-Capture Exposure Safety Batch

Status: complete.

What changed:
- Tightened Android CameraX pre-capture exposure prep so Maintainiac no longer
  dims bright-but-readable receipt scenes immediately before saving the photo.
- Tightened iOS AVFoundation pre-capture exposure prep the same way, keeping
  native auto exposure as the baseline unless the scene is genuinely dark.
- Kept live brightness assist available, but changed the last-second capture
  behavior to rescue only very dark scenes instead of fighting the phone's
  native exposure system.
- Added `lastPreCaptureExposureSkipReason` diagnostics on Android, iOS, and the
  privacy-safe native capture staging allow-list so Command One/expense health
  can explain whether native auto exposure was intentionally kept.
- Added bridge guards proving the dimming thresholds are no longer part of the
  pre-capture path and that the new skip reason is exported.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is capture-review navigation and
  persistence: make the accepted photo path impossible to lose accidentally and
  keep the next step aimed at parsed receipt review instead of a blank expense
  form.

### Receipt Camera Reopen Pass 660: Receipt Review Exit Safety Copy Batch

Status: complete.

What changed:
- Tightened the post-capture review exit dialog so the risky path now says
  `Leave Without Reading` instead of the softer `Leave Unattached`.
- Changed the primary review-exit action to `Next: Attach + Review Details` so
  it reads like the same forward workflow as the persistent Next button.
- Updated the explanatory copy to say plainly that leaving keeps recoverable
  local photos on the phone, but Maintainiac will not read or attach them to
  the expense yet.
- Kept the actual safety behavior intact: staged/native photos are not silently
  deleted when the user backs out, and the safe action still runs the normal
  accepted-photo preparation/OCR handoff.
- Added regression coverage for the safer labels and removed the old
  `Leave Unattached` wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-state persistence cues:
  surface that photos are already recoverable before they are attached, then
  keep the handoff flowing into filled receipt review.

### Receipt Camera Reopen Pass 661: Local Recovery Preview Cue Batch

Status: complete.

What changed:
- Added a compact `Saved locally for recovery.` cue to the receipt photo
  preview tray whenever capture diagnostics prove the image came through the
  Maintainiac/native receipt camera or native recovery staging.
- Kept the cue inside the existing compact tray instead of adding another panel,
  preserving the receipt-first 75-80% preview goal.
- Applied the cue across normal, warning, possible-continuation, and
  multi-photo status text so users know the image exists locally before they
  tap Next.
- Guarded the detection using privacy-safe diagnostics such as native capture
  surface, capture flow, and recovery freshness, without reading or displaying
  receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is OCR handoff evidence: make the
  accepted-photo result and expense receipt handoff show that OCR uses the
  original/clean source before storage-saving backup copies.

### Receipt Camera Reopen Pass 662: OCR Source-First Handoff Batch

Status: complete.

What changed:
- Added `ocr_source_first=true` to the privacy-safe OCR handoff evidence label
  so telemetry can prove OCR source handling without exposing receipt content.
- Added `ocrSourceFirstPolicy: ocr_reads_clear_source_before_backup` to the
  receipt-reader handoff metadata.
- Updated the filled receipt handoff panel to say Maintainiac reads the clear
  OCR source before the storage-saving proof copy.
- Updated the in-progress reading copy to explain the same source-first rule
  while the receipt reader is working.
- Added/updated tests for result metadata, capture layout guards, and the
  assisted receipt review panel copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native/manual shutter reliability:
  inspect the back/close path and camera lifecycle guards for the disposed
  preview crash reported on-device.

### Receipt Camera Reopen Pass 652: Native Review/Back Label Contract Batch

Status: complete.

What changed:
- Renamed the native long-receipt completion control from generic "Use Photo"
  language to "Review Photo/Review Photos" on both Android CameraX and iOS
  AVFoundation so the button matches the Maintainiac flow.
- Changed the in-flight back/close message to say the app is saving the receipt
  photo before opening review, instead of sounding like the photo is being
  discarded or the camera is simply closing.
- Kept captured-photo back behavior wired to return captured sections for
  review with `back_returned_captured_sections`, while empty back still cancels
  without pretending a receipt was captured.
- Reworded the empty review fallback button from "Back To Receipt Form" to
  "Return To Receipt Entry" so the UI does not imply the accepted-photo path
  should drop the user back into a blank form.
- Added guard coverage for the Android and iOS native camera strings, the
  captured-photo back ordering, and the absence of the old confusing labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening post-capture review
  layout recovery and the accepted-photo handoff so the user sees the filled
  receipt details path after OCR/parsing instead of a blank expense-entry loop.

### Receipt Camera Reopen Pass 653: Filled Review Handoff Stage Batch

Status: complete.

What changed:
- Changed the expense receipt handoff stage shown immediately after accepting
  receipt photos from "Preparing saved receipt photo" to "Opening filled
  receipt review."
- Kept the accepted-photo sequence explicit: accept reviewed photo, show the
  filled-review handoff state, read OCR source photos, parse into the receipt
  detail review, then mark the photos read/unreadable.
- Added regression guards so the old proof-storage wording does not return in
  the camera help, shareability, or assisted receipt review tests.
- Reconfirmed that accepted camera photos start the receipt review panel before
  OCR work finishes, so the user is not dumped back into the blank receipt
  entry loop.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_capture_flow_shareability_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the receipt review preview
  action tray and long-receipt add-photo prompts so the controls stay obvious
  without covering the receipt.
