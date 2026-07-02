# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 322 / Total Pass 402: Safe Review Exit Retention Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 322 / Total Pass 402: Safe Review Exit Retention Batch

Status: complete.

What changed:
- Audited the receipt photo review back/close path, including system back via
  `PopScope`, the top-bar back action, and the review exit dialog.
- Changed the post-capture exit action from destructive discard wording to a
  safe leave action: `Leave Photo Saved` / `Leave Photos Saved`.
- Updated the exit explanation so it tells the user the captured receipt
  sections stay recoverable and that Next goes to the receipt detail review.
- Removed abandoned-review cleanup from the safe leave path so accepted/native
  staged photos are not silently deleted if the user backs out of review.
- Kept generated edit preview cleanup in place so temporary crop/processing
  artifacts do not accumulate.
- Added/updated source guards proving the receipt review does not expose
  `Delete Staged Photo(s)` in the safe back path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_capture_staging_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_capture_staging_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue camera/OCR hardening by checking that saved review results clear only
  the accepted recovery manifest after the expense has the backup/OCR paths,
  while interrupted captures remain recoverable and route back into the filled
  receipt detail review instead of the ambiguous starting point.

### Receipt Camera Reopen Pass 323 / Total Pass 403: Accepted Recovery Clear Guard Batch

Status: complete.

What changed:
- Audited the native receipt capture acceptance path from shared
  `ReceiptCaptureFlow` into `SharedReceiptAttachmentPanel`.
- Added a mounted guard immediately after `_acceptReviewedPhotoResult(result)`
  so native recovery is not cleared if the attachment panel is gone before the
  accepted photo handoff finishes.
- Hardened `_clearAcceptedNativeRecovery` so it only clears a recovery manifest
  when the flow is accepted, the review result exists, saved proof photos exist,
  and OCR source photos exist.
- Kept interrupted/canceled review results recoverable; only a completed
  accepted handoff can clear the native recovery manifest.
- Updated source guards to prove recovery clearing happens after photo
  acceptance and requires both backup and OCR paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR hardening by verifying recovery resume returns to the same
  receipt photo review and then proceeds to the filled receipt detail review,
  with diagnostics that distinguish recovered, accepted, canceled, and missing
  photo outcomes without storing receipt content.

### Receipt Camera Reopen Pass 324 / Total Pass 404: Recovery Resume Outcome Diagnostics Batch

Status: complete.

What changed:
- Audited interrupted native receipt capture recovery from the attachment panel.
- Kept the recovery resume path scoped to existing saved photo paths and
  capture diagnostics, without storing private receipt text.
- Added a diagnostic event when recovered receipt photos are accepted and the
  recovery record is cleared:
  `recovery_review_accepted`.
- Added a diagnostic event when the user closes the recovered review without
  accepting it:
  `recovery_review_closed`.
- Added privacy-safe counts for accepted/kept recovered photo sections and
  whether the interrupted receipt had multiple sections.
- Preserved the existing missing-photo and user-discard diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR hardening by checking the native CameraX/AVFoundation
  capture diagnostics and review warning copy so dark/soft/glare/partial
  capture problems produce direct user actions and Command Center-safe health
  signals without exposing receipt content.

### Receipt Camera Reopen Pass 325 / Total Pass 405: OCR Native Warning Risk Flags Batch

Status: complete.

What changed:
- Audited OCR source attachment metadata for native camera quality warnings.
- Added native saved-photo warning risk flags to OCR source attachments in both
  the shared camera flow and the expense attachment panel flow.
- Added `ocr_source_<warning_code>` and
  `ocr_source_action_<warning_action>` flags so future Command Center health can
  separate dark, soft, glare, bottom-dark, and related capture problems.
- Added `ocr_source_native_critical_review` when native capture diagnostics say
  the saved photo is critical before OCR review.
- Handled stitched/long-receipt OCR by carrying warnings from all source
  sections into the single stitched OCR source when applicable.
