# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 607: Executable Scanner-Decision OCR Risk Coverage Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 607: Executable Scanner-Decision OCR Risk Coverage Batch

Status: complete.

What changed:
- Extended the scanner preparation concern test so it proves a reviewed receipt
  result with quality-guard scanner decisions produces OCR-source attachment
  risk flags.
- Verified `scanner_decision_cleanup_skipped_quality_guard` stays as a document
  signal while `ocr_source_cleanup_skipped_quality_guard` and
  `ocr_source_ocr_source_original_selected_quality_guard` become OCR review
  risk flags.
- This gives executable coverage for the scanner-decision risk path instead of
  relying only on source-token guards.

Validation:
- `dart format test/receipt_camera_result_test.dart`
- `flutter analyze test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "scanner prep concerns"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 606: Duplicate Scanner-Decision OCR Risk Parity Batch

Status: complete.

What changed:
- Brought the duplicate/restored/imported receipt-photo OCR handoff path into
  parity with the main camera flow for scanner-decision risk flags.
- Scanner decisions containing `quality_guard`, `decode_failed`, or `skipped`
  now become `ocr_source_*` risk flags in
  `receipt_attachment_import_actions.dart`, matching `ReceiptCaptureFlow`.
- Extended the parity guard so future scanner-decision OCR risk handling must
  stay aligned across both receipt attachment paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "handoff helpers"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 605: OCR Handoff Helper Parity Guard Batch

Status: complete.

What changed:
- Added a regression guard that compares critical OCR-source handoff tokens
  across `ReceiptCaptureFlow` and `receipt_attachment_import_actions.dart`.
- Locked parity for proof data-saver signals, review-depth signals, native
  recovery signals, native UI-health signals, small proof-copy risk flags, and
  native UI risk classification.
- Kept the guard source-level because both helper implementations are private
  to their receipt capture paths.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "handoff helpers"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 604: Duplicate Native Recovery And UI-Health Parity Batch

Status: complete.

What changed:
- Added native recovery document signals to the duplicate
  `receipt_attachment_import_actions.dart` OCR-source helper.
- Added native camera UI-health document signals and risk flags to that same
  duplicate helper so incomplete/missing native controls are diagnosed the same
  way as the main `ReceiptCaptureFlow` path.
- Added source guards proving the duplicate import-action path emits native
  recovery, native UI-health, and native UI-risk evidence.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "reviewed receipt photos"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 603: Duplicate Import-Action OCR Handoff Parity Batch

Status: complete.

What changed:
- Brought the receipt attachment import-action OCR helper into parity with
  `ReceiptCaptureFlow` for proof data-saver document signals, native review
  depth signals, and small proof-copy OCR risk flags.
- Preserved the existing linked-module signal while adding the newer
  privacy-safe camera/OCR handoff evidence.
- Added layout guards proving the duplicate path continues to emit
  `proof_data_saver_*`, `receipt_review_depth_*`,
  `ocr_source_small_proof_copy_review_required`, and
  `ocr_source_proof_data_saver_*`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "reviewed receipt photos"`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/receipt_ocr_service_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 602: Small Proof-Copy OCR Warning Guidance Batch

Status: complete.

What changed:
- Added OCR review warning copy when a receipt photo is saved with a small
  proof/backup copy, so users are told to review the saved proof image before
  saving.
- Classified that small-proof warning as a photo-quality review warning instead
  of an unknown warning.
- Added OCR service coverage proving small-proof risk flags produce a user
  warning and remain visible in privacy-safe OCR handoff diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "proof copy"`
- `flutter test test/receipt_ocr_service_test.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 601: Small Proof-Copy OCR Review Risk Batch

Status: complete.

What changed:
- Added OCR-source risk flags when the selected proof/backup tier is
  `strong` or `maximum`, because those smaller proof copies require stricter
  human review even though OCR still reads the prepared source first.
- Added tier-specific risk evidence such as
  `ocr_source_proof_data_saver_strong`.
