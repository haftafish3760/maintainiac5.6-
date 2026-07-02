# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 337 / Total Pass 417: Review Exit Copy Safety Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 337 / Total Pass 417: Review Exit Copy Safety Batch

Status: complete.

What changed:
- Audited the receipt photo review back/close path.
- Confirmed the review screen uses `PopScope(canPop: false)` and routes back
  button/close actions through `_confirmReceiptReviewExit`.
- Fixed a single-photo grammar bug in the exit dialog:
  `This receipt photo are saved...` now reads
  `This receipt photo is saved locally for recovery, but not attached to the
  expense yet.`
- Preserved the multi-photo wording:
  `These receipt photos are saved locally for recovery, but not attached to the
  expense yet.`
- Kept the safe action set intact: Leave saved/recoverable, Keep Reviewing, or
  Next into receipt detail review.
- Added layout-source coverage for both single-photo and multi-photo exit
  safety copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue with review-image usability: zoom/crop/order controls should remain
  reachable without covering the receipt, and data-saver preview should remain
  clearly separated from OCR source quality.

### Receipt Camera Reopen Pass 338 / Total Pass 418: Review Surface Zoom Control Batch

Status: complete.

What changed:
- Audited receipt photo review image visibility and control bounds.
- Confirmed the review surface already reserves bottom padding for the capped
  controls and uses `InteractiveViewer` for pinch zoom.
- Added a dedicated `TransformationController` for the receipt preview.
- Added double-tap zoom behavior:
  - double-tap on an unzoomed receipt zooms into the tapped area,
  - double-tap again resets the receipt to full view.
- Added a small `boundaryMargin` so the zoomed receipt can be panned without
  feeling pinned to the viewport edge.
- Disposed the transformation controller with the review screen.
- Added source-contract coverage for the zoom controller, double-tap handlers,
  and boundary margin.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue native capture parity and review handoff hardening. Specifically,
  verify Android/iOS captured-photo diagnostics, exposure behavior, and OCR
  handoff metadata stay aligned.

### Receipt Camera Reopen Pass 339 / Total Pass 419: Native Bottom-Receipt Diagnostic Coverage Batch

Status: complete.

What changed:
- Audited Android CameraX and iOS AVFoundation captured-photo diagnostics.
- Confirmed both native backends already record:
  average luma, edge score, top/middle/bottom luma, bottom edge score,
  brightness bucket, sharpness bucket, vertical quality signal, quality signal,
  and live-preview versus captured-photo exposure mismatch.
- Added bridge-test coverage for `latestCapturedBottomEdgeScore` on both
  Android and iOS.
- Added bridge-test coverage that both platforms round and export
  `sample.bottomEdgeScore`.