- Kept the added signals privacy-safe: only quality/action codes are stored, not
  receipt text, vendor, totals, customer data, or line items.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR hardening by checking the post-capture review controls and
  action wording for long receipts: add-photo, stitch/match, crop, and Next must
  stay understandable while keeping the receipt image dominant on screen.

### Receipt Camera Reopen Pass 326 / Total Pass 406: Long Receipt Preview Action Rail Batch

Status: complete.

What changed:
- Audited the post-capture receipt photo review tray for multi-photo/long
  receipt discoverability.
- Replaced the multi-photo section header with a compact horizontal action rail.
- Added direct preview actions for `Add Next Section`, `Photo Order`,
  `Match Photos`, and `Crop Current`, so users do not have to guess from a
  menu or thumbnail-only strip.
- Reduced multi-photo thumbnail height in preview mode so the bottom tray stays
  compact and the receipt image remains dominant.
- Preserved the existing capped review tray behavior and explicit
  business/personal receipt-details handoff language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR hardening by checking crop/review lifecycle behavior and
  generated-edit cleanup so crop, rotate, retake, add-photo, and Next do not
  lose the accepted source or leave stale temporary files.

### Receipt Camera Reopen Pass 327 / Total Pass 407: Generated Edit Cleanup Guard Batch

Status: complete.

What changed:
- Audited crop, rotate, retake, remove, and generated edit cleanup in receipt
  photo review.
- Kept original/native staged receipt photos protected; the pass only targets
  app-created edit artifacts.
- Hardened `_replaceCurrentPhotoPath` so when a generated crop/rotate file is
  replaced by another generated edit, the older generated file is cleaned
  immediately instead of waiting until screen disposal.
- Preserved data-saver preview cleanup for stale preview files tied to the
  replaced path.
- Added a regression guard proving replaced generated edits are cleaned while
  retained current photo paths are kept.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR hardening by checking the native camera configuration
  layer and device capability policy: CameraX/AVFoundation settings should map
  user-facing receipt settings into device-safe focus, exposure, zoom, quality,
  long-receipt, and guidance behavior.

### Receipt Camera Reopen Pass 328 / Total Pass 408: Long Receipt Policy Gate Batch

Status: complete.

What changed:
- Audited the native camera settings/session policy that maps receipt settings
  into CameraX/AVFoundation session arguments.
- Fixed a long-receipt policy gap: when `longReceiptMode` is disabled, the
  native session now caps `maxSectionCount` at `1`.
- Added `long_receipt_mode_disabled` to capability policy codes so diagnostics
  explain why multi-section capture and ghost guides are disabled.
- Verified previous-section ghost guide paths are not sent when long receipt
  mode is disabled, even if a guide path is available.
- Added a method-channel test proving native capture receives
  `longReceiptMode: false`, `maxSectionCount: 1`, no previous guide path, and
  the matching policy code.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR hardening by checking native Android/iOS bridge parity for
  the session arguments: both sides should consume the same settings for
  long-receipt limits, exposure, zoom, focus, warnings, cleanup, and safe close
  behavior.

### Receipt Camera Reopen Pass 329 / Total Pass 409: Native Long Receipt Toggle Gate Batch

Status: complete.

What changed:
- Audited Android CameraX and iOS AVFoundation receipt camera bridge handling
  for `longReceiptMode` and `maxSectionCount`.
- Fixed a native settings mismatch: when the Flutter session policy caps a
  capture session to one receipt photo, native settings can no longer toggle
  long receipt mode back on.
- Added Android and iOS startup guards so `maxSectionCount <= 1` forces
  `longReceiptMode = false` before the user sees the camera UI.
- Added Android and iOS settings-action guards with clear user-facing copy:
  `Long receipt mode is unavailable for this device or storage setting.`
