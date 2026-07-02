# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 770: Review Crop And Proof Control Split Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 770: Review Crop And Proof Control Split Batch

Status: complete.

What changed:
- Split crop/edit controls and data-saver proof controls out of the large
  post-capture review controls file into
  `receipt_photo_review_crop_and_proof_controls.dart` as a `part` file.
- Reduced `receipt_photo_review_controls.dart` from 3033 lines to 2708 lines;
  the new crop/proof controls part is 326 lines.
- Preserved existing review behavior: crop apply/cancel/reset, rotate/straighten,
  data-saver proof-size choices, and OCR-before-compressed-proof copy still run
  through the same review screen API.
- Updated the focused source guards so crop controls, proof copy, lighter camera
  vignette, and guidance overlay checks follow the new split files.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another safe post-capture review split
  or behavior hardening, whichever removes the most risk without changing the
  receipt photo workflow.

### Receipt Camera Reopen Pass 771: Review Stitch Control Split Batch

Status: complete.

What changed:
- Split manual long-receipt stitch controls, stitch readiness, stitch evidence
  chips, and match-recovery pills into
  `receipt_photo_review_stitch_controls.dart` as a `part` file.
- Reduced `receipt_photo_review_controls.dart` from 2708 lines to 2169 lines;
  the new stitch controls part is 540 lines.
- Preserved existing long-receipt behavior: pair selection, manual overlap
  slider, automatic-match copy, combined-receipt readiness, safe fallback
  readiness, and photo-order recovery actions remain wired through the same
  review screen API.
- Updated focused source guards so order controls remain checked in the general
  review controls file while stitch and match evidence checks follow the new
  stitch part.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another safe post-capture review split
  or behavior hardening around the review controls that remain in the 2169-line
  file.

### Receipt Camera Reopen Pass 772: Review Order Control Split Batch

Status: complete.

What changed:
- Split photo-order controls and order thumbnails into
  `receipt_photo_review_order_controls.dart` as a `part` file.
- Reduced `receipt_photo_review_controls.dart` from 2169 lines to 1883 lines;
  the new order controls part is 287 lines.
- Preserved existing long-receipt ordering behavior: top-to-bottom order
  guidance, earlier/later movement, add-next-photo, retake-in-place, and cached
  thumbnail rendering remain wired through the same review screen API.
- Updated focused source guards so order/thumbnail checks follow the new part
  while the general controls file still owns mode routing and review context.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another safe split from the remaining
  review controls or behavior hardening around preview/context actions.

### Receipt Camera Reopen Pass 773: Review Proof Lane Consolidation Batch

Status: complete.

What changed:
- Moved the OCR proof lane card and proof lane chips into the existing
  `receipt_photo_review_crop_and_proof_controls.dart` part file.
- Reduced `receipt_photo_review_controls.dart` from 1883 lines to 1727 lines;
  the crop/proof part now owns crop actions, data-saver proof controls, and the
  OCR-clear-source-versus-small-backup explanation.
- Preserved the receipt review behavior: the data-saver mode still shows
  `Receipt Details And Backup Image`, `Use Clear Photo`, `Save Small Copy`, and
  the reminder that OCR uses the clear photo before compressed proof storage.
- Updated focused source guards so proof-lane checks follow the crop/proof part.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another safe review-controls split or
  behavior hardening around preview action rows and recovery strips.

### Receipt Camera Reopen Pass 774: Review Context Control Split Batch

Status: complete.

What changed:
- Split the review context/status row and its compact add/retake/remove
  controls into `receipt_photo_review_context_controls.dart` as a `part` file.
- Reduced `receipt_photo_review_controls.dart` from 1727 lines to 1521 lines;
  the new context controls part is 207 lines.
- Preserved existing behavior: status copy, selected-section guidance,
  single-photo captured copy, Add Another Photo, Retake, Remove, and compact
  icon button sizing stay wired through the same review screen API.
- Updated focused source guards so context-row copy and compact icon sizing
  follow the new context part.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another safe review-controls split or
  behavior hardening around preview action rows/recovery strips.

### Receipt Camera Reopen Pass 775: Review Preview Control Split Batch

Status: complete.