- This protects diagnostics for the exact failure class where the top of the
  receipt looks readable but the bottom total/barcode area is dim or soft.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart`

Next camera/OCR focus:
- Continue native capture parity and user-facing review behavior. Prioritize
  anything that directly affects taking a readable photo, preserving it safely,
  or handing it to OCR with useful diagnostics.

### Receipt Camera Reopen Pass 340 / Total Pass 420: Bottom Receipt Telemetry Handoff Batch

Status: complete.

What changed:
- Audited the handoff from Android/iOS native captured-photo diagnostics into
  app-level receipt telemetry.
- Confirmed native staging already allows bottom-of-receipt diagnostics:
  `latestCapturedBottomLuma`, `latestCapturedBottomEdgeScore`, and
  `latestCapturedVerticalQualitySignal`.
- Added receipt preparation telemetry summaries for:
  - `capturedPhotoBottomBrightnessBuckets`,
  - `capturedPhotoBottomEdgeScoreBuckets`,
  - `capturedPhotoVerticalQualitySignals`.
- Added privacy-policy allowlist support for those content-free metadata
  fields.
- Added Command One health snapshot aggregation and exported summary fields:
  - `capturedPhotoBottomBrightnessCounts`,
  - `capturedPhotoBottomEdgeScoreCounts`,
  - `capturedPhotoVerticalQualitySignalCounts`,
  - matching top-value fields.
- Added sanitizer and health-summary test coverage so the signals are accepted,
  aggregated, and exported without receipt image/text content.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next pass should target the next highest-impact
  photo-capture or OCR handoff issue, not PDF, inventory, or broad expense
  backend work.

### Receipt Camera Reopen Pass 341 / Total Pass 421: Review Back-Exit Lifecycle Guard Batch

Status: complete.

What changed:
- Audited the active receipt camera path for old Flutter camera usage.
- Confirmed the receipt flow uses Maintainiac native camera first:
  CameraX on Android and AVFoundation on iOS.
- Confirmed `ImagePicker` remains only a fallback path when the Maintainiac
  native camera is unavailable.
- Hardened receipt photo review back/close behavior by adding an
  `_confirmingReviewExit` guard.
- Prevented repeated hardware-back, close, or overlay-close taps from stacking
  exit dialogs or racing review-screen navigation while an exit confirmation is
  already open.
- Wrapped the confirmation guard reset in `finally` so the review screen does
  not get stuck if the dialog is interrupted.
- Added source coverage that proves the lifecycle guard exists and is reset.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR lifecycle and quality hardening. Prioritize remaining
  issues that block reliable phone testing: native capture brightness/zoom,
  review flow clarity, OCR handoff, and long-receipt stitching.

### Receipt Camera Reopen Pass 342 / Total Pass 422: Native Pre-Capture Brightness Band Batch

Status: complete.

What changed:
- Audited Android CameraX and iOS AVFoundation exposure assist around the saved
  photo brightness issue.
- Tightened the Android automatic-capture light readiness band from a broad
  `68..245` to a safer receipt target band of `122..238`.
- Tightened Android pre-capture exposure adjustment:
  - brighten strongly at `<= 88`,
  - brighten at `<= 124`,
  - dim strongly at `>= 248`,
  - dim at `>= 238`,
  - treat `124..238` as the ready band.
- Applied matching AVFoundation pre-capture thresholds on iOS.
- Added native bridge coverage so both platform implementations keep the safer
  pre-capture brightness target and do not silently drift back toward darker
  saved receipt photos.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next likely targets are OCR handoff review flow,
  long-receipt stitching confidence, pinch-zoom/manual focus behavior, and
  saved-photo quality diagnostics.

### Receipt Camera Reopen Pass 343 / Total Pass 423: Pending OCR Review State And Storage-Tier Rule Batch

Status: complete.

What changed:
- Audited the accepted-photo OCR handoff route after the review screen's Next
  action.
- Confirmed accepted camera photos set `_receiptReviewFlowStarted`, scroll to
  the receipt review section, and prepare OCR sources before deleting temporary
  OCR files.
- Fixed the pending OCR review state so it no longer shows a premature
  `No Line Items Found` failure while receipt reading is still running.
- Added a clear waiting state:
  - title: `Waiting For Receipt Reader`,
  - reason: `Reading receipt`,
  - next step: keep the screen open until filled receipt review appears.
- Added test coverage for the pending OCR review copy so the user is not told
  OCR failed before OCR finishes.
- Added the download-size/device-storage architecture rule:
  low-storage phones must keep a usable basic receipt flow, heavy OCR/scanner
  features must be capability-gated or optional, and any camera/OCR payload
  over roughly 50 MB added size needs explicit review.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Prioritize remaining visible blockers: review flow
  clarity, native zoom/focus behavior, long-receipt stitching confidence, and
  storage-tier enforcement.

### Receipt Camera Reopen Pass 344 / Total Pass 424: Low-Storage OCR Capability Contract Batch

Status: complete.

What changed:
- Audited the receipt capability and assistance policy for low-storage and
  older-device behavior.
- Confirmed low-storage does not mean no OCR. Every device tier keeps a basic
  on-device receipt-reading path for photos.
- Added explicit capability labels for the future UI/settings layer:
  - local receipt reading plan,
  - lean local receipt reading,
  - optional cloud OCR assist.
- Made the cloud OCR contract explicit: cloud OCR may be offered for better
  accuracy or heavier parsing, but it must be explicit, require internet, and
  never replace the basic local receipt-reading path.
- Added tests proving a critically low-storage phone keeps local photo OCR,
  limits heavy catalog matching, uses maximum space saving for saved proof
  copies, and only treats cloud OCR as optional assist.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Prioritize native zoom/focus, review flow clarity,
  long-receipt stitching confidence, and OCR review handoff.

### Receipt Camera Reopen Pass 345 / Total Pass 425: Android Preview Gesture Ownership Batch

Status: complete.

What changed:
- Audited Android CameraX pinch-zoom and tap-focus handling after the phone
  report that pinch zoom was not working.
- Fixed the preview touch listener so it owns the full gesture sequence from
  `ACTION_DOWN` through move/up/cancel instead of returning `false` on the
  first touch.
- Kept tap-to-focus and pinch-to-zoom separate:
  - pinch gestures update CameraX zoom through the current active camera,
  - tap focus still meters the tapped receipt text,
  - taps immediately after a pinch are suppressed so zoom does not accidentally
    trigger focus.
- Added Android bridge coverage for the gesture ownership behavior.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-flow clarity and long-receipt
  section handoff.

### Receipt Camera Reopen Pass 346 / Total Pass 426: Accepted Photo Review Wording Batch

Status: complete.

What changed:
- Audited the receipt-photo review handoff wording after accepting a photo.
- Strengthened the single-photo primary action label from `Next: Review
  Details` to `Next: Review Receipt Details` so the user knows the next screen
  is the filled receipt review, not a generic return to the entry screen.
- Updated the photo-quality guidance copy to use the same wording.
- Added test coverage so the accepted-photo review flow keeps the stronger
  next-step wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is long-receipt section handoff and
  photo-order confidence.

### Receipt Camera Reopen Pass 347 / Total Pass 427: Multi-Photo Device Limit Warning Batch

Status: complete.

What changed:
- Audited the long-receipt multi-photo review flow.
- Added a device-limit warning strip when the user has more receipt photos than
  the current device tier is tuned to read locally.
- Kept the flow permissive: Next still works, but the user is told to review
  every line before saving.
- This keeps low-storage/older-phone users from silently overloading local OCR
  while still allowing long receipts to be captured.

Validation:
- Pending in this pass: run receipt capture layout tests and analyzer.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is OCR review handoff evidence and
  native capture diagnostics.

### Receipt Camera Reopen Pass 348 / Total Pass 428: Privacy-Safe OCR Handoff Evidence Batch

Status: complete.

What changed:
- Audited accepted-photo OCR handoff diagnostics.
- Added `privacySafeOcrHandoffEvidenceLabel` to `ReceiptPhotoReviewResult`.
- The label summarizes non-private evidence only:
  - quality outcome,
  - stitch status and reason,
  - OCR source count,
  - scanner source decision,
  - saved-photo warning severity,
  - receipt coverage status.
- No receipt image, receipt text, merchant/customer/private content, or line
  item content is included.
- Added tests proving the handoff evidence distinguishes enhanced OCR sources,
  possible partial receipts, and saved-photo warning severity.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring this evidence into the
  accepted-photo read status and telemetry.

### Receipt Camera Reopen Pass 349 / Total Pass 429: OCR Handoff Evidence Wiring Batch

Status: complete.

What changed:
- Wired the privacy-safe OCR handoff evidence into the accepted-photo read
  status message.
- Added the same evidence to expense camera/OCR telemetry as
  `privacySafeOcrHandoffEvidence`.
- Added the telemetry key to the privacy allowlist.
- Updated tests so this evidence remains connected to the user-visible handoff
  and future Command One health reporting without exposing receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture diagnostics and
  review-screen recovery behavior.

### Receipt Camera Reopen Pass 350 / Total Pass 430: Native Recovery Evidence Label Batch

Status: complete.

What changed:
- Audited native capture staging and recovery.
- Confirmed accepted native photos are copied into app-owned staged storage and
  recovery is written to both manifest and Hive index.
- Added `privacySafeRecoveryEvidenceLabel` to interrupted native capture
  recovery records.
- The evidence label summarizes engine, photo count, multi-section state, close
  action, storage level, workload tier, and exposure mismatch code.
- The label excludes receipt text, receipt image content, customer details, and
  private receipt fields.
- Extended recovery tests to prove the evidence label is useful and does not
  leak private content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing recovery evidence through
  resume/discard telemetry.

### Receipt Camera Reopen Pass 351 / Total Pass 431: Recovery Evidence Telemetry Wiring Batch

Status: complete.

What changed:
- Wired interrupted native capture recovery evidence into accepted, kept, and
  discarded recovery telemetry.
- Added `nativeRecoveryEvidence` to the expense telemetry allowlist.
- Updated tests so recovery telemetry keeps using
  `privacySafeRecoveryEvidenceLabel`.
- This gives future Command One health views a way to separate resumed,
  postponed, and discarded interrupted receipt-camera sessions without private
  receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is OCR/source cleanup and interrupted
  review lifecycle hardening.

### Receipt Camera Reopen Pass 352 / Total Pass 432: OCR Temp Artifact Cleanup Safety Batch

Status: complete.

What changed:
- Audited reviewed-photo OCR source cleanup after app-assisted receipt reading.
- Replaced broad cleanup behavior with a guarded classifier so only generated
  OCR temp artifacts are deleted.
- Protected accepted receipt photos, staged proof storage, permanent proof
  storage, and native capture recovery storage from OCR temp cleanup.
- Required cleanup candidates to live under the OS temp directory and use the
  Maintainiac OCR artifact filename prefix before deletion.
- Updated receipt-flow guard tests so temporary OCR cleanup cannot silently
  expand back into app-owned proof/recovery deletion.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is interrupted review lifecycle and
  native capture disposed-controller guard coverage.