- Extended recovered long-receipt attachment coverage so small proof-copy risk
  flags travel with native recovery and proof data-saver signals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 600: OCR-Source Proof Data-Saver Signal Batch

Status: complete.

What changed:
- Added a `proof_data_saver_*` document signal to OCR-source receipt
  attachments so each prepared OCR source carries the selected proof/backup tier
  without exposing receipt content.
- Kept the existing `data_saver_*` signal for compatibility while making the
  saved-proof meaning explicit for downstream review and diagnostics.
- Added result coverage proving recovered native long-receipt OCR attachments
  include the proof data-saver signal alongside native recovery and review-depth
  signals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 599: Proof Data-Saver Handoff Metadata Batch

Status: complete.

What changed:
- Added the selected proof/backup data-saver level to
  `ReceiptPhotoReviewResult.privacySafeReceiptReaderHandoffMetadata`.
- Kept the metadata privacy-safe: it exposes only the selected backup tier name,
  not receipt image content, OCR text, merchant names, item descriptions, or
  prices.
- Extended receipt result coverage so the save-space tier survives the same
  handoff as native review depth and OCR-source preparation counts.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 598: Compact Recovery Add-Photo Clarity Batch

Status: complete.

What changed:
- Replaced the compact quality-recovery button label from "Add Section" to
  "Add Photo" so the action remains understandable in the tight bottom tray.
- Kept the longer primary action as "Add Receipt Photo" while using the shorter
  compact label only where button width is constrained.
- Added source guards proving the old compact `Add Section` label does not
  return to the live receipt review controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 597: Receipt-Photo Add Action Wording Batch

Status: complete.

What changed:
- Replaced the user-facing "Add Next Section" wording across the receipt
  camera/review/OCR path with "Add Receipt Photo" or "Add Next Receipt Photo"
  where the user is choosing another camera capture.
- Kept the internal long-receipt section model intact while making the visible
  action clearer for normal users after a single receipt photo.
- Updated partial-receipt confirmation, camera fallback errors, OCR guidance,
  help text, saved-photo warnings, and preview tray actions to use the same
  action name.
- Updated layout guards so future camera UI changes cannot silently bring back
  the old confusing wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 596: Native Review-Depth Handoff Batch

Status: complete.

What changed:
- Exposed native selected receipt review depth (`pricesOnly` / `detailedLines`)
  on `ReceiptPhotoReviewResult` as privacy-safe handoff metadata.
- Added a review-depth document signal to OCR source attachment records so
  downstream receipt review and diagnostics can tell whether the user chose
  prices-only or detailed lines.
- Kept the default safe: missing or invalid native depth falls back to
  `pricesOnly`.
- Added result tests proving detailed native review depth survives into
  metadata and OCR-source signals without exposing receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 595: iOS Native Settings Parity Batch

Status: complete.

What changed:
- Added AVFoundation receipt-camera settings actions for receipt review style:
  prices-only and detailed lines.
- Added AVFoundation receipt-camera settings actions for save-space proof size:
  local original, high quality, normal backup, low storage, and tiny backup.
- Fixed the iOS save-space label to read the user-facing `dataSaverLevel`
  instead of the device safety fallback field.
- Kept the iOS settings copy explicit that OCR still reads the original photo
  first and the save-space setting controls the proof/backup copy.
- Added iOS bridge guards proving these native settings controls are present and
  diagnostics still expose the selected review depth and data-saver level.