What changed:
- Split the preview/recovery control family into
  `receipt_photo_review_preview_controls.dart` as a `part` file.
- Reduced `receipt_photo_review_controls.dart` from 1521 lines to 1004 lines;
  the new preview controls part is 518 lines.
- Preserved behavior: preview primary row, multi-photo rail, section position
  chip, single-photo row, photo count badge, native saved-photo warning model,
  recovery strip/buttons, and action rail buttons stay wired through the same
  review screen API.
- Updated focused source guards so preview/recovery classes and warning-button
  copy follow the new preview part while status copy remains in the main
  controls wrapper.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is another safe split from the remaining
  review controls or behavior hardening around preview action rows/recovery
  strips.

### Receipt Camera Reopen Pass 776: Review Mode Control Split Batch

Status: complete.

What changed:
- Split the review mode strip, step buttons, and mode header into
  `receipt_photo_review_mode_controls.dart` as a `part` file.
- Reduced `receipt_photo_review_controls.dart` from 1004 lines to 809 lines;
  the new mode controls part is 196 lines.
- Preserved behavior: Review, Crop, Photo Order, Match Photos, Proof Size,
  mode-specific header copy, and the back-to-preview action stay wired through
  the same bottom-controls coordinator.
- Updated focused source guards so mode/header copy follows the mode-controls
  part while the coordinator still owns continuation, status, and tray wiring.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is either extracting continuation/status
  micro-controls from the remaining review controls or tightening preview action
  recovery behavior without changing the camera backend.

### Receipt Camera Reopen Pass 777: Review Common Control Split Batch

Status: complete.

What changed:
- Split shared review-control atoms into
  `receipt_photo_review_common_controls.dart` as a `part` file.
- Reduced `receipt_photo_review_controls.dart` from 809 lines to 599 lines;
  the new common controls part is 211 lines.
- Preserved behavior: persistent Next button, `Next: Attach + Review Details`
  stacked label, `Next Anyway`, `Check Photo Match`, local-photo-limit warning,
  and shared action rail button styling remain wired through the same review
  coordinator and preview tray.
- Updated focused source guards so common control copy and sizing follow the new
  common part while the coordinator still owns review-mode routing and status
  decision copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the remaining review coordinator:
  either isolate preview status decision copy or harden the native preview/review
  recovery path without touching Firebase, PDF, or inventory.

### Receipt Camera Reopen Pass 778: Native Camera Backup Policy Diagnostics Batch

Status: complete.

What changed:
- Added explicit native camera diagnostics that separate the app-owned
  Maintainiac camera surface from the phone-camera backup path.
- The native contract now states that stock camera UI is not allowed as the
  primary Maintainiac receipt camera, while the phone camera backup remains
  allowed and labeled as `fallback_only`.
- Strengthened source guards so add-photo review flow continues to try the
  Maintainiac native camera first, labels phone-camera backup captures, and
  exposes the backup policy in privacy-safe diagnostics.
- Preserved the user-safety behavior: if the native receipt camera is
  unavailable, the backup path still lets the user capture a receipt instead of
  being stranded.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening manual-capture advisory
  behavior and preview/review recovery so warnings never strand the user when
  OCR can still read the receipt.

### Receipt Camera Reopen Pass 779: Advisory Quality Warning Copy Batch

Status: complete.

What changed:
- Changed critical photo-quality action copy from hard-block language to
  advisory language: `Retake recommended; Next still works`.
- Updated the review-score meaning for retake-risk photos so it says retake is
  safer while still making clear that Next remains available if the receipt text
  is readable.
- Aligned saved-photo bottom-section warning tests with the current
  user-facing `Add Another Photo` long-receipt language.
- Preserved the professional scanner behavior: quality guidance can recommend a
  retake, but it does not trap the user when the receipt is still readable.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native shell responsiveness and
  preview/review recovery behavior, especially ensuring add-photo, back, and
  settings interactions stay obvious and non-blocking.

### Receipt Camera Reopen Pass 780: Native Recovery Index Cleanup Batch

Status: complete.

What changed:
- Added age-based cleanup for Hive-only native receipt capture recovery index
  entries so interrupted receipt sessions cannot accumulate forever on a phone.
