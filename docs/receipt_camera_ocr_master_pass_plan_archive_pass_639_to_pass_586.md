# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 639: Accepted Photo Routing Guard Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 639: Accepted Photo Routing Guard Batch

Status: complete.

What changed:
- Audited the accepted native receipt photo route from the shared receipt
  attachment panel into the expense assisted receipt review state.
- Added regression coverage proving an accepted native camera result returns
  immediately from the outer take-photo flow instead of falling through to
  import options, document-scanner fallback, or phone-camera backup.
- Kept the existing accept-before-read order guarded: the expense screen starts
  the filled receipt review before OCR work finishes, then keeps the user on the
  review area while OCR/parser results arrive.
- No PDF, inventory, or unrelated expense UI was changed.

Validation:
- `dart format test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "accepted camera photo starts filled receipt review before OCR work finishes"`
- `flutter analyze test/receipt_capture_flow_shareability_test.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the visual review path:
  accepted long-receipt sections should keep clear thumbnails/order labels,
  preserve OCR source images separately from storage-saving proof, and make the
  next action unmistakably review-focused.

### Receipt Camera Reopen Pass 640: Post-Capture Review Copy Guard Batch

Status: complete.

What changed:
- Tightened the single-photo warning/recovery action in the receipt photo review
  tray so the add-section action says `Add Receipt Photo` instead of the vague
  `Add Photo`.
- Strengthened the receipt camera layout guard so the post-capture review tray
  keeps explicit next-step language and does not regress to confusing labels
  such as `Read receipt`, `Use this photo`, or `Saved copy`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 641: Multi-Receipt Line Selection Contract Batch

Status: complete.

What changed:
- Added `ReceiptMultiReceiptSelectionBundle` to the shared receipt processing
  contract so estimates, jobs, invoices, client proof, and inventory/materials
  can reference selected lines from multiple receipt proofs without carrying raw
  item text into privacy-safe summaries.
- Added regression coverage proving multi-receipt job selection preserves
  receipt ids, selected/excluded line counts, proof review counts, and totals
  while omitting private item descriptions, raw OCR text, and prices from the
  privacy-safe map.

Validation:
- `dart format lib/shared/receipts/receipt_processing_contract.dart test/receipt_line_models_test.dart`
- `flutter test test/receipt_line_models_test.dart --name "multi receipt selection bundle stays privacy safe for job proof"`
- `flutter analyze lib/shared/receipts/receipt_processing_contract.dart lib/shared/receipts/receipt_line_models.dart test/receipt_line_models_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 642: OCR Pack Disclosure Setup Batch

Status: complete.

What changed:
- Added a plain `userFacingPackDisclosureLabel` to `ReceiptCloudAssistPlan` so
  expense/camera setup can explain optional local parser size, cloud OCR/parser
  internet requirements, and honest accuracy bands without exposing raw device
  details or receipt content.
- Included that disclosure in privacy-safe diagnostics so Command One and setup
  screens can show the same local-vs-cloud plan language.