Validation:
- `dart format test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart test/receipt_native_android_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 594: Native Save-Space Choice Staging Handoff Batch

Status: complete.

What changed:
- Wired the native camera `dataSaverLevel` diagnostic back into
  `ReceiptCaptureFlow` staging so the user-facing save-space choice made inside
  the Android CameraX receipt camera can affect the staged receipt proof level.
- Kept the fallback order safe: known native data-saver level first, then the
  explicit flow option, then the stored receipt settings default, then balanced.
- Added a camera layout guard proving staging uses `_stagedDataSaverLevelFor`
  before `_staging.stage` and reads the native `dataSaverLevel` diagnostic.
- Preserved existing enum fallback behavior elsewhere instead of changing the
  global `ReceiptDataSaverLevel.fromName` contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 593: Android Native Settings Choice Controls Batch

Status: complete.

What changed:
- Made the Android CameraX receipt settings dialog scrollable so the full
  receipt-specific settings package remains reachable on smaller phones.
- Replaced summary-only native settings for receipt review depth and save-space
  proof size with actual adjustable controls.
- Corrected the native camera save-space label to read the user-facing
  `dataSaverLevel` instead of the device safety fallback field.
- Kept the OCR-first contract visible in the native settings: OCR reads the
  clear source first, and save-space proof size only changes the smaller backup
  copy.
- Added Android bridge guards proving the native camera remains a Maintainiac
  receipt camera surface with scrollable settings, review-depth choices, and
  save-space choices.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 592: Stale Read-Label Cleanup Batch

Status: complete.

What changed:
- Replaced the data-saver review chip labels `Read First` and `Save After`
  with clearer workflow labels: `Use Clear Photo` and `Save Small Copy`.
- Renamed the user-facing attachment read-state label from `Read into form` to
  `Ready for receipt review` while preserving the enum value for compatibility.
- Updated the receipt line guidance copy from "read lines" to "review lines" so
  the UI matches the app-assisted review flow instead of sounding like a hidden
  OCR command.
- Added source guards preventing the stale `Read First` and `Read into form`
  labels from returning to the receipt camera/review path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_recap.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_recap.dart test/receipt_camera_capture_layout_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 591: Review Action Language And Accessibility Clarity Batch

Status: complete.

What changed:
- Standardized the deeper review-tool add action to `Add Next Section` so the
  receipt flow no longer mixes generic photo language with long-receipt section
  language.
- Added tooltip and semantic labels to the primary and persistent review
  continue buttons so compact visible labels still expose the full action:
  Next: Review Receipt Details.
- Kept the visual tray footprint unchanged while improving screen-reader and
  pointer/hover clarity for the continuation path.
- Added source guards to prevent `Add Another Photo` from returning to the
  receipt review controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 590: Post-Capture Next-Step Affordance Clarity Batch

Status: complete.

What changed:
- Reworked the primary green review action label so the visible button reads as
  a clear two-line Next / Receipt Details action instead of relying on a long
  sentence that can truncate on-device.
- Applied the same label treatment to the persistent continue button in deeper
  review tools.
- Native saved-photo warning status text now still tells the user that Next
  opens receipt details when the photo is readable, so warning copy does not
  hide the continuation path.
- Preserved the compact bottom tray and did not increase the review control
  height caps.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 569: Review Exit And Long-Receipt Copy Batch

Status: complete.

What changed:
- Renamed the receipt photo review top-left action from "Back to receipt form"
  to "Leave receipt review" so the button no longer implies the captured photo
  has already been attached to the expense.
- Reworded the leave confirmation to explain the real choice: attach the
  captured photo and open filled receipt details, or leave it unattached while
  keeping the recoverable local copy.
- Changed the leave dialog primary action to "Attach + Review Details" and the
  secondary action to "Leave Unattached" so accidental exits do not silently
  discard the user's work.
- Standardized long-receipt helper language around "Add Next Section" and
  "Add Next Receipt Section" instead of mixing in "Add Another Photo".
- Kept OCR privacy language explicit: OCR uses the clear source photo first,
  while smaller saved proof images are for review/backup, and cloud OCR or
  inventory matching must be optional.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is accepted-photo continuity: prove that
  "Next" attaches reviewed photos, reads OCR source images before compressed
  backup copies, and opens the app-assisted filled receipt detail review instead
  of dropping the user back into the generic expense entry surface.