- Kept retained active review paths safe: old Hive-only recovery entries are not
  deleted when their staged photo is currently retained by an active review.
- Wired `cleanOldAbandonedNativeStaging` to clean both unrecoverable Hive
  entries and old recoverable entries using the same retention window as staged
  files/manifests.
- Added regression coverage for both sides of the edge case: old Hive-only
  recovery is removed when the staged photo is gone, and preserved when the
  staged photo is explicitly retained.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is preview/review responsiveness and
  recovery clarity: add-photo/back/settings must remain obvious, quick, and
  non-blocking even when capture/review work is interrupted.

### Receipt Camera Pass 755: Device Workload Protection Evidence Batch

Status: complete.

What changed:
- Added a privacy-safe `workloadProtectionPolicy` summary to the native receipt
  camera session contract.
- Passed that policy from Dart into Android CameraX and iOS AVFoundation native
  receipt camera surfaces.
- Echoed the policy back in native capture diagnostics so Command One and test
  fixtures can tell whether a capture used balanced, flagship, older-phone, or
  storage-saver workload protection.
- Added focused coverage for older-phone/storage-saver behavior, maximum
  data-saver behavior, balanced service arguments, and Android/iOS bridge parity.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using the new workload-protection
  evidence in receipt capture/result health summaries so older-phone and
  storage-saver captures are clearly visible without exposing receipt content.

### Receipt Camera Pass 756: Workload Protection Result Summary Batch

Status: complete.

What changed:
- Updated receipt photo review result summaries to read the explicit
  `workloadProtectionPolicy` emitted by the native camera.
- Added privacy-safe result buckets for `flagship_native` and
  `balanced_native`, while preserving existing storage-saver, older-phone,
  recovery, and backup-camera policy buckets.
- Strengthened the result-model test so workload protection can be surfaced in
  review handoff metadata without exposing merchant, total, or receipt text.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding workload-protection policy
  counts into the expense camera health telemetry path so Command One can show
  whether failures are happening mostly on storage-saver, older-phone, balanced,
  flagship, recovery, or backup-camera capture paths.

### Receipt Camera Pass 757: Command One Workload Policy Telemetry Batch

Status: complete.

What changed:
- Added `nativeCaptureSourcePolicyCounts` and
  `topNativeCaptureSourcePolicy` to expense camera health telemetry snapshots.
- Carried the new workload/source policy counts from OCR-start metadata into
  the local expense telemetry rollup.
- Added the new policy fields to the privacy-safe telemetry sanitizer,
  Firestore Command One allowlist, and schema expectation helper.
- Updated expense telemetry and Firestore tests so Command One can see whether
  receipt camera failures skew toward storage-saver, older-phone, balanced,
  flagship, recovery, or backup-camera paths without seeing receipt content.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening user-visible receipt
  capture flow copy around Native/backup camera paths so the buttons and status
  text say what happens next without exposing internal implementation names.

### Receipt Camera Pass 758: Receipt Handoff Copy Guard Batch

Status: complete.

What changed:
- Updated the receipt camera layout/copy guard test to match the current
  `Next accepted` filled-review workflow.
- Added regression guards that the reviewed-photo handoff path does not bring
  back `Read receipt` or user-facing `Evidence:` copy.
- Corrected stale helper-scope expectations so the privacy-safe OCR evidence
  helper is guarded on the result model, while the import action guards the
  actual visible status copy.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the actual native capture
  copy/settings affordances around phone-camera fallback and app-owned receipt
  camera behavior without changing backend scope.

### Receipt Camera Pass 759: Backup Camera Wording Polish Batch

Status: complete.

What changed:
- Renamed the visible fallback label from `Phone camera backup` to
  `Backup camera option` in receipt import and add-next-section review flows.
- Kept the stable diagnostic tokens (`phone_camera_backup_receipt_photo`,
  `phoneCameraBackupUsed`, and related telemetry) unchanged for Command One and
  historical health tracking.
- Updated receipt camera copy tests so the user-facing review label stays plain
  while the fallback telemetry remains explicit.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is inspecting the native receipt camera
  settings affordance so camera controls, receipt assistance, long-receipt
  guidance, and backup-size choices are discoverable without covering the
  receipt preview.