- Added source-level bridge tests to keep both native camera backends aligned
  with the session policy.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`

Next camera/OCR focus:
- Continue native bridge parity checks for exposure, focus, zoom, warnings,
  cleanup, and safe-close diagnostics so CameraX and AVFoundation consume the
  same receipt-camera control package.

### Receipt Camera Reopen Pass 330 / Total Pass 410: Native Control Bounds Parity Batch

Status: complete.

What changed:
- Audited Android CameraX and iOS AVFoundation control handling for tap focus,
  pinch zoom, brightness/exposure slider, exposure reset, live exposure assist,
  and pre-capture exposure assist.
- Fixed a bridge parity gap where the Flutter session contract sent safe
  `minZoom`, `maxZoom`, `minExposureOffset`, and `maxExposureOffset` limits,
  but native controls could still use wider device-level ranges.
- Android now clamps pinch zoom to effective session zoom bounds and clamps
  manual, reset, live-assist, and pre-capture exposure changes to an effective
  session exposure range.
- iOS now clamps pinch zoom, manual brightness, brightness reset, live-assist,
  and pre-capture exposure changes to the same session-safe policy envelope.
- Added bridge tests proving both native backends contain the bound helpers and
  session-control enforcement points.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`
- Attempted `./gradlew :app:compileDebugKotlin` from `android/`; blocked by
  missing Java runtime in the current Mac session.

Next camera/OCR focus:
- Continue camera/OCR hardening by checking native compile readiness once Java
  is available, then proceed to native warning/cleanup parity and OCR handoff
  behavior.

### Receipt Camera Reopen Pass 331 / Total Pass 411: Native Control Bounds Sanity Batch

Status: complete.

What changed:
- Rechecked the exact Android CameraX and iOS AVFoundation source sections
  edited in Pass 410 after native compile could not run without Java.
- Confirmed the Android exposure flow structure around manual slider, reset,
  live exposure assist, and pre-capture exposure assist.
- Hardened Android brightness reset to match the iOS behavior: reset now clamps
  to the safe session-neutral exposure value instead of doing nothing when `0`
  is outside the effective session range.
- Hardened Android exposure slider initialization to clamp the current camera
  exposure index before mapping it to slider progress.
- Added bridge-test coverage for the Android `clampExposureIndex` helper.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`

Native compile note:
- Android Kotlin compile is still unverified in this session because
  `./gradlew :app:compileDebugKotlin` is blocked by a missing Java runtime.

Next camera/OCR focus:
- Continue with native warning/cleanup parity and OCR handoff behavior while
  keeping the camera/OCR scope isolated from broader expenses, inventory, and
  PDF work.

### Receipt Camera Reopen Pass 332 / Total Pass 412: Native Warning Toggle Parity Batch

Status: complete.

What changed:
- Audited native warning settings parity for Android CameraX and iOS
  AVFoundation.
- Fixed a settings bug where the user-facing `Receipt guidance warnings`
  toggle did not cover the full warning package.
- Android and iOS now include `shadowWarningEnabled` and
  `textTooSmallWarningEnabled` when deciding whether receipt guidance warnings
  are on.
- Android and iOS now turn shadow warnings and small-text warnings on/off from
  the same receipt guidance warning setting instead of leaving those warnings
  active after the user disables guidance warnings.
- Added focused bridge-test guards for both platforms.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`

Next camera/OCR focus:
- Continue with OCR handoff behavior: accepted original photos should remain
  the first OCR source, backup/data-saver proofs should stay separate, and
  native capture diagnostics should remain privacy-safe.

### Receipt Camera Reopen Pass 333 / Total Pass 413: Stitched OCR Diagnostics Handoff Batch

Status: complete.

What changed:
- Audited the native capture staging, review-save, OCR attachment, and shared
  capture-flow handoff path.
- Confirmed native receipt photos are copied into app staging first, then the
  review flow creates separate OCR source artifacts and saved proof copies.
- Fixed a stitched-OCR diagnostics gap: when multiple prepared receipt sections
  become one stitched OCR source, the final stitched path now receives
  aggregated preparation diagnostics.