- Validated that low-storage phones still keep local OCR available and cloud
  OCR optional, while high-capacity phones can disclose larger local parser
  packs such as the materials/inventory regional pack.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "parser pack disclosures explain local size and cloud fallback honestly"`
- `flutter test test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter build apk --debug`
- `git diff --check`

### Receipt Camera Reopen Pass 576: Native Control Contract Parity Batch

Status: complete.

What changed:
- Added explicit `whiteBalanceLockEnabled` to the Dart native camera session
  config so white-balance locking is treated like focus and exposure locking,
  not hidden inside a generic mode string.
- Sent `whiteBalanceLockEnabled` through the receipt camera method-channel
  payload and included it in Android/iOS native diagnostics.
- Updated Android CameraX receipt camera code to read and report
  `whiteBalanceLockEnabled`, and only attempt white-balance lock when both the
  native setting mode and enabled flag allow it.
- Updated iOS AVFoundation receipt camera code to read and report
  `whiteBalanceLockEnabled`, with the same explicit lock gate.
- Expanded the settings descriptor package with controls a professional receipt
  camera needs to expose or account for: reset brightness, exposure lock,
  white-balance lock, and receipt light.
- Added policy-code coverage for unavailable focus lock, exposure lock, and
  white-balance lock so Command One can later explain which camera controls are
  disabled by device capability instead of guessing.
- Strengthened tests so capable-device fixtures prove the full control package
  is sent, received, and reported without storing receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_shell_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native lifecycle/recovery evidence:
  confirm interrupted captures keep local originals safe, recovery manifests
  survive app switches/calls/crashes, and accepted images hand OCR the original
  source before any storage-saving proof copy.

### Receipt Camera Reopen Pass 577: Recovery Control Diagnostics Preservation Batch

Status: complete.

What changed:
- Audited the native capture staging/recovery path against the new native camera
  control contract.
- Added the missing safe recovery diagnostic keys for focus lock, exposure
  lock, white-balance lock, mode values, lock counts, and lock status.
- Confirmed those diagnostics are preserved in both the recovery manifest and
  Hive recovery index so interrupted receipt work can still explain which camera
  controls were available or used.
- Kept the privacy boundary intact: recovery still drops unknown/private-looking
  keys such as receipt text, customer name, and address.
- Added regression coverage that proves white-balance lock status survives
  staging/recovery while private receipt text is still redacted.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_shell_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the accepted-review handoff: verify
  recovery manifests are cleared only after accepted attachments are safely
  attached, OCR source photos remain ordered, and the review/result metadata
  exposes a clear privacy-safe handoff status for Command One.

### Receipt Camera Reopen Pass 578: Attachment-Gated Recovery Clear Batch

Status: complete.

What changed:
- Changed reviewed-photo acceptance to return a success/failure result instead
  of always clearing native recovery state after the review screen closes.
- Delayed native camera recovery cleanup until the receipt attachment panel has
  accepted the reviewed photos and started the receipt-reader handoff.
- Stopped the shared recovered-capture review flow from clearing recovery
  manifests by itself, because that flow cannot prove the caller attached the
  photos safely.
- Moved recovered manifest cleanup into the attachment panel, gated by
  `_acceptReviewedPhotoResult` success.
- Renamed the recovery diagnostic action to
  `clear_recovery_after_attachment_acceptance` so Command One can tell that
  recovery was cleared after attachment acceptance, not merely after review.
- Added guard tests that prove the success gate is present and that the old
  premature clear action is not used.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the fast review and saved-photo
  UX path: confirm accepted photos keep OCR originals, the user can clearly add
  another photo for long receipts, review can exit without trapping the user,
  and data-saving copies are explained without touching OCR source quality.

### Receipt Camera Reopen Pass 579: Single-Photo Completion Gate Batch

Status: complete.

What changed:
- Added a single-photo completion decision before saving when Maintainiac sees
  safe diagnostic evidence that the receipt may continue below the current
  photo.
- The prompt asks, "Is this the whole receipt?" and gives three explicit
  choices: keep reviewing, continue with this photo, or add the next section.
- Kept OCR unblocked: if the user confirms the photo is complete enough,
  Maintainiac continues to the filled receipt details instead of rejecting the
  image.
- Wired "Add Next Section" from that prompt into the existing native
  CameraX/AVFoundation add-section path, preserving the ghost/overlap guidance
  for long receipts.
- Added a per-photo prompt memory so the same photo does not nag the user every
  time they tap Next.
- Added guard coverage so this gate runs before stitch/save work and still
  exposes a clear continue option.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native capture control surface:
  make the Maintainiac camera settings/control package visible and coherent
  during capture while preserving native CameraX/AVFoundation control and
  avoiding stock camera UI.

### Receipt Camera Reopen Pass 580: Native Settings Surface Naming Batch

Status: complete.

What changed:
- Audited the native camera capture settings surface on Android and iOS.
- Confirmed Android already opens a real Maintainiac receipt-camera settings
  dialog with assisted fill, long receipt mode, optional auto capture, auto
  brightness assist, edge guidance, warnings, OCR-original-first explanation,
  review style, save-space backup, manual shutter, and camera control summary.
- Renamed the iOS settings action from `showSettingsPlaceholder` to
  `showReceiptCameraSettings` so the native AVFoundation controller no longer
  describes the production receipt settings surface as a placeholder.
- Updated iOS bridge coverage to require `showReceiptCameraSettings` and reject
  `showSettingsPlaceholder`.
- Kept the app inside Maintainiac native CameraX/AVFoundation UI; no stock
  Samsung/iOS camera controller was introduced.

Validation:
- `dart format test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture layout consistency:
  tighten the visible control contract around settings, light, back, manual
  shutter, brightness, status, long-receipt done, and section guidance so the
  capture screen remains understandable without blocking the preview.

### Receipt Camera Reopen Pass 581: Native Visible Control Contract Batch

Status: complete.

What changed:
- Added a privacy-safe `visibleControlSet` diagnostic to the Android CameraX
  receipt camera.
- Added the same `visibleControlSet` diagnostic to the iOS AVFoundation receipt
  camera.
- The control set reports the visible Maintainiac capture controls as compact
  codes: back, settings, manual shutter, status, light, brightness, long
  receipt done, section ghost guide, and edge guide.
- Added `previewDominanceTarget: receipt_preview_75_80_percent` to both native
  capture diagnostics so QA and Command One can detect when a camera layout
  violates the receipt-preview-first requirement.
- Added bridge tests requiring both platforms to expose the same native control
  contract without collecting receipt text, customer data, or image content.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is capture/result diagnostics flowing
  into the Dart review model: ensure `visibleControlSet` and
  `previewDominanceTarget` survive native result staging/recovery and can be
  surfaced by privacy-safe camera health telemetry.