- The stitched OCR source now preserves scanner decision codes from the
  prepared section sources and adds `ocr_source_stitched_selected`.
- Added stitch metadata to the final OCR source diagnostics:
  `stitchedOcrSource`, `stitchedInputCount`, `stitchedConfidence`,
  `stitchedOverlapPixels`, and `sourceOcrPaths`.
- Updated stale source-contract expectations to the current safe retention
  behavior: leaving review keeps staged native photos recoverable and only
  cleans generated edit artifacts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`

Next camera/OCR focus:
- Continue with OCR result handoff and review-screen behavior: the screen after
  accepting receipt photos must show what OCR/parse found, with business,
  personal, and mixed classification ready for the user.

### Receipt Camera Reopen Pass 334 / Total Pass 414: Accepted Photo Review Destination Batch

Status: complete.

What changed:
- Audited the accepted receipt-photo path from native capture review through
  OCR source handoff, parser entry, and expense receipt review rendering.
- Fixed a UI state gap where the app-assisted receipt review section did not
  exist until OCR/parser data arrived. That allowed accepted camera photos to
  visually fall back to the generic receipt attachment area while reading was
  still in progress.
- Added `_receiptReviewFlowStarted` so accepting receipt photos, starting OCR,
  loading imported text, restoring drafts, or applying parsed receipt data all
  create the filled-review destination immediately.
- Changed accepted-photo and read-start scrolling to target the receipt review
  destination instead of the attachment handoff block.
- Removed the now-unused `_scrollToReceiptReadHandoff` helper.
- Updated source-contract coverage so the camera path stays pointed at the
  filled receipt review flow after the user accepts receipt photos.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue hardening the native receipt camera/OCR flow around quality scoring,
  post-capture review clarity, and OCR confidence handoff. Keep PDF, inventory,
  and broad Firebase work out of scope until the camera/OCR lane is solid.

### Receipt Camera Reopen Pass 335 / Total Pass 415: Readable Receipt Quality Gate Batch

Status: complete.

What changed:
- Audited receipt photo quality scoring after the accepted-photo review handoff.
- Found the scoring floor already protects `isLikelyReadable` photos, but the
  image processor was strict enough that one weak heuristic could mark a real
  readable receipt as not likely readable.
- Added a safer `borderlineReadable` path in `ReceiptImageProcessor`:
  sufficient resolution, usable light, usable focus, and usable contrast can
  accept strong text evidence, strong receipt-shape evidence, or acceptable
  crop with partial text-band evidence.
- Kept hard retake blockers intact for truly dark, glare-heavy, very soft, low
  resolution, or weak/no-text photos.
- Added test coverage so a readable receipt with one weak heuristic can still
  continue to the filled receipt review, while a truly weak photo remains a
  retake risk.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_image_processor.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_image_processor.dart test/receipt_camera_quality_guidance_test.dart`

Next camera/OCR focus:
- Continue with post-capture review clarity: controls should make the next
  action obvious, preserve accepted photos from accidental loss, and keep the
  receipt image visible while still exposing add-photo/long-receipt actions.

### Receipt Camera Reopen Pass 336 / Total Pass 416: Single Photo Review Copy Batch

Status: complete.

What changed:
- Audited the post-capture review controls for the single-photo case.
- Clarified the primary button from `Next: Review` to
  `Next: Review Details` so the user knows it continues into the receipt detail
  review, not back to the attachment button.
- Changed single-photo status copy to lead with `Photo captured` and explain
  that Next opens item prices and business/personal use.
- Changed the single-photo secondary tray copy so `Add another photo` is framed
  as only needed when the receipt continues.
- Kept multi-photo/stitch copy intact, including `Next: Review opens item
  prices and business/personal use`.
- Added layout-source coverage for the clearer single-photo wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_photo_section_labels_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue with accepted-photo safety and review UX: accidental back/close
  should not silently discard captured receipt photos, and the review screen
  should keep the receipt image usable for zoom/crop/order checks.