### Receipt Camera Reopen Pass 582: Native Control Diagnostics Staging Batch

Status: complete.

What changed:
- Added `visibleControlSet` and `previewDominanceTarget` to the safe native
  capture diagnostics allowlist.
- Verified those diagnostics survive accepted native capture staging.
- Verified those diagnostics survive the Hive-backed native recovery index.
- Kept the privacy boundary intact: private receipt text and other
  non-allowlisted content remain excluded from staged/recovery diagnostics.
- Preserved the same diagnostic vocabulary for Android CameraX and iOS
  AVFoundation so Command One can summarize camera UI health without seeing
  receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review/result labels for camera UI
  health: expose the visible-control and preview-dominance evidence in concise
  privacy-safe handoff labels so app health diagnostics can show whether
  camera UI quality is failing.

### Receipt Camera Reopen Pass 583: Camera UI Health Handoff Labels Batch

Status: complete.

What changed:
- Added `nativeCameraUiHealthCounts` to `ReceiptPhotoReviewResult`.
- Added `nativeCameraUiHealthOutcome` so receipt review can classify native
  camera UI health as ready, incomplete, missing control signal, or missing
  preview-dominance evidence.
- Included native camera UI health counts in receipt-reader handoff counts
  using privacy-safe bucket names.
- Added `ui=<health>` to the privacy-safe OCR handoff evidence only when native
  UI health diagnostics exist, preserving older/non-native evidence strings.
- Added `nativeCameraUiHealthCounts` and `nativeCameraUiHealthOutcome` to the
  privacy-safe handoff metadata when available.
- Added tests for healthy native camera controls and incomplete native camera
  controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_native_capture_staging_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is telemetry handoff: ensure the
  receipt attachment/Command One diagnostic path carries the new native camera
  UI health buckets without duplicating private content or creating extra
  Firestore writes.

### Receipt Camera Reopen Pass 584: Camera UI Health Attachment Diagnostics Batch

Status: complete.

What changed:
- Added native camera UI health document signals to OCR source attachments.
- Added native camera UI risk flags to OCR source attachments only when native
  camera controls are incomplete, missing, or unknown.
- Centralized receipt-reader handoff diagnostics so accepted capture,
  recovered capture, and OCR handoff use the same privacy-safe metadata.
- Carried `nativeCameraUiHealthOutcome` and `nativeCameraUiHealthCounts`
  through the local diagnostics path for future Command One summaries.
- Preserved the privacy boundary: no receipt image content, receipt text,
  customer names, vendor names, item descriptions, phone numbers, or addresses
  are added to the telemetry vocabulary.
- Added no Firestore writes; this remains local attachment/diagnostic handoff
  evidence only.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture/review correctness:
  keep back/exit reliable, keep the preview dominant, and keep the next action
  moving into filled receipt review instead of returning to the receipt entry
  start.

### Receipt Camera Reopen Pass 585: Review Lifecycle Exit Guard Batch

Status: complete.

What changed:
- Added a shared `_reviewWorkActive` guard for receipt photo review background
  work.
- Stopped delayed storage-preview, quality-check, and stitch-preview work from
  updating review state after the user has committed to leaving the review.
- Routed stitch preview timers through the same active-review guard.
- Kept generated preview cleanup behavior intact so abandoned generated files
  remain best-effort cleanup instead of blocking exit.
- Added a layout/lifecycle regression guard so future review async work checks
  the closing-review state instead of only checking `mounted`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_shell_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture/review correctness:
  verify the back/exit actions on the review and native camera surfaces cannot
  trap the user, discard accepted work silently, or keep async preview work
  alive after exit.

### Receipt Camera Reopen Pass 586: Native Pre-Capture Exposure Confirmation Batch

Status: complete.

What changed:
- Android CameraX now records confirmed pre-capture exposure adjustments, not
  just attempted adjustment decisions.
- Android diagnostics now include
  `preCaptureExposureAdjustmentConfirmedCount` and
  `lastPreCaptureExposureTargetIndex`.
- Android pre-capture exposure decisions now distinguish confirmed
  `brightened_before_capture` and `dimmed_before_capture` outcomes from
  unconfirmed adjustment attempts.
- iOS AVFoundation now records the same confirmed pre-capture adjustment count
  and target-bias evidence.
- iOS diagnostics now include
  `preCaptureExposureAdjustmentConfirmedCount` and
  `lastPreCaptureExposureTargetBias`.
- Added native bridge guards so future brightness/exposure changes remain
  inspectable without receipt content.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is brightness parity and capture
  quality: keep diagnosing why a saved capture can be darker or blurrier than
  the live/native stock camera view, then tighten the capture settings and
  review warnings with evidence.
